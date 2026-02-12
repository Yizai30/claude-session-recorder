#!/usr/bin/env pwsh
<#
.SYNOPSIS
Claude Session Monitor - Auto-track all Claude CLI sessions
#>

param(
    [Parameter(Position=0)]
    [ValidateSet('start', 'stop', 'list', 'restore', 'open', 'config', 'help')]
    [string]$Action = 'help',

    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$RemainingArgs
)

$localAppData = [Environment]::GetFolderPath('LocalApplicationData')
$SessionsDir = "$localAppData\claude-tools\sessions"
$MonitorPidFile = "$localAppData\claude-tools\monitor.pid"
$ConfigFile = "$localAppData\claude-tools\config.json"

function Init-SessionsDir {
    if (-not (Test-Path $SessionsDir)) {
        New-Item -ItemType Directory -Path $SessionsDir -Force | Out-Null
    }
}

function Get-Config {
    $configDir = Split-Path -Parent $ConfigFile
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }

    if (Test-Path $ConfigFile) {
        try {
            return Get-Content $ConfigFile | ConvertFrom-Json
        }
        catch {
            # Invalid config, return defaults
        }
    }

    # Default config
    return @{
        gitBashPath = "C:\Program Files\Git\git-bash.exe"
        defaultTerminal = "powershell"
    }
}

function Set-Config {
    param([hashtable]$Config)

    $configDir = Split-Path -Parent $ConfigFile
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }

    $Config | ConvertTo-Json | Out-File -FilePath $ConfigFile -Encoding utf8
}

function Get-ClaudeProcesses {
    $processes = @()
    $nodeProcs = Get-Process -Name node -ErrorAction SilentlyContinue

    foreach ($node in $nodeProcs) {
        try {
            $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($node.Id)").CommandLine
            if ($cmdLine -and $cmdLine -match 'cli\.js') {
                # Get working directory from process
                $procInfo = Get-CimInstance Win32_Process -Filter "ProcessId = $($node.Id)"
                $workingDir = $procInfo.ExecutablePath | Split-Path -Parent

                $processes += @{
                    Id = $node.Id
                    CommandLine = $cmdLine
                    StartTime = $node.StartTime
                    WorkingDirectory = $workingDir
                    WindowTitle = "Claude CLI - $workingDir"
                }
            }
        }
        catch {}
    }
    return $processes
}

function Start-Monitor {
    Write-Host "Claude Monitor starting... (Ctrl+C to stop)" -ForegroundColor Cyan
    $knownProcs = @{}
    
    while ($true) {
        $currentProcs = Get-ClaudeProcesses
        
        foreach ($proc in $currentProcs) {
            if (-not $knownProcs.ContainsKey($proc.Id)) {
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Detected Claude PID=$($proc.Id) at $($proc.WorkingDirectory)" -ForegroundColor Green

                $sessionId = "session-{0:yyyyMMdd-HHmmss}-{1}" -f (Get-Date), [Guid]::NewGuid().ToString().Substring(0,8)
                $sessionData = @{
                    sessionId = $sessionId
                    timestamp = Get-Date -Format 'o'
                    processId = $proc.Id
                    workingDirectory = $proc.WorkingDirectory
                    windowTitle = $proc.WindowTitle
                    autoDetected = $true
                }

                $sessionFile = Join-Path $SessionsDir "$sessionId.json"
                $sessionData | ConvertTo-Json | Out-File -FilePath $sessionFile -Encoding utf8

                $knownProcs[$proc.Id] = $proc
            }
        }
        
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Monitoring $($currentProcs.Count) Claude sessions" -ForegroundColor Gray
        Start-Sleep -Seconds 5
    }
}

function Stop-Monitor {
    if (Test-Path $MonitorPidFile) {
        $pid = Get-Content $MonitorPidFile
        Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
        Remove-Item $MonitorPidFile -Force
        Write-Host "Monitor stopped" -ForegroundColor Green
    }
}

function Update-DirectoryPath {
    param([string]$path)

    # After ConvertFrom-Json, C:\\\\Users becomes C:\\Users (double backslashes)
    # Convert double backslashes to single
    $normalizedPath = $path -replace '\\\\', '\'

    # Map old directory paths to new paths
    $mappings = @{
        'C:\Users\Administrator\source\repos' = 'C:\repos'
        'C:\Users\Administrator\文档' = 'C:\Users\HP\Documents'
    }

    $newPath = $normalizedPath
    foreach ($oldPath in $mappings.Keys) {
        if ($newPath -like "$oldPath*") {
            $newPath = $newPath -replace [regex]::Escape($oldPath), $mappings[$oldPath]
            break
        }
    }

    return $newPath
}

