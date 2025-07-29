import os
import time
import sys
from datetime import datetime

if len(sys.argv) != 2:
    print("Usage: python script.py <file_or_directory_name>")
    exit()

path = sys.argv[1]

full_path = os.path.abspath(path)

try:
    stat_info = os.stat(path)
    permissions = oct(stat_info.st_mode)[-3:]
    creation_time = time.ctime(stat_info.st_ctime)
except FileNotFoundError:
    print("Path doesn't exist.")
    exit()

call_date = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

log_file_path = "search_log.txt"

with open(log_file_path, "a") as log_file:
    log_file.write(f"\nProvided parameter: {path}\n")
    log_file.write(f"Call Date: {call_date}\n")

    if os.path.isdir(path):
        log_file.write(f"Full Path: {full_path}\n")
        log_file.write(f"Permissions: {permissions}\n")
        log_file.write(f"Creation Time: {creation_time}\n")

        log_file.write("\nDirectory contents:\n")
        try:
            for entry in os.listdir(path):
                log_file.write(f"{entry}\n")
        except PermissionError:
            log_file.write("Cannot access the contents of the directory due to permission issues.\n")
    
    elif os.path.isfile(path):
        log_file.write(f"Full Path: {full_path}\n")
        log_file.write(f"File Name: {os.path.basename(path)}\n")
        log_file.write(f"Permissions: {permissions}\n")
        log_file.write(f"Creation Time: {creation_time}\n")

    else:
        log_file.write("Path doesn't exist.\n")

print("Search results have been logged.\n")
