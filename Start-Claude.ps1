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

    # Save to the same file (overwrite)
    $existingData | ConvertTo-Json | Out-File -FilePath $existingSessionFile -Encoding utf8

    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Claude Session Tracker" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Project: $ProjectName" -ForegroundColor White
    Write-Host "Directory: $workingDir" -ForegroundColor Gray
    Write-Host "Session ID: $sessionId" -ForegroundColor Gray
    Write-Host "✓ Updated existing session" -ForegroundColor Yellow
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

# Start Claude with remaining arguments
& claude @RemainingArgs
