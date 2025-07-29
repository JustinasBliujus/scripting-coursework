require 'fileutils'
require 'digest'
require 'clipboard'
require 'zip'
require 'open3'
require 'rubygems'

DOWNLOADS_DIR = File.expand_path('~/Downloads')
SORTED_DIR = File.join(DOWNLOADS_DIR, 'Sorted')
DUPLICATES_DIR = File.join(DOWNLOADS_DIR, 'Duplicates')
UNUSED_DIR = File.join(DOWNLOADS_DIR, 'Unused')
CLIPBOARD_DIR = File.join(DOWNLOADS_DIR, 'Clipboard')
LOG_FILE = File.join(DOWNLOADS_DIR, 'activity.log')
UNUSED_THRESHOLD = 60*60*24*7

def ensure_directories_exist
  [DOWNLOADS_DIR, SORTED_DIR, DUPLICATES_DIR, UNUSED_DIR, CLIPBOARD_DIR].each do |dir|
    Dir.mkdir(dir) unless Dir.exist?(dir)
  end
end

def log_activity(message)
  File.open(LOG_FILE, 'a') { |f| f.puts("#{Time.now}: #{message}") }
end

def file_hash(file)
  Digest::SHA256.file(file).hexdigest if File.file?(file)
end

def move_file(file, destination)
  FileUtils.mv(file, destination)
  log_activity("Moved: #{file} -> #{destination}")
end

def categorize_file(file)
    ext = File.extname(file).downcase
    case ext
    when '.jpg', '.png', '.gif', '.jpeg', '.bmp', '.tiff', '.webp' then 'Images'
    when '.mp4', '.avi', '.mkv', '.mov', '.flv', '.wmv', '.mpg', '.mpeg' then 'Videos'
    when '.mp3', '.wav', '.flac', '.aac', '.ogg', '.m4a', '.wma' then 'Music'
    when '.pdf', '.docx', '.txt', '.dotx', '.rtf', '.odt', '.epub' then 'Documents'
    when '.xls', '.xlsx', '.csv', '.ods' then 'Spreadsheets'
    when '.ppt', '.pptx', '.odp' then 'Presentations'
    when '.zip', '.rar', '.7z', '.tar', '.gz', '.bz2', '.xz' then 'Archives'
    when '.html', '.htm', '.css', '.js', '.json', '.xml' then 'Web Files'
    when '.cpp', '.c', '.java', '.py', '.rb', '.html', '.php', '.swift', '.go', '.js' then 'Code Files'
    when '.iso', '.img', '.bin' then 'Disk Images'
    when '.apk', '.exe', '.msi', '.app', '.dmg' then 'Installers'
    when '.md', '.rst' then 'Documentation'
    when '.json', '.yaml', '.ini', '.toml', '.conf' then 'Configuration Files'
    when '.bak', '.swp', '.tmp' then 'Temporary Files'
    else 'Others'
    end
  end  

  def extract_archive(file)
    ext = File.extname(file).downcase
    destination = File.join(SORTED_DIR, 'Extracted')
    Dir.mkdir(destination) unless Dir.exist?(destination)
  
    begin
      case ext
      when '.zip'
        Zip::File.open(file) do |zip_file|
          zip_file.each do |entry|
            extracted_path = File.join(destination, entry.name)
  
            FileUtils.mkdir_p(File.dirname(extracted_path))
  
            if File.exist?(extracted_path)
              move_file(extracted_path, File.join(DUPLICATES_DIR, entry.name))
              log_activity("Moved duplicate (exists): #{entry.name} to duplicates")
            else
              entry.extract(extracted_path)
              log_activity("Extracted: #{entry.name} from #{file}")
            end
          end
        end
      when '.rar', '.7z'
        if ext == '.rar'
          Open3.popen3("unrar x -o+ #{file} #{destination}")
        elsif ext == '.7z'
          Open3.popen3("7z x -y #{file} -o#{destination}")
        end
        log_activity("Extracted: #{file}")
      else
        raise "Unsupported archive format: #{ext}"
      end
    rescue Zip::Error => e
      log_activity("Error extracting file #{file}: #{e.message}")
    rescue StandardError => e
      log_activity("Error extracting file #{file}: #{e.message}")
    end
  end  

