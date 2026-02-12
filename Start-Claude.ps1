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

# Generate session ID
$sessionId = "session-{0:yyyyMMdd-HHmmss}-{1}" -f (Get-Date), [Guid]::NewGuid().ToString().Substring(0,8)

# Get current directory
$workingDir = Get-Location

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

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Claude Session Tracker" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Project: $ProjectName" -ForegroundColor White
Write-Host "Directory: $workingDir" -ForegroundColor Gray
Write-Host "Session ID: $sessionId" -ForegroundColor Gray
Write-Host "✓ Session saved" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Start Claude with remaining arguments
& claude @RemainingArgs
