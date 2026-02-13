#!/bin/bash
# Start Claude CLI with session tracking for Git Bash
# This script is a wrapper for Start-Claude.ps1

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
USE_GIT_BASH=false

# Parse arguments
shift
while [ $# -gt 0 ]; do
    case "$1" in
        -UseGitBash)
            USE_GIT_BASH=true
            ;;
        *)
            # Pass remaining arguments to Claude
            break
            ;;
    esac
    shift
done

# Call PowerShell script
if [ "$USE_GIT_BASH" = true ]; then
    # Already in Git Bash, just run pwsh directly
    pwsh -File "$SCRIPT_DIR/Start-Claude.ps1" -ProjectName "$PROJECT_NAME" -UseGitBash
else
    # In Git Bash but want PowerShell, still use pwsh
    pwsh -File "$SCRIPT_DIR/Start-Claude.ps1" -ProjectName "$PROJECT_NAME"
fi
