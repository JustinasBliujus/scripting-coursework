#!/bin/bash

user_exists() {
    id "$1" &>/dev/null
}

if [ -z "$1" ]; then
    users=$(ps aux | awk '{print $1}' | sort | uniq)  
else
    username="$1"
    users="$username"  
fi

current_date=$(date '+%Y-%m-%d')
current_time=$(date '+%H-%M-%S') 

output_dir="user_processes_logs"
mkdir -p "$output_dir"

total_line_count=0

for username in $users; do
    if ! user_exists "$username"; then
        log_file="${output_dir}/unknown-process-log-${current_date}-${current_time}.log"
        echo "User '$username' does not exist." > "$log_file"
    else
        log_file="${output_dir}/${username}-process-log-${current_date}-${current_time}.log"
        processes=$(ps -u $username --no-headers -eo pid,comm,%cpu,%mem)

        echo "Date: $current_date" > "$log_file"
        echo "Time: $current_time" >> "$log_file"
        echo "--------------------------------------" >> "$log_file"
        
        while read -r pid comm cpu mem; do
            echo "Process Name: $comm" >> "$log_file"
            echo "PID: $pid" >> "$log_file"
            echo "CPU Usage: $cpu%" >> "$log_file"
            echo "Memory Usage: $mem%" >> "$log_file"
            echo "--------------------------------------" >> "$log_file"
        done <<< "$processes"

        if [ -n "$1" ]; then
            echo -e "\nProcesses for user '$username':"
            echo "--------------------------------------"
            echo "$processes" | while read -r pid comm cpu mem; do
                echo "Process Name: $comm"
                echo "PID: $pid"
                echo "CPU Usage: $cpu%"
                echo "Memory Usage: $mem%"
                echo "--------------------------------------"
            done
        fi
    fi
done

echo -e "\nOutput directory: $output_dir"
total_line_count=0

for log_file in "$output_dir"/*.log; do
    if [ -f "$log_file" ]; then
        line_count=$(wc --lines < "$log_file")
        echo "File: $log_file - Line Count: $line_count"
        total_line_count=$((total_line_count + line_count))
    fi
done

echo -e "\nTotal line count across all files: $total_line_count"

echo "Press any key to continue..."
read -n 1 -s

rm -rf "$output_dir"
echo "All files have been deleted"

