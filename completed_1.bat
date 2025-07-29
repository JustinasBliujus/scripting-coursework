@echo off
setlocal enabledelayedexpansion

set defaultDirectory=%C:\Users\justi\Desktop\scripting%
set /p directory=Enter the directory path (default: %defaultDirectory%): 
if not defined directory set "directory=%defaultDirectory%"
if not exist "%directory%" (
    echo Directory does not exist. Using default directory: %defaultDirectory%
    set "directory=%defaultDirectory%"
)

set /p extension=Enter the file extension (default: .bat): 
if not defined extension set "extension=.bat"

set "logfile=%directory%\file_log.txt"

set counter=0
for /r "%directory%" %%F in (*%extension%) do (
    set /a counter+=1
    set "file[!counter!]=%%F"
)
echo Total files found: %counter%
if %counter%==0 (
    echo No files found with the extension %extension%.
) else (
    echo Writing log file...
)

(
    echo Date: %date%
    echo Time: %time%
    echo.
    for /l %%i in (1,1,%counter%) do (
        set "fullpath=!file[%%i]!"

        for %%a in (!fullpath!) do set "filename=%%~nxa"
        
        echo Filename: !filename!
        echo Filepath: !fullpath!
        echo.
    )
) > "%logfile%"

start notepad "%logfile%"
pause

taskkill /im notepad.exe 
del "%logfile%" 
exit
