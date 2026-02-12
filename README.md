# Claude Session Manager

Windows 上的 Claude CLI 会话管理工具 - 自动保存和恢复会话，支持多终端类型。

## 功能特性

- 自动保存会话信息（目录、时间戳、项目名）
- 一键恢复之前的会话
- 支持多种终端：PowerShell、Git Bash、CMD
- 会话列表查看和管理

## 安装

```powershell
# 克隆仓库
git clone <repository-url>
cd claude_tools

# （可选）将当前目录添加到 PATH 环境变量
```

## 使用方法

### 启动会话

```powershell
# 使用 PowerShell 启动并记录会话
.\Start-Claude.ps1 "项目名称"

# 示例
.\Start-Claude.ps1 "我的项目"
```

### 会话管理

```powershell
# 查看所有会话
.\monitor.ps1 list

# 恢复会话（交互式选择终端）
.\monitor.ps1 restore

# 查看配置
.\monitor.ps1 config

# 设置 Git Bash 路径
.\monitor.ps1 config -gitbash "C:\Program Files\Git\git-bash.exe"
```

### 恢复会话流程

运行 `.\monitor.ps1 restore` 后：

1. 确认是否恢复 (y/n)
2. 选择终端类型：
   - `1` - PowerShell
   - `2` - Git Bash
   - `3` - CMD
   - `4` - 配置 Git Bash 路径

### 监控模式（可选）

```powershell
# 自动检测并记录正在运行的 Claude 会话
.\monitor.ps1 start

# 停止监控
.\monitor.ps1 stop
```

## 配置文件

配置保存在：`%LOCALAPPDATA%\claude-tools\config.json`

默认配置：
```json
{
    "gitBashPath": "C:\\Program Files\\Git\\git-bash.exe",
    "defaultTerminal": "powershell"
}
```

## 目录结构

```
%LOCALAPPDATA%\claude-tools\
├── config.json          # 配置文件
└── sessions/            # 会话记录
    └── session-*.json   # 会话文件
```

## 系统要求

- Windows 10/11
- PowerShell 5.1+
- Claude Code CLI 已安装

## 文件说明

| 文件 | 说明 |
|------|------|
| `monitor.ps1` | 主脚本 - 会话管理工具 |
| `Start-Claude.ps1` | 启动 Claude 并记录会话 |
| `delete-session.ps1` | 删除指定会话 |

## 常见问题

**Q: 会话保存在哪里？**
A: `%LOCALAPPDATA%\claude-tools\sessions\`

**Q: 如何删除旧会话？**
A: 运行 `.\delete-session.ps1` 选择要删除的会话

**Q: Git Bash 路径不对怎么办？**
A: 运行 `.\monitor.ps1 config -gitbash "正确路径"`

**Q: 支持哪些终端？**
A: PowerShell（默认）、Git Bash、CMD

## License

MIT License
