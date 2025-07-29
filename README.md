# Scripting coursework

This repository contains a few tasks and solutions completed for a scripting-focused university course.

## Repository Structure

The repository includes:

- `1 practice.pptx` to `5 practice.pptx`  
  → Task descriptions for each assignment (in PowerPoint format).

- `completed_1` to `completed_5`  
  → Completed scripts for each task, written in the respective scripting language.
  
- `project.ruby`
  → A project in ruby organizing downloads folder.

## Task Overview

### Task 1 – Batch Script
- **Goal:** Read all files with a given extension from a specified directory (including subdirectories).

### Task 2 – PowerShell Script
- **Goal:** Read all currently running processes along with their users.

### Task 3 – Bash Script
- **Goal:** Similar to Task 2 but using Bash.

### Task 4 – Python Script
- **Goal:** Search for files or directories by name or partial match.

### Task 5 – PHP Command-Line Script
- **Goal:** List processes and save logs in a selected format.

## Ruby Automation Project – `project.rb` for windows

### Purpose

Automates organization of the `~/Downloads` folder by:

- **Categorizing files** into folders like `Images`, `Videos`, `Documents`, etc.
- **Detecting duplicates** using SHA-256 hash.
- **Extracting archives** (`.zip`, `.rar`, `.7z`) into an "Extracted" folder.
- **Archiving old/unused files** based on last modified time.
- **Logging** all activity to `activity.log`.
- **Saving clipboard text** to a timestamped file (avoiding duplicates).
- **Sending desktop notifications**.

### Key Folders Created
- `Sorted/` – Categorized files
- `Duplicates/` – Identified duplicates
- `Unused/` – Files not used in over 7 days
- `Clipboard/` – Clipboard logs
- `activity.log` – History of all operations

### Dependencies
- `fileutils`
- `digest`
- `clipboard`
- `zip`
- `open3`
- `rubygems`
- `BurntToast`

### Loop Behavior
Runs continuously every 10 seconds:
1. Sorts and moves files.
2. Extracts archives.
3. Moves unused files.
4. Saves new clipboard text.
5. Logs changes and notifies user.
