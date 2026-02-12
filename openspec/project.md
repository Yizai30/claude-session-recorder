# Project Context

## Purpose
A Windows automation tool to persist and restore Claude CLI sessions, eliminating manual recovery of chat contexts after terminal closures or system reboots. The tool automatically saves session state and provides one-click recovery via `/resume`, reducing cognitive overhead and manual workflow steps.

## Tech Stack
- **Language**: TBD (to be determined - considering Python, PowerShell, or Node.js)
- **Platform**: Windows (cmd, PowerShell, Windows Terminal)
- **Target**: Claude Code CLI (claude-cli/claude-code)

## Project Conventions

### Code Style
- Preference for simple, readable code over complex abstractions
- Follow Windows platform conventions for file paths and environment variables
- Use descriptive variable names (self-documenting code)

### Architecture Patterns
- Start with single-file, script-based implementation
- Add complexity only when proven necessary (avoid over-engineering)
- Prefer straightforward solutions over framework-heavy approaches

### Testing Strategy
- Manual testing on Windows with Claude CLI
- Test scenarios: session save, terminal close, reboot, recovery
- Verify data integrity (no chat history loss)

### Git Workflow
- Feature branches for each capability
- Conventional commit messages (feat:, fix:, docs:)
- PR review before merging to main

## Domain Context

### Claude CLI Behavior
- Claude CLI stores session state in terminal/process memory
- `/resume` command lists previous sessions for recovery
- Closing terminal loses in-memory state
- Sessions are identified by names/IDs

### Windows Environment
- Multiple shell environments: cmd, PowerShell, Windows Terminal
- Environment variables for configuration
- File system for persistent storage (%APPDATA%, %LOCALAPPDATA%, or project directory)

## Important Constraints

### Platform Constraints
- Windows-only (Windows 10/11)
- Must work across cmd, PowerShell, and Windows Terminal
- No assumption of admin privileges

### Usability Constraints
- Minimal installation/config overhead
- No interference with normal Claude CLI usage
- Fast save/restore operations (< 1 second typical)

## External Dependencies

### Required
- Claude Code CLI (must be installed and in PATH)
- Windows OS (version 10+)

### Optional
- Configuration file for custom storage paths
- Integration with Windows startup/task scheduler (future)
