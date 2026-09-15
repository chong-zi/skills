---
name: mcp-note
description: 整理 MCP 服务笔记。给定 MCP 服务的 GitHub 地址，自动抓取信息，按 5W1H 结构生成结构化中文笔记，输出为 Obsidian 兼容的 Markdown 文件。触发场景：用户提供 MCP GitHub 链接并要求整理/记录/写笔记。
---

# mcp-note

给定一个 MCP 服务的 GitHub 地址，生成结构化中文笔记。

## 工作流程

### 第一步：抓取信息

从以下来源获取内容：
1. GitHub README（优先用 `https://raw.githubusercontent.com/{owner}/{repo}/main/README.md`）
2. 如有 npm 包，查看 package.json 了解安装方式

重点提取：
- 服务描述和核心机制
- 所有工具（tools）列表及说明
- 所有命令行参数/配置项
- 安装配置方式（各客户端）
- 使用场景

### 第二步：按模板生成笔记

严格按照以下结构输出，章节标注保留英文括号注释：

```markdown
{GitHub URL}

# 说明(what)

{1-2句话说明是什么，有什么作用、价值，谁出品}

## 核心原理(how it works)

{工作机制，技术原理，与同类工具的区别}

## 适合场景(when&where&why)

**用它的理由**：{为什么选它，对比其他方案的优势}

**适合场景**：
- {场景1}
- {场景2}

## 安装(how to install)

### 通用（Claude Desktop / VS Code / Cursor / Windsurf 等）

\`\`\`json
{
  "mcpServers": {
    "{name}": {
      "command": "npx",
      "args": ["{package}"]
    }
  }
}
\`\`\`

### Claude Code（CLI）

\`\`\`bash
claude mcp add {name} npx {package}
\`\`\`

### opencode（`~/.config/opencode/opencode.json`）

\`\`\`json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "{name}": {
      "type": "local",
      "command": ["npx", "{package}"],
      "enabled": true
    }
  }
}
\`\`\`

### Codex（`~/.codex/config.toml`）

\`\`\`toml
[mcp_servers.{name}]
command = "npx"
args = ["{package}"]
\`\`\`

## 配置(how to config)

### {分类1}

| 参数 | 说明 |
|------|------|
| `--param` | 说明 |

### 会话模式（如有）

| 模式 | 说明 |
|------|------|

## 主要工具(how to use)

### {官方分类名}

| 工具 | 功能 |
|------|------|
| `tool_name` | 功能说明 |

### 扩展能力（按需开启，如有）

{说明}
```

### 第三步：保存文件

- 询问用户保存路径（默认建议当前目录，或用户指定的笔记库目录）；若用户未指定，用 `{服务名}.md` 保存在当前目录
- 文件名用服务的 npm 包名或 GitHub repo 名（小写，连字符）

## 注意事项

- 配置章节：若参数较少（<5个），不必强行分类，用单一表格即可
- 工具章节：严格按官方 README 的分类，不要自行归类
- 语言：全部中文，技术术语保留英文原文
- 若 README 信息不足，补充抓取 npm 页面或官方文档
