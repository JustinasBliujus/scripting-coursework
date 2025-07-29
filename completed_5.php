#!/usr/bin/env php
<?php

if ($argc < 2 || $argc > 3) {
    echo "Usage: script.php [file_format] <username>\n";
    exit(1);
}

$fileFormat = isset($argv[1]) ? strtolower($argv[1]) : 'txt';
$username = isset($argv[2]) ? $argv[2] : null;

if (!in_array($fileFormat, ['txt', 'html', 'csv'])) {
    echo "Supported formats are 'txt', 'html', or 'csv'.\n";
    exit(1);
}

$command = $username
    ? "ps aux | grep ^$username"
    : "ps aux";

$output = shell_exec($command);

if (empty($output)) {
    echo "No processes found.\n";
    exit(1);
}

$lines = explode("\n", trim($output));
$processes = [];

$users = [];

foreach ($lines as $line) {
    $processInfo = preg_split('/\s+/', $line);
   
    if (count($processInfo) > 10) {
        $user = $processInfo[0];

        if (!$username) {
            $users[$user][] = $processInfo;
        } else {
            $processes[] = $processInfo;
        }
    }
}

function saveProcessesToFile($processes, $fileFormat, $username) {
    $fileName = "$username-processes.$fileFormat";
    $file = fopen($fileName, 'w');

    if ($fileFormat === 'txt') {
        $headers = ['USER', 'PID', 'CPU%', 'MEM%', 'VSZ', 'RSS'];

        fwrite($file, str_pad("USER", 15) . str_pad("PID", 10) . str_pad("CPU%", 8) . str_pad("MEM%", 8) . str_pad("VSZ", 10) . str_pad("RSS", 10) . "\n");
        fwrite($file, str_repeat("-", 80) . "\n");

        foreach ($processes as $process) {
            fwrite($file, str_pad($process[0], 15) . str_pad($process[1], 10) . str_pad($process[2], 8) . str_pad($process[3], 8) . str_pad($process[4], 10) . str_pad($process[5], 10) . "\n");
        }
    }

    elseif ($fileFormat === 'csv') {
        fputcsv($file, ['USER', 'PID', 'CPU%', 'MEM%', 'VSZ', 'RSS']);

        foreach ($processes as $process) {
            fputcsv($file, $process);
        }
    }

    elseif ($fileFormat === 'html') {
        fwrite($file, "<html><head><title>Processes for $username</title></head><body><table border='1'><tr>");
        fwrite($file, "<th>USER</th><th>PID</th><th>CPU%</th><th>MEM%</th><th>VSZ</th><th>RSS</th>");

        foreach ($processes as $process) {
            fwrite($file, "<tr>");
            foreach ($process as $column) {
                fwrite($file, "<td>" . htmlspecialchars($column) . "</td>");
            }
            fwrite($file, "</tr>");
        }
        fwrite($file, "</table></body></html>");
    }

    fclose($file);
    echo "Processes for $username have been saved to $fileName\n";
}

if ($username) {
    saveProcessesToFile($processes, $fileFormat, $username);
} else {
    foreach ($users as $user => $userProcesses) {
        saveProcessesToFile($userProcesses, $fileFormat, $user);
    }
}

echo "Press any key to delete the log files and exit...\n";
system('bash -c "read -n 1 -s -p \"Press any key to continue...\""');

if ($username) {
    $fileName = "$username-processes.$fileFormat";
    if (file_exists($fileName)) {
        unlink($fileName);
        echo "Log file $fileName deleted.\n";
    }
} else {
    foreach ($users as $user => $userProcesses) {
        $fileName = "$user-processes.$fileFormat";
        if (file_exists($fileName)) {
            unlink($fileName);
            echo "Log file $fileName deleted.\n";
        }
    }
}

?>
