#!/usr/bin/env pwsh
<#
.SYNOPSIS
Start Claude CLI with session tracking

.PARAMETER ProjectName
Name/label for this project (e.g., "Web App", "API Service")

.DESCRIPTION
This script:
1. Records the current directory with a project name
2. Starts Claude CLI
3. Makes it easy to restore later with monitor.ps1

.EXAMPLE
cd C:\my-project
.\Start-Claude.ps1 "Web App"
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$ProjectName,

    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$RemainingArgs
)

# Configuration
$localAppData = [Environment]::GetFolderPath('LocalApplicationData')
$sessionsDir = "$localAppData\claude-tools\sessions"

# Initialize sessions directory
if (-not (Test-Path $sessionsDir)) {
    New-Item -ItemType Directory -Path $sessionsDir -Force | Out-Null
}

# Get current directory
$workingDir = Get-Location

# Check for existing sessions with same project name and directory
$sessions = Get-ChildItem $sessionsDir -Filter 'session-*.json' -ErrorAction SilentlyContinue
$existingSessionFile = $null
$oldSessionId = $null

if ($sessions) {
    foreach ($s in $sessions) {
        try {
            $data = Get-Content $s.FullName | ConvertFrom-Json
            # Check if same project name and same directory
            if ($data.projectName -eq $ProjectName -and $data.workingDirectory -eq $workingDir.Path) {
                $existingSessionFile = $s.FullName
                $oldSessionId = $data.sessionId
                break
            }
        } catch {
            # Skip invalid sessions
        }
    }
}

# Generate new session ID
$sessionId = "session-{0:yyyyMMdd-HHmmss}-{1}" -f (Get-Date), [Guid]::NewGuid().ToString().Substring(0,8)

# Create session data
$sessionData = @{
    sessionId = $sessionId
    timestamp = Get-Date -Format 'o'
    projectName = $ProjectName
    workingDirectory = $workingDir.Path
    autoDetected = $false
    manualMark = $true
}

# Save session
$sessionFile = Join-Path $sessionsDir "$sessionId.json"
$sessionData | ConvertTo-Json | Out-File -FilePath $sessionFile -Encoding utf8

# Delete old session file if exists
if ($existingSessionFile) {
    Remove-Item $existingSessionFile -Force
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Claude Session Tracker" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Project: $ProjectName" -ForegroundColor White
Write-Host "Directory: $workingDir" -ForegroundColor Gray
Write-Host "Session ID: $sessionId" -ForegroundColor Gray

if ($existingSessionFile) {
    Write-Host "✓ Session updated (removed old: $oldSessionId)" -ForegroundColor Yellow
} else {
    Write-Host "✓ New session created" -ForegroundColor Green
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Start Claude with remaining arguments
& claude @RemainingArgs
