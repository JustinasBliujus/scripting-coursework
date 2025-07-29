param(
    [string[]]$usernames  
)

$processes = Get-WmiObject Win32_Process
$dateTime = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"

if (-not $usernames) {
    $usernames = $processes | ForEach-Object {
        try {
            $owner = $_.GetOwner()
            if ($owner.User) { $owner.User } else { "unknown" }
        } catch {
            if ($_.Exception.Message -match "Not found") {
                "unknown"
            } else {
                throw
            }
        }
    } | Select-Object -Unique
}

foreach ($username in $usernames) {

    $fileName = "$username-process-log-$dateTime.txt"
    $content = "Log created for user: $username`n"
    $content += "Date: $(Get-Date -Format 'yyyy-MM-dd')`n"
    $content += "Time: $(Get-Date -Format 'HH-mm-ss')`n"
    $content += "-----------------------------------------------`n"
    $content += "{0,-20} {1,-10} {2,-15} {3,-15}" -f "ProcessName", "PID", "KernelTime", "UserTime"
    $content += "`n-----------------------------------------------`n"

    foreach ($process in $processes) {
        $owner = $process.GetOwner()
        $user = if ($owner.User) { $owner.User } else { "unknown" }

        if ($user -eq $username) {
            $processName = $process.Name
            $processId = $process.ProcessId
            $kernelTime = $process.KernelModeTime 
            $userTime = $process.UserModeTime
            $content += "{0,-20} {1,-10} {2,-15} {3,-15}" -f $processName, $processId, $kernelTime, $userTime
            $content += "`n"
        }
    }
	
    Set-Content -Path $fileName -Value $content
    Start-Process notepad.exe $fileName
}

Write-Host "Press any key to continue."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Get-Process notepad | ForEach-Object { $_.CloseMainWindow() }
