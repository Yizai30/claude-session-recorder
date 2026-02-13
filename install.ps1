#!/usr/bin/env pwsh
<#
.SYNOPSIS
Install Claude Session Manager to PATH

.DESCRIPTION
This script adds the current directory to PATH for easy access.

.EXAMPLE
.\install.ps1
#>

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Claude Session Manager - 安装" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get current directory
$toolDir = Get-Location
Write-Host "工具目录: $toolDir" -ForegroundColor White
Write-Host ""

# Detect shell type
$isGitBash = $env:GIT_BASH -eq "true"

if ($isGitBash) {
    # Git Bash installation
    $bashrcPath = "$env:HOME/.bashrc"
    $pathEntry = "export PATH=`$PATH:$toolDir`""

    # Check if already in PATH
    $bashrcContent = ""
    if (Test-Path $bashrcPath) {
        $bashrcContent = Get-Content $bashrcPath -Raw
    }

    if ($bashrcContent -notlike "*$toolDir*") {
        # Add to .bashrc
        $pathEntry | Out-File -FilePath $bashrcPath -Append -Encoding utf8
        Write-Host "✓ 已添加到 ~/.bashrc:" -ForegroundColor Green
        Write-Host "  $pathEntry" -ForegroundColor Gray
        Write-Host ""
        Write-Host "请执行以下命令使生效:" -ForegroundColor Yellow
        Write-Host "  source ~/.bashrc" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host "✓ 已经在 PATH 中" -ForegroundColor Green
        Write-Host ""
    }
} else {
    # PowerShell installation
    $pathEntry = $toolDir

    # Check current user PATH
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $inPath = $currentPath -split ";" | Where-Object { $_ -eq $toolDir }

    if (-not $inPath) {
        # Add to user PATH
        $newPath = "$currentPath;$toolDir"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")

        Write-Host "✓ 已添加到用户 PATH:" -ForegroundColor Green
        Write-Host "  $toolDir" -ForegroundColor Gray
        Write-Host ""
        Write-Host "请重启 PowerShell 使生效" -ForegroundColor Yellow
        Write-Host ""
    } else {
        Write-Host "✓ 已经在 PATH 中" -ForegroundColor Green
        Write-Host ""
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
