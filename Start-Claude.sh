#!/bin/bash
# Start Claude CLI with session tracking for Git Bash
# This script is a wrapper for Start-Claude.ps1

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find PowerShell executable
POWERSHELL_EXE=""
if command -v pwsh &> /dev/null; then
    POWERSHELL_EXE="pwsh"
elif command -v powershell &> /dev/null; then
    POWERSHELL_EXE="powershell"
else
    # Try default paths
    if [ -f "/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe" ]; then
        POWERSHELL_EXE="/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
    elif [ -f "C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe" ]; then
        POWERSHELL_EXE="C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
    else
        echo "错误: 找不到 PowerShell"
        exit 1
    fi
fi

# Check if project name is provided
if [ -z "$1" ]; then
    echo "错误: 请提供项目名称"
    echo ""
    echo "用法: ./Start-Claude.sh \"项目名称\""
    echo ""
    echo "示例:"
    echo "  ./Start-Claude.sh \"我的项目\""
    exit 1
fi

PROJECT_NAME="$1"

# Call PowerShell script with project name
# The -File parameter expects a Windows path
"$POWERSHELL_EXE" -File "$SCRIPT_DIR/Start-Claude.ps1" -ProjectName "$PROJECT_NAME"

echo "✓ 已启动项目: $PROJECT_NAME"
