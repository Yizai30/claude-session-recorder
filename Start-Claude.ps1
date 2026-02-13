#!/usr/bin/env pwsh
<#
.SYNOPSIS
Start Claude CLI with session tracking

.PARAMETER ProjectName
Name/label for this project (e.g., "Web App", "API Service")

.PARAMETER UseGitBash
Start Claude in Git Bash instead of PowerShell

.DESCRIPTION
This script:
1. Records the current directory with a project name
2. Starts Claude CLI in the specified terminal
3. Makes it easy to restore later with monitor.ps1

.EXAMPLE
cd C:\my-project
.\Start-Claude.ps1 "Web App"

.EXAMPLE
cd C:\my-project
.\Start-Claude.ps1 "Web App" -UseGitBash
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$ProjectName,

    [Parameter(Mandatory=$false)]
    [switch]$UseGitBash,

    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$RemainingArgs
)

# Configuration
$localAppData = [Environment]::GetFolderPath('LocalApplicationData')
$sessionsDir = "$localAppData\claude-tools\sessions"
$configFile = "$localAppData\claude-tools\config.json"

# Initialize sessions directory
if (-not (Test-Path $sessionsDir)) {
    New-Item -ItemType Directory -Path $sessionsDir -Force | Out-Null
}

# Load config to get Git Bash path
function Get-Config {
    if (Test-Path $configFile) {
        try {
            return Get-Content $configFile | ConvertFrom-Json
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

$config = Get-Config

# Get current directory
$workingDir = Get-Location

# Check for existing sessions with same project name and directory
$sessions = Get-ChildItem $sessionsDir -Filter 'session-*.json' -ErrorAction SilentlyContinue
$existingSessionFile = $null
$oldSessionId = $null
$existingData = $null

if ($sessions) {
    foreach ($s in $sessions) {
        try {
            $data = Get-Content $s.FullName | ConvertFrom-Json
            # Check if same project name and same directory
            if ($data.projectName -eq $ProjectName -and $data.workingDirectory -eq $workingDir.Path) {
                $existingSessionFile = $s.FullName
                $oldSessionId = $data.sessionId
                $existingData = $data
                break
            }
        } catch {
            # Skip invalid sessions
        }
    }
}

# Generate new session ID
$sessionId = "session-{0:yyyyMMdd-HHmmss}-{1}" -f (Get-Date), [Guid]::NewGuid().ToString().Substring(0,8)

# Update existing session or create new one
if ($existingData) {
    # Update existing session data
    $existingData.timestamp = Get-Date -Format 'o'
    $existingData.sessionId = $sessionId

    # Get new filename and old filename
    $newFilename = "$sessionId.json"
    $oldFilename = Split-Path $existingSessionFile -Leaf

    # Save to new file with new session ID
    $newSessionFile = Join-Path $sessionsDir $newFilename
    $existingData | ConvertTo-Json | Out-File -FilePath $newSessionFile -Encoding utf8

    # Delete old file
    Remove-Item $existingSessionFile -Force

    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Claude Session Tracker" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Project: $ProjectName" -ForegroundColor White
    Write-Host "Directory: $workingDir" -ForegroundColor Gray
    Write-Host "Old Session: $oldSessionId" -ForegroundColor Gray
    Write-Host "New Session: $sessionId" -ForegroundColor Gray
    Write-Host "✓ Session updated (renamed: $oldFilename -> $newFilename)" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
} else {
    # Create new session
    $sessionData = @{
        sessionId = $sessionId
        timestamp = Get-Date -Format 'o'
        projectName = $ProjectName
        workingDirectory = $workingDir.Path
        autoDetected = $false
        manualMark = $true
    }

    $sessionFile = Join-Path $sessionsDir "$sessionId.json"
    $sessionData | ConvertTo-Json | Out-File -FilePath $sessionFile -Encoding utf8

    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Claude Session Tracker" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Project: $ProjectName" -ForegroundColor White
    Write-Host "Directory: $workingDir" -ForegroundColor Gray
    Write-Host "Session ID: $sessionId" -ForegroundColor Gray
    Write-Host "✓ New session created" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

# Start Claude in appropriate terminal
$terminalUsed = ""

if ($UseGitBash) {
    # Check if Git Bash exists
    if (-not (Test-Path $config.gitBashPath)) {
        Write-Host "Warning: Git Bash not found at: $($config.gitBashPath)" -ForegroundColor Yellow
        Write-Host "Falling back to PowerShell..." -ForegroundColor Yellow
        Write-Host ""
        Start-Sleep -Seconds 2
    }
    else {
        # Start in Git Bash
        $terminalUsed = "Git Bash"
        Start-Process $config.gitBashPath -ArgumentList "--cd=`"$workingDir`"", "-l", "-i", "-c", "exec claude"
        Write-Host "Started in Git Bash" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        exit 0
    }
}

# Default: Start in PowerShell
$terminalUsed = "PowerShell"
& claude @RemainingArgs