function Show-Sessions {
    Init-SessionsDir
    $sessions = Get-ChildItem $SessionsDir -Filter 'session-*.json' | Sort-Object LastWriteTime -Descending

    Write-Host "`nRecorded Sessions:" -ForegroundColor Cyan
    Write-Host ("=" * 80) -ForegroundColor Gray

    foreach ($s in $sessions) {
        $data = Get-Content $s.FullName | ConvertFrom-Json
        $time = $s.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')

        # Update directory path to new location
        $displayDir = Update-DirectoryPath -path $data.workingDirectory

        Write-Host "`n  Session ID: $($data.sessionId)" -ForegroundColor White
        Write-Host "  Time: $time" -ForegroundColor Gray

        if ($data.projectName) {
            Write-Host "  Project: $($data.projectName)" -ForegroundColor Green
        }
        else {
            Write-Host "  Project: [Unnamed]" -ForegroundColor Yellow
        }

        Write-Host "  Directory: $displayDir" -ForegroundColor Gray
    }

    Write-Host "`n" + ("=" * 80) -ForegroundColor Gray
    Write-Host "Use: .\monitor.ps1 restore" -ForegroundColor Green
}

function Restore-Sessions {
    Init-SessionsDir
    $sessions = Get-ChildItem $SessionsDir -Filter 'session-*.json' | Sort-Object LastWriteTime -Descending

    $grouped = @{}
    foreach ($s in $sessions) {
        $data = Get-Content $s.FullName | ConvertFrom-Json
        $dir = $data.workingDirectory
        # Update directory path to new location
        $mappedDir = Update-DirectoryPath -path $dir
        if (-not $grouped.ContainsKey($mappedDir)) {
            $grouped[$mappedDir] = $data
        }
    }

    Write-Host "`nFound $($grouped.Count) projects. Restore? (y/n): " -NoNewline
    $ans = Read-Host

    if ($ans -eq 'y') {
        # Load config
        $config = Get-Config

        # Choose terminal type
        Write-Host "`nSelect terminal type:" -ForegroundColor Cyan
        Write-Host "1. PowerShell" -ForegroundColor White
        Write-Host "2. Git Bash" -ForegroundColor White
        Write-Host "3. Command Prompt (cmd)" -ForegroundColor White
        Write-Host "4. Configure Git Bash path" -ForegroundColor Yellow
        Write-Host "`nEnter choice [1-4] (default: 1): " -NoNewline
        $terminalChoice = Read-Host

        if (-not $terminalChoice) {
            $terminalChoice = "1"
        }

        # Handle configure option
        if ($terminalChoice -eq "4") {
            Write-Host "`nCurrent Git Bash path: $($config.gitBashPath)" -ForegroundColor Gray
            Write-Host "Enter new Git Bash path (or press Enter to keep current): " -NoNewline
            $newPath = Read-Host

            if ($newPath) {
                $config.gitBashPath = $newPath
                Set-Config -Config $config
                Write-Host "Git Bash path updated!" -ForegroundColor Green
            }

            Write-Host "`nEnter terminal choice [1-3] to proceed (or q to cancel): " -NoNewline
            $terminalChoice = Read-Host

            if ($terminalChoice -eq 'q') {
                Write-Host "Restore cancelled." -ForegroundColor Yellow
                return
            }
        }

        $gitBashPath = $config.gitBashPath

        foreach ($dir in $grouped.Keys) {
            switch ($terminalChoice) {
                "1" {
                    Start-Process powershell.exe -ArgumentList "-NoExit", "-Command", "cd '$dir'; claude"
                    Write-Host "Opened in PowerShell: $dir" -ForegroundColor Green
                }
                "2" {
                    if (Test-Path $gitBashPath) {
                        # Git Bash can use Windows path directly with --cd option
                        Start-Process $gitBashPath -ArgumentList "--cd=`"$dir`"", "-l", "-i", "-c", "exec claude"
                        Write-Host "Opened in Git Bash: $dir" -ForegroundColor Green
                    }
                    else {
                        Write-Host "Git Bash not found at: $gitBashPath" -ForegroundColor Red
                        Write-Host "Run: .\monitor.ps1 restore and select option 4 to configure" -ForegroundColor Yellow
                        Write-Host "Falling back to PowerShell" -ForegroundColor Yellow
                        Start-Process powershell.exe -ArgumentList "-NoExit", "-Command", "cd '$dir'; claude"
                    }
                }
                "3" {
                    Start-Process cmd.exe -ArgumentList "/K", "cd /d `"$dir`" && claude"
                    Write-Host "Opened in CMD: $dir" -ForegroundColor Green
                }
                default {
                    Start-Process powershell.exe -ArgumentList "-NoExit", "-Command", "cd '$dir'; claude"
                    Write-Host "Opened in PowerShell: $dir" -ForegroundColor Green
                }
            }
        }
    }
}

function Show-Config {
    $config = Get-Config
    Write-Host "`nCurrent Configuration:" -ForegroundColor Cyan
    Write-Host ("=" * 50) -ForegroundColor Gray
    Write-Host "Git Bash Path: $($config.gitBashPath)" -ForegroundColor White
    Write-Host "Default Terminal: $($config.defaultTerminal)" -ForegroundColor White
    Write-Host ("=" * 50) -ForegroundColor Gray
    Write-Host "`nTo change Git Bash path:" -ForegroundColor Yellow
    Write-Host "  .\monitor.ps1 config -gitbash <path>" -ForegroundColor White
    Write-Host "`nExample:" -ForegroundColor Yellow
    Write-Host "  .\monitor.ps1 config -gitbash 'C:\Program Files\Git\git-bash.exe'" -ForegroundColor White
}

function Open-Session {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$RemainingArgs
    )

    Init-SessionsDir
    $sessions = Get-ChildItem $SessionsDir -Filter 'session-*.json' | Sort-Object LastWriteTime -Descending

    if ($sessions.Count -eq 0) {
        Write-Host "No sessions found. Start a session with: .\Start-Claude.ps1 \"ProjectName\"" -ForegroundColor Yellow
        return
    }

    $sessionId = $null
    $projectName = $null
    $terminalChoice = "1"

    # Parse arguments
    for ($i = 0; $i -lt $RemainingArgs.Count; $i++) {
        $arg = $RemainingArgs[$i]
        if ($arg -eq '-session' -or $arg -eq '-s') {
            if ($i + 1 -lt $RemainingArgs.Count) {
                $sessionId = $RemainingArgs[$i + 1]
                $i++
            }
        }
        elseif ($arg -eq '-project' -or $arg -eq '-p') {
            if ($i + 1 -lt $RemainingArgs.Count) {
                $projectName = $RemainingArgs[$i + 1]
                $i++
            }
        }
        elseif ($arg -eq '-terminal' -or $arg -eq '-t') {
            if ($i + 1 -lt $RemainingArgs.Count) {
                $terminalChoice = $RemainingArgs[$i + 1]
                $i++
            }
        }
    }

    $targetSession = $null

    # Find by session ID
    if ($sessionId) {
        foreach ($s in $sessions) {
            $data = Get-Content $s.FullName | ConvertFrom-Json
            if ($data.sessionId -eq $sessionId -or $s.Name -eq "$sessionId.json") {
                $targetSession = $data
                break
            }
        }
        if (-not $targetSession) {
            Write-Host "Session not found: $sessionId" -ForegroundColor Red
            return
        }
    }
    # Find by project name
    elseif ($projectName) {
        foreach ($s in $sessions) {
            $data = Get-Content $s.FullName | ConvertFrom-Json
            if ($data.projectName -and $data.projectName -like "*$projectName*") {
                $targetSession = $data
                break
            }
        }
        if (-not $targetSession) {
            Write-Host "Project not found: $projectName" -ForegroundColor Red
            Write-Host "Use '.\monitor.ps1 list' to see available sessions" -ForegroundColor Yellow
            return
        }
    }
    # No filter specified, show selection
    else {
        Write-Host "`nAvailable sessions:" -ForegroundColor Cyan
        $idx = 1
        $sessionList = @()
        foreach ($s in $sessions | Select-Object -First 10) {
            $data = Get-Content $s.FullName | ConvertFrom-Json
            $displayDir = Update-DirectoryPath -path $data.workingDirectory
            $projName = if ($data.projectName) { $data.projectName } else { "[Unnamed]" }

            Write-Host "  [$idx] $projName" -ForegroundColor White
            Write-Host "      Directory: $displayDir" -ForegroundColor Gray
            Write-Host "      Session: $($data.sessionId)" -ForegroundColor Gray
            Write-Host ""

            $sessionList += $data
            $idx++
        }

        Write-Host "Select session [1-$($sessionList.Count)] (or 0 to cancel): " -NoNewline
        $selection = Read-Host
        $selectionNum = [int]$selection

        if ($selectionNum -eq 0 -or $selectionNum -lt 1 -or $selectionNum -gt $sessionList.Count) {
            Write-Host "Cancelled." -ForegroundColor Yellow
            return
        }

        $targetSession = $sessionList[$selectionNum - 1]
    }

    # Get terminal choice and config
    $config = Get-Config
    $gitBashPath = $config.gitBashPath

    # Update directory path
    $targetDir = Update-DirectoryPath -path $targetSession.workingDirectory

    # Start the session
    switch ($terminalChoice) {
        "1" {
            Start-Process powershell.exe -ArgumentList "-NoExit", "-Command", "cd '$targetDir'; claude"
            Write-Host "Opened in PowerShell: $targetDir" -ForegroundColor Green
        }
        "2" {
            if (Test-Path $gitBashPath) {
                Start-Process $gitBashPath -ArgumentList "--cd=`"$targetDir`"", "-l", "-i", "-c", "exec claude"
                Write-Host "Opened in Git Bash: $targetDir" -ForegroundColor Green
            }
            else {
                Write-Host "Git Bash not found. Falling back to PowerShell." -ForegroundColor Yellow
                Start-Process powershell.exe -ArgumentList "-NoExit", "-Command", "cd '$targetDir'; claude"
            }
        }
        "3" {
            Start-Process cmd.exe -ArgumentList "/K", "cd /d `"$targetDir`" && claude"
            Write-Host "Opened in CMD: $targetDir" -ForegroundColor Green
        }
        default {
            Start-Process powershell.exe -ArgumentList "-NoExit", "-Command", "cd '$targetDir'; claude"
            Write-Host "Opened in PowerShell: $targetDir" -ForegroundColor Green
        }
    }

    Write-Host "`nSession Info:" -ForegroundColor Cyan
    if ($targetSession.projectName) {
        Write-Host "  Project: $($targetSession.projectName)" -ForegroundColor White
    }
    Write-Host "  Directory: $targetDir" -ForegroundColor White
}

function Set-ConfigFromArgs {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$RemainingArgs
    )

    $config = Get-Config
    $GitBashPath = $null

    # Parse arguments manually
    for ($i = 0; $i -lt $RemainingArgs.Count; $i++) {
        $arg = $RemainingArgs[$i]
        if ($arg -eq '-gitbash' -or $arg -eq '-GitBashPath') {
            if ($i + 1 -lt $RemainingArgs.Count) {
                $GitBashPath = $RemainingArgs[$i + 1]
                $i++
            }
        }
    }

    if ($GitBashPath) {
        if (Test-Path $GitBashPath) {
            $config.gitBashPath = $GitBashPath
            Set-Config -Config $config
            Write-Host "Git Bash path updated to: $GitBashPath" -ForegroundColor Green
        }
        else {
            Write-Host "Error: Path not found: $GitBashPath" -ForegroundColor Red
            return
        }
    }

    Show-Config
}

switch ($Action) {
    'start' {
        $PID | Out-File -FilePath $MonitorPidFile -Encoding utf8
        try { Start-Monitor } finally { Remove-Item $MonitorPidFile -Force -ErrorAction SilentlyContinue }
    }
    'stop' { Stop-Monitor }
    'list' { Show-Sessions }
    'restore' { Restore-Sessions }
    'open' { Open-Session @RemainingArgs }
    'config' { Set-ConfigFromArgs @RemainingArgs }
    'help' {
        Get-Help $MyInvocation.MyCommand.Path -Full
        Write-Host "`nQuick Examples:" -ForegroundColor Cyan
        Write-Host "  .\monitor.ps1 list" -ForegroundColor White
        Write-Host "  .\monitor.ps1 open -project \"MyProject\" -terminal 2" -ForegroundColor White
        Write-Host "  .\monitor.ps1 open -session session-20250101-120000-abcd1234" -ForegroundColor White
        Write-Host "  .\monitor.ps1 config -gitbash \"C:\Program Files\Git\git-bash.exe\"" -ForegroundColor White
    }
}
