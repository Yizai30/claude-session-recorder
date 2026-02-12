# Change: Session Persistence System

## Why
When using Claude CLI on Windows, closing terminal windows or rebooting the system loses all in-memory session state. Users must manually remember and restore previous sessions using `/resume`, which is time-consuming, error-prone, and creates cognitive overhead. This automation eliminates manual recovery workflow.

## What Changes
- Auto-save Claude CLI session state to persistent storage before terminal closure
- Provide easy session listing and one-command recovery
- Support cmd, PowerShell, and Windows Terminal environments
- Store sessions in user directory (default: `%LOCALAPPDATA%\claude-tools\sessions\`)
- No modification to Claude CLI itself - works as external wrapper/monitor

## Impact
- Affected specs: session-persistence (new capability)
- Affected code: New session monitoring, storage, and recovery module
- Breaking changes: None (additive feature)
- User-facing: New commands available for session management