def process_downloads
  file_hashes = {}
  files_changed = []

  Dir.glob(File.join(DOWNLOADS_DIR, '*')).each do |file|
    next if File.directory?(file) || file == LOG_FILE || [SORTED_DIR, DUPLICATES_DIR, UNUSED_DIR, CLIPBOARD_DIR].include?(file)

    if ['.zip', '.rar', '.7z'].include? File.extname(file).downcase
      extract_archive(file)
      files_changed << "Extracted: #{file}"
    end

    hash = file_hash(file)
    if file_hashes.value?(hash)
      move_file(file, File.join(DUPLICATES_DIR, File.basename(file)))
      files_changed << "Moved duplicate: #{file}"
      next
    end

    file_hashes[file] = hash
    category = categorize_file(file)
    destination = File.join(SORTED_DIR, category)
    Dir.mkdir(destination) unless Dir.exist?(destination)
    move_file(file, File.join(destination, File.basename(file)))
    files_changed << "Moved and categorized: #{file} to #{category}"
  end

  files_changed
end

def clean_empty_directories
    Dir.glob(File.join(DOWNLOADS_DIR, '**', '/')).reverse.each do |dir|
      if Dir.empty?(dir) && dir != DOWNLOADS_DIR
        Dir.rmdir(dir)
        log_activity("Removed empty directory: #{dir}")
      end
    end
  end

def move_unused_files
  files_changed = []

  Dir.glob(File.join(SORTED_DIR, '**', '*')).select { |file| File.file?(file) }.each do |file|
    next if file == LOG_FILE

    category = categorize_file(file)

    if ['Images', 'Music'].include?(category)
      next
    end

    if Time.now - File.mtime(file) > UNUSED_THRESHOLD
      move_file(file, File.join(UNUSED_DIR, File.basename(file)))
      files_changed << "Moved unused: #{file}"
    end
  end

  files_changed
end

def send_windows_notification(changes)
  return if changes.empty?

  changes_to_display = changes.first(5)

  message = "Download folder sorting is complete!\nChanges:\n#{changes_to_display.join("\n")}"

  max_message_length = 100
  message = message[0...max_message_length]

  script_content = <<-PS
    Import-Module BurntToast
    New-BurntToastNotification -Text "Download Sorting", "#{message}"
  PS

  temp_ps1_path = File.join(Dir.tmpdir, "notify_script.ps1")
  File.open(temp_ps1_path, 'w:utf-8') { |f| f.write(script_content) }

  system("powershell -ExecutionPolicy Bypass -File \"#{temp_ps1_path}\"")

  File.delete(temp_ps1_path) if File.exist?(temp_ps1_path)
end

def save_clipboard_content
  content = Clipboard.paste.strip
  return nil if content.empty?

  last_clipboard_file = File.join(CLIPBOARD_DIR, '.last_clipboard.txt')

  content = content.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')

  if File.exist?(last_clipboard_file)
    last_content = File.read(last_clipboard_file, mode: 'r', encoding: 'UTF-8').strip
    return nil if content == last_content
  end

  timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
  file_path = File.join(CLIPBOARD_DIR, "clipboard_#{timestamp}.txt")

  File.open(file_path, 'w:utf-8') { |f| f.write(content) }

  File.open(last_clipboard_file, 'w:utf-8') { |f| f.write(content) }

  log_activity("Saved clipboard content to #{file_path}")
  "Saved clipboard content"
end

loop do
  ensure_directories_exist
  
  changes = process_downloads + move_unused_files
  clipboard_result = save_clipboard_content
  clean_empty_directories
  changes << clipboard_result if clipboard_result

  log_activity('Sorting completed.')

  send_windows_notification(changes) unless changes.empty?

  sleep(10)
end

