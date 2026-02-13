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

### 📌 启动前必读

**启动前必须先 cd 到项目目录！**

```powershell
# ❌ 错误：在工具目录启动
cd C:\repos\claude_tools
.\Start-Claude.ps1 "博客系统"    # 会记录工具目录，不是项目目录！

# ✅ 正确：先 cd 到项目目录
cd C:\repos\my-blog
.\Start-Claude.ps1 "博客系统"    # 正确记录项目目录

# ✅ 或者根据已记录的项目路径进行 cd
.\monitor.ps1 list    # 查看项目路径
cd C:\repos\my-blog     # 切换到项目目录
.\Start-Claude.ps1 "博客系统"    # 启动并记录
```

**原因**：`Start-Claude.ps1` 会记录**当前目录**作为项目路径，所以必须先 cd 到实际的项目目录。

## 安装

### 方法一：自动安装脚本（推荐）

```powershell
# 运行自动安装脚本
.\install.ps1

# 脚本会自动检测终端类型并添加到 PATH
# PowerShell 用户：添加到用户 PATH 环境变量
# Git Bash 用户：添加到 ~/.bashrc 文件
```

⚠️ **重要**：必须将工具目录添加到 PATH，才能在任何目录下使用命令！

### 方法二：手动添加到 PATH

```powershell
# 1. 克隆仓库
git clone https://gitee.com/Yizai30/claude-session-recorder.git
cd claude-session-recorder

# 2. PowerShell 用户：添加到用户 PATH
$env:Path += ";C:\repos\claude-session-recorder"

# 3. Git Bash 用户（添加到 ~/.bashrc）
echo 'export PATH="$PATH:/c/repos/claude-session-recorder"' >> ~/.bashrc
source ~/.bashrc
```

```powershell
# 不添加 PATH，使用完整路径
C:\repos\claude-session-recorder\Start-Claude.ps1 "项目名称"

# Git Bash 中
/c/repos/claude-session-recorder/Start-Claude.sh "项目名称"
```

## 快速开始

### ⚠️ 安装前必读

**必须先将工具目录添加到 PATH 环境变量！**

- **PowerShell 用户**：添加到系统 PATH
- **Git Bash 用户**：添加到 `~/.bashrc`

添加到 PATH 后，可以在任何目录下直接使用命令（不需要 `./` 前缀）。

### 1️⃣ 启动新会话并记录

**已添加到 PATH 后**（推荐）：
```powershell
# 在任意目录下，直接使用命令
cd /c/repos/my-project
Start-Claude.ps1 "项目名称"

# Git Bash 中使用
Start-Claude.sh "项目名称"

# 示例
Start-Claude.sh "博客系统"
Start-Claude.sh "AI助手"
```

**未添加到 PATH**（需要在工具目录执行）：
```powershell
# 必须先 cd 到工具目录
cd C:\repos\claude-session-recorder

# 在 PowerShell 中启动（默认）
.\Start-Claude.ps1 "项目名称"

# 在 Git Bash 中启动
.\Start-Claude.sh "项目名称"
```

执行后：
- ✅ 自动在项目目录启动 Claude
- ✅ 记录项目路径和名称
- ✅ 生成唯一会话 ID
- ✅ 在 Git Bash 中正常使用

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
# 在 PowerShell 中启动（默认）
.\Start-Claude.ps1 "项目名称"

# 在 Git Bash 中启动
.\Start-Claude.ps1 "项目名称" -UseGitBash
```

**PowerShell 用户参数**（`Start-Claude.ps1`）：
- `ProjectName`：项目名称（必需）
  - 用于标识和搜索项目
  - 建议使用简洁的中文名称
- `-UseGitBash`：在 Git Bash 中启动（仅限 PowerShell，Git Bash 用户请直接用 .sh 文件）
  - 使用 Git Bash 终端代替 PowerShell

**Git Bash 用户使用**（`Start-Claude.sh`）：
- 直接执行 `./Start-Claude.sh "项目名称"`
- 自动调用 PowerShell 脚本完成会话记录和启动

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

### Q: 如何在 Git Bash 中启动 Claude？

A: **推荐方式**：使用 `Start-Claude.sh` 脚本

```bash
# 在 Git Bash 中启动
cd /c/repos/my-project
./Start-Claude.sh "我的项目"

# 示例
./Start-Claude.sh "博客系统"
./Start-Claude.sh "AI助手"
```

**备用方式**（不推荐）：在 Git Bash 中调用 PowerShell 脚本

```bash
# 不推荐，但也可以用
./Start-Claude.ps1 "我的项目" -UseGitBash
```

### Q: 项目名称可以重复吗？

A: 可以。`open` 命令会匹配第一个包含关键词的项目。

## 文件说明

| 文件 | 说明 | 适用终端 |
|------|------|----------|
| `monitor.ps1` | 主管理脚本 | PowerShell、Git Bash |
| `Start-Claude.ps1` | 启动并记录会话 | PowerShell |
| `Start-Claude.sh` | Git Bash 启动脚本 | Git Bash |
| `install.ps1` | 自动安装到 PATH | PowerShell、Git Bash |
| `delete-session.ps1` | 删除会话 | PowerShell、Git Bash |

## 常见问题

### Q: 如何安装工具到 PATH？

A: 运行自动安装脚本 `.\install.ps1`，它会自动检测终端类型并添加到 PATH。

### Q: 为什么我的会话没有被记录？

**A**: 必须通过 `Start-Claude.ps1`（PowerShell）或 `Start-Claude.sh`（Git Bash）启动才能被记录。

```powershell
# ✅ 会被记录
Start-Claude.ps1 "我的项目"     # PowerShell
Start-Claude.sh "我的项目"      # Git Bash

# ❌ 不会被记录
claude
```

### Q: 会话保存在哪里？

A: `%LOCALAPPDATA%\claude-tools\sessions\`

### Q: 如何删除旧会话？

A: 运行 `.\delete-session.ps1` 选择要删除的会话

### Q: 如何在 Git Bash 中启动 Claude？

A: **推荐方式**：直接使用 `Start-Claude.sh`

```bash
Start-Claude.sh "我的项目"
```

**备用方式**（不推荐）：调用 PowerShell 脚本

```bash
Start-Claude.ps1 "我的项目" -UseGitBash
```

### Q: 项目名称可以重复吗？

A: 可以。`open` 命令会匹配第一个包含关键词的项目。

## License

MIT License
