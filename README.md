# skills

个人维护的 Claude/Agent Skills 集合，可被 Skills Manager、skills.sh、Claude Code 插件市场等多通道安装使用。

## 安装方式

### 1. Skills Manager（推荐，支持多 agent 同步）

```bash
skills install chong-zi/skills@<skill-name>
skills deploy <skill-name> --agent claude_code
```

### 2. skills.sh CLI（Claude Code / Codex 通用）

```bash
npx skills add chong-zi/skills
```

### 3. Claude Code 插件市场

```bash
/plugin marketplace add chong-zi/skills
/plugin install <plugin>@chong-zi-skills
```

## Skill 清单

| Skill | 用途 |
|-------|------|
| `concept-analyst` | 对新事物/产品/系统做 DDD 概念分析，输出结构化概念文档 |
| `init-kb` | 将目录初始化为结构化知识库，供个人查阅和 Agent 协作 |
| `mac-app-scan` | 扫描 /Applications，对比本地应用 wiki，自动处理新增/删除 |
| `mcp-note` | 抓取 MCP 服务信息，生成 5W1H 结构化笔记 |
| `mistral-pdf-to-markdown` | 用 Mistral OCR 将 PDF 转为 Markdown（含图片提取） |
| `ppt-presenter-script` | 生成功能讲解类 PPT 演示串词 |
| `product-research` | 多维度软件产品调研分析 |
| `proposal-iteration` | 假设-验证循环式目标达成 |
| `server-profile` | 采集服务器信息，整理标准化档案（基底 + GPU 专题） |
| `skill-wiki` | 扫描已安装 skill，生成/更新 Obsidian wiki |
| `univer-excel-filler` | 填充 Univer 格式 Excel 文档（.univer.md） |

## 目录结构

```text
skills/
├── .claude-plugin/marketplace.json   # Claude Code 插件市场清单
├── skills/                           # 各 skill（平铺，每个含 SKILL.md）
├── template/                         # 新 skill 模板
├── .github/workflows/check-skills.yml # CI 校验 frontmatter
└── CONTRIBUTING.md                   # 维护规范
```

## 许可

MIT
