#!/usr/bin/env pwsh
<#
.SYNOPSIS
Delete a specific Claude session record

.DESCRIPTION
This script allows you to delete a specific session from the session history.

.PARAMETER SessionId
The session ID to delete (e.g., "session-20260205-163000-a1b2c3d4")

.PARAMETER ProjectName
Delete all sessions matching this project name (wildcard supported)

.PARAMETER All
Delete all sessions (use with caution!)

.EXAMPLE
.\delete-session.ps1 -SessionId "session-20260205-163000-a1b2c3d4"

.EXAMPLE
.\delete-session.ps1 -ProjectName "数据集"

.EXAMPLE
.\delete-session.ps1 -ProjectName "*test*"

.EXAMPLE
.\delete-session.ps1 -All
#>

param(
    [Parameter(ParameterSetName='ById', Mandatory=$false)]
    [string]$SessionId,

    [Parameter(ParameterSetName='ByProject', Mandatory=$false)]
    [string]$ProjectName,

    [Parameter(ParameterSetName='All', Mandatory=$false)]
    [switch]$All
)

$localAppData = [Environment]::GetFolderPath('LocalApplicationData')
$sessionsDir = "$localAppData\claude-tools\sessions"

if (-not (Test-Path $sessionsDir)) {
    Write-Host "No sessions directory found." -ForegroundColor Yellow
    exit 0
}

$sessions = Get-ChildItem $sessionsDir -Filter 'session-*.json' | Sort-Object LastWriteTime -Descending

if ($sessions.Count -eq 0) {
    Write-Host "No sessions found." -ForegroundColor Yellow
    exit 0
}

# Function to delete a session
function Remove-SessionFile {
    param($session)

    try {
        $data = Get-Content $session.FullName | ConvertFrom-Json
        Remove-Item $session.FullName -Force
        Write-Host "✓ Deleted: $($data.sessionId)" -ForegroundColor Green
        Write-Host "  Project: $($data.projectName)" -ForegroundColor Gray
        Write-Host "  Directory: $($data.workingDirectory)" -ForegroundColor Gray
        return $true
    } catch {
        Write-Host "✗ Failed to delete: $($session.Name)" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
        return $false
    }
}

# Delete by Session ID
if ($SessionId) {
    $session = $sessions | Where-Object { $_.BaseName -eq $SessionId }

    if (-not $session) {
        Write-Host "Session not found: $SessionId" -ForegroundColor Red
        Write-Host ""
        Write-Host "Tip: Use .\monitor.ps1 list to see all sessions" -ForegroundColor Yellow
        exit 1
    }

    Write-Host "Deleting session..." -ForegroundColor Cyan
    Write-Host ""
    Remove-SessionFile $session
    exit 0
}

# Delete by Project Name
if ($ProjectName) {
    $matchingSessions = @()

    foreach ($s in $sessions) {
        try {
            $data = Get-Content $s.FullName | ConvertFrom-Json
            if ($data.projectName -like $ProjectName) {
                $matchingSessions += $s
            }
        } catch {
            # Skip invalid sessions
        }
    }

    if ($matchingSessions.Count -eq 0) {
        Write-Host "No sessions found matching project name: $ProjectName" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Tip: Use wildcards, e.g., '*test*' or '数据集*'" -ForegroundColor Yellow
        exit 0
    }

    Write-Host "Found $($matchingSessions.Count) session(s) matching '$ProjectName':" -ForegroundColor Cyan
    Write-Host ""

    $deletedCount = 0
    foreach ($s in $matchingSessions) {
        if (Remove-SessionFile $s) {
            $deletedCount++
        }
        Write-Host ""
    }

    Write-Host "Deleted $deletedCount session(s)" -ForegroundColor Green
    exit 0
}

# Delete all sessions
if ($All) {
    Write-Host "WARNING: This will delete ALL sessions!" -ForegroundColor Red
    Write-Host "Total sessions: $($sessions.Count)" -ForegroundColor Yellow
    $confirm = Read-Host "Are you sure? (yes/no)"

    if ($confirm -ne 'yes') {
        Write-Host "Cancelled." -ForegroundColor Yellow
        exit 0
    }

    Write-Host ""
    $deletedCount = 0
    foreach ($s in $sessions) {
        if (Remove-SessionFile $s) {
            $deletedCount++
        }
        Write-Host ""
    }

    Write-Host "Deleted all $deletedCount sessions" -ForegroundColor Green
    exit 0
}

# If no parameters provided, show list and prompt
Write-Host "No parameters provided. Here are all sessions:" -ForegroundColor Cyan
Write-Host ""

.\monitor.ps1 list

Write-Host ""
Write-Host "To delete a session, use one of:" -ForegroundColor Yellow
Write-Host "  .\delete-session.ps1 -SessionId '<session-id>'" -ForegroundColor White
Write-Host "  .\delete-session.ps1 -ProjectName '<project-name>'" -ForegroundColor White
Write-Host "  .\delete-session.ps1 -All" -ForegroundColor White
Write-Host ""
