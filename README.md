# Claude Session Manager

Windows 上的 Claude CLI 会话管理工具 - 自动记录项目路径，一键恢复会话。

## 核心功能

这是一个**项目路径管理工具**，帮助你记录和快速访问不同项目的 Claude 会话，无需记忆复杂的文件夹路径。

### 主要用途

- 📁 **记录项目路径**：自动保存每个项目的目录位置
- 🔍 **快速查找项目**：按项目名称或会话 ID 搜索
- 🚀 **一键启动**：在指定终端中快速打开项目会话
- 🎯 **多终端支持**：PowerShell、Git Bash、CMD

### ⚠️ 重要说明

**必须通过 `Start-Claude.ps1` 启动会话才能被工具记录！**

```powershell
# ✅ 正确方式 - 会被记录
.\Start-Claude.ps1 "我的项目"

# ❌ 错误方式 - 不会被记录
claude
```

只有通过 `Start-Claude.ps1` 启动的会话才会被自动记录到本地数据库中。

## 安装

```powershell
# 克隆仓库
git clone https://gitee.com/Yizai30/claude-session-recorder.git
cd claude-session-recorder

# （可选）将当前目录添加到 PATH 环境变量
```

## 快速开始

### 1️⃣ 启动新会话并记录

```powershell
# 启动并记录项目
.\Start-Claude.ps1 "项目名称"

# 示例
.\Start-Claude.ps1 "博客系统"
.\Start-Claude.ps1 "AI助手"
```

执行后：
- ✅ 自动在项目目录启动 Claude
- ✅ 记录项目路径和名称
- ✅ 生成唯一会话 ID

### 2️⃣ 查看已记录的项目

```powershell
# 列出所有项目
.\monitor.ps1 list
```

输出示例：
```
Recorded Sessions:
================================================================================

  Session ID: session-20250212-120000-abcd1234
  Time: 2025-02-12 12:00:00
  Project: 博客系统
  Directory: C:\repos\blog-system

  Session ID: session-20250211-153022-efgh5678
  Time: 2025-02-11 15:30:22
  Project: AI助手
  Directory: C:\repos\ai-assistant
```

### 3️⃣ 快速打开项目

```powershell
# 方式一：按项目名称打开
.\monitor.ps1 open -project "博客"

# 方式二：按会话 ID 打开
.\monitor.ps1 open -session session-20250212-120000-abcd1234

# 方式三：交互式选择
.\monitor.ps1 open

# 指定终端类型（1=PowerShell, 2=Git Bash, 3=CMD）
.\monitor.ps1 open -project "博客" -terminal 2
```

### 4️⃣ 批量恢复所有项目

```powershell
# 恢复所有已记录的项目（每个项目一个终端窗口）
.\monitor.ps1 restore
```

## 命令详解

### monitor.ps1 - 主管理工具

```powershell
# 查看所有项目
.\monitor.ps1 list

# 打开指定项目
.\monitor.ps1 open -project "项目名"
.\monitor.ps1 open -session "会话ID"
.\monitor.ps1 open                    # 交互式选择

# 批量恢复所有项目
.\monitor.ps1 restore

# 配置管理
.\monitor.ps1 config                          # 查看配置
.\monitor.ps1 config -gitbash "路径"           # 设置 Git Bash 路径

# 帮助
.\monitor.ps1 help
```

### Start-Claude.ps1 - 启动并记录

```powershell
.\Start-Claude.ps1 "项目名称"
```

**参数**：
- `ProjectName`：项目名称（必需）
  - 用于标识和搜索项目
  - 建议使用简洁的中文名称

### open 命令参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `-project`, `-p` | 按项目名称打开（支持模糊搜索） | `-project "博客"` |
| `-session`, `-s` | 按会话 ID 打开 | `-session session-2025...` |
| `-terminal`, `-t` | 终端类型（1/2/3） | `-terminal 2` |

终端类型：
- `1` = PowerShell（默认）
- `2` = Git Bash
- `3` = CMD

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
├── config.json              # 配置文件
└── sessions/               # 会话记录目录
    └── session-*.json      # 会话文件
```

## 使用场景

### 场景一：管理多个项目

```powershell
# 项目 1：博客系统
cd C:\repos\blog-system
.\Start-Claude.ps1 "博客系统"

# 项目 2：AI 助手
cd C:\repos\ai-assistant
.\Start-Claude.ps1 "AI助手"

# 切换工作：快速打开博客项目
.\monitor.ps1 open -project "博客"

# 切换工作：快速打开 AI 项目
.\monitor.ps1 open -project "AI"
```

### 场景二：忘记项目路径

```powershell
# 查看所有项目
.\monitor.ps1 list

# 找到后直接打开
.\monitor.ps1 open -project "项目名"
```

### 场景三：团队协作

不同项目使用不同目录，通过工具快速切换：

```powershell
# 项目 A
cd D:\projects\project-a
.\Start-Claude.ps1 "项目A"

# 项目 B
cd D:\projects\project-b
.\Start-Claude.ps1 "项目B"
```

## 系统要求

- Windows 10/11
- PowerShell 5.1+
- Claude Code CLI 已安装

## 常见问题

### Q: 为什么我的会话没有被记录？

**A**: 必须通过 `Start-Claude.ps1` 启动才能被记录。

```powershell
# ✅ 会被记录
.\Start-Claude.ps1 "我的项目"

# ❌ 不会被记录
claude
```

### Q: 会话保存在哪里？

A: `%LOCALAPPDATA%\claude-tools\sessions\`

### Q: 如何删除旧会话？

A: 运行 `.\delete-session.ps1` 选择要删除的会话

### Q: Git Bash 路径不对怎么办？

A: 运行 `.\monitor.ps1 config -gitbash "正确路径"`

### Q: 支持哪些终端？

A: PowerShell（默认）、Git Bash、CMD

### Q: 项目名称可以重复吗？

A: 可以。`open` 命令会匹配第一个包含关键词的项目。

## 文件说明

| 文件 | 说明 |
|------|------|
| `monitor.ps1` | 主管理脚本 |
| `Start-Claude.ps1` | 启动并记录会话 |
| `delete-session.ps1` | 删除会话 |

## License

MIT License
