---
name: spool
description: Spool 会话分享与召回。通过 spool CLI 把当前/指定 AI 会话发布到 Spool hub 并获得持久 URL，或在任意 agent 内检索本地全部 Claude Code、Codex、Gemini CLI、OpenCode、Pi 历史会话。触发：「share to spool」「发布/分享这个会话」「withdraw/撤回分享」「我们之前讨论过这个」「find that session where…」「看看 codex 之前做了什么」，或用户粘贴 spool 会话链接。
allowed-tools: Bash
version: 1.0.0
---

Spool 是 agent 会话的发布平台。**Share** 将选定的记录显式发送到 Hub 并返回持久 URL：Claude Code 和 Codex CLI 的 Share 默认 Public，会出现在 Explore 和搜索中；Gemini CLI、OpenCode、Pi 保持 Link-only，直到 Discovery 支持它们。Claude Code / Codex 的 Share 还可以在另一台机器上 resume。Share 可附带 Markdown Summary：交互式 CLI 能用检测到的 Claude Code / Codex 自动生成，agent shell 应自己写好 Summary 并用 `--summary` 传入。本地准备与分享覆盖全部五个 provider，因此**任何有 shell 的 agent 都能召回其他 agent 的会话**。

## Routing

根据 `$ARGS` 和对话上下文判断：

- **share/publish** 当前（或指定）会话 → Share 流程
- **withdraw/unpublish** 已分享的会话 → `spool withdraw <sid-or-url>`
- 用户想继续一个可 resume 的 **Claude/Codex spool 会话 URL 或 sid** → `spool resume <sid-or-url>`（物化到本地并 fork 出 provider 的原生会话）
- 其他（一个主题、一个问题、"那个会话里…"）→ Recall 流程

## Preflight

所有 Spool 操作都用已安装的 `spool …` 命令。先运行 `command -v spool`。若不存在，安装一次 CLI，然后用 `spool --version` 验证：

```bash
curl -fsSL https://spool.new/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"
spool --version
```

不要退回 npx：临时调用不会让 `spool` 命令在后续的 login、Share 或 Resume 步骤可用。对分享当前项目的人，裸 `spool` 是日常流程：刷新索引、按需登录、为最新 Session 发起 Share。本 skill 使用显式命令，因为非交互 Share 需要传入准备好的 Summary。

## Share 流程

**claude**、**codex**、**gemini**、**opencode**、**pi** 会话均可分享。分享会把 Claude/Codex 原生记录或其他来源的 provider 中立索引会话发送到 Hub。CLI 会在上传前说明可见性，并打印持久 URL。

1. 运行裸 `spool`（或依赖运行中的 `spool daemon`），确保会话及其最新轮次已索引。
2. 选定目标：
   - 在 Claude Code 内，使用 `$CLAUDE_CODE_SESSION_ID`。
   - 在其他 agent（或该变量未设置）中，省略 session 参数以选择 cwd 与当前目录完全一致的最新索引会话。
   - 其他会话则传 `spool sessions list` 中的 UUID 或唯一 UUID 前缀。`<uuid>@<n>` 只分享前 _n_ 条记录。
3. 从会话的被分享部分撰写一份可直接分享的 Markdown Summary。它读起来应像这个会话的简洁、精炼的 GitHub README——不是逐轮聊天记录。

   语言从会话的自然语言对话判断，用户消息权重高于助手回复。判断语言时忽略代码、日志、命令、路径、标识符、元数据和粘贴材料。混合语言会话用用户讨论的主导语言；不清楚时用第一个实质性用户请求。所有行文和标题用该语言，技术名词保留原文。

   使用如下 README 式结构，每个标题本地化：
   - `# <具体标题>` 来自真实目标，后接 1–2 句概述。
   - `## Goal` — 原始请求、约束和有意义的范围变化。
   - `## What happened` — 按时间顺序的重要阶段，组织成简洁的段落或列表；包含关键的转向、失败、实现细节和验证。
   - `## Key decisions and findings` 仅当实质性的决策或发现影响了工作。
   - `## Validation` 仅当会话包含具体的检查、测试、构建或测量。
   - `## Outcome` — 说明目标已达成、部分达成、变更还是未解决，并解释原因。
   - `## Next steps` 仅当会话支持具体的剩余工作。

   没有实质内容时省略可选章节。使用直接、中性的语言，保留有用的技术细节，区分已完成的工作与提议和未解决事项，不暴露秘密，绝不编造结果。

4. 直接传入 Summary。Agent tool shell 是非交互的，不要依赖 CLI 上传后的 Agent 提示：

```bash
summary="$(cat <<'SPOOL_SUMMARY'
<share-ready Markdown Summary>
SPOOL_SUMMARY
)"

# 在 Claude Code 内：
spool share "$CLAUDE_CODE_SESSION_ID" --summary "$summary" --visibility-confirmed < /dev/null
```

在 Claude Code 之外则省略目标：`spool share --summary "$summary" --visibility-confirmed < /dev/null`。对选定的会话，把 UUID 放在 `--summary` 前。仅当用户想附加 `.spool` 文档时才加 `--spool-file <path>`。`--visibility-confirmed` 确认已知晓声明的 Public/Link-only 结果，但不会绕过敏感数据检查。

`< /dev/null` 是刻意的：若敏感信息门控需要确认，非交互调用必须中止而不是挂起。在用户明确接受报告的风险之前，不要加 `--yes`。

5. 处理结果：
   - **`Session published`** — Claude/Codex 会话及提供的 Summary 为 Public，可出现在 Explore 和搜索中；把 URL 给用户。协作者可运行 `spool resume <sid-or-url>` 在本地 fork。
   - **`Session shared as Link-only`** — Gemini/OpenCode/Pi 会话及提供的 Summary 对任何有 URL 的人可见，但不出现在 Explore 和搜索中。
   - **`Not logged in`** — 让用户运行 `spool login`（浏览器授权），然后重试。
   - **Secret findings / `Cannot confirm ... without a TTY`** — 展示发现摘要并询问。仅在用户明确同意后，才用 `--yes` 重跑同一命令。
   - **`<source> sessions can be shared and read, but native Resume is not supported yet`** — 解释分享可读，但原生 Resume 目前需要 Claude 或 Codex。
   - **`The session is already shared at <url>. Its previous Summary is unchanged.`** — 保留并报告现有 URL，说明只有 Summary 生成/上传失败。

## Recall 流程

目标是**带引用的召回**：回复回答问题，并指明每条结论来自哪个会话。

### 1. 搜索

```bash
spool sessions search "<query>" --json -n 5
```

- `-s claude|codex|gemini|opencode|pi` 按 agent 过滤，`--since 7d` 按时间过滤。
- 用户点名项目时改为限定范围：`spool sessions list -p <path>` 列出该项目路径的会话。
- 零命中 → 先运行一次裸 `spool`（最新会话可能还未索引），再用更宽泛的词重试。

持有至少一个相关 UUID 即完成——或者已同步、重试后可以报告没有匹配。

### 2. 聚焦

选能回答问题的最省的视图；完整转录最贵，很少是正确的第一步：

| 关于会话的问题            | 命令                                                                    |
| ------------------------- | ----------------------------------------------------------------------- |
| 发生了什么，一步步        | `spool sessions show <uuid> --log` — 每条记录一行                        |
| 改了什么代码              | `spool sessions show <uuid> --diff` — 整个会话的净 diff                  |
| 某一条具体记录            | `spool sessions show <uuid>@r<n>` — 美化打印的记录 JSON                  |
| 完整对话                  | `spool sessions show <uuid>`                                             |

本地 Gemini、OpenCode、Pi 会话用完整转录：记录级 `--log`、`--diff`、`@r<n>` 视图目前需要 Claude 或 Codex 原始记录。本地 UUID 前缀在唯一时可用。

### 3. 使用

把找到的内容作为普通上下文融入回复，按结论逐条注明来源 — `[codex · 7/15 · parallel-world]`。当用户想**继续**本地会话而非阅读时，使用人类可读搜索输出中显示的原生命令：`claude -r <uuid>`、`codex resume <uuid>` 或 `pi --session <uuid>`。JSON 搜索输出不含该命令，且 CLI 目前不为 Gemini 或 OpenCode 打印 resume 提示。

## 命令参考

| 命令                                                              | 作用                                                                                                                                                                    |
| ----------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `spool`                                                           | 刷新当前项目、按需登录，并为其最新 Session 发起 Share                                                                                                                    |
| `spool subscribe [dir] [--team <t>\|--link-only\|--public]`       | 一次性可见性决定；目录（及其 worktree）之后每次运行自动发布                                                                                                              |
| `spool daemon start\|stop\|status\|logs\|run`                     | 注册到 launchd/systemd 的常驻 watcher + 自动发布器                                                                                                                       |
| `spool sessions search <query> [-s <source>] [--since 7d]`        | 全文搜索；加 `--json` 得到机器可读结果                                                                                                                                   |
| `spool sessions list [-s <src>] [-p <path>] [-n <count>] [--all]` | 默认当前项目的 Session；`--all` 覆盖每个项目。过滤器作用于近期窗口，过滤时适当调大 `-n`                                                                                   |
| `spool sessions show <uuid\|sid\|url>`                            | 本地转录 / 分享的 Summary；`--log` 时间线、`--diff` 净变更、`@r<n>` 记录、`--json` 结构化数据                                                                             |
| `spool doctor [checkId] [--fix]`                                  | 诊断，含索引统计和 daemon 心跳；`--fix --force` 还允许破坏性修复                                                                                                          |
| `spool login [--token <t>]` / `spool logout`                      | Hub 浏览器设备授权（自动化用 token）/ 撤销并清除凭据                                                                                                                      |
| `spool share [<uuid>[@<n>]] [--summary <markdown>]`               | Claude/Codex 默认公开发布；其他 provider 分享为 Link-only。还支持 `--visibility-confirmed`、`--no-agent-summary`、`--yes`、`--spool-file`                                 |
| `spool visibility <sid\|url> <public\|link-only\|team>`           | 具名、需确认的可见性变更；Team → Public 保留 Team 归属                                                                                                                    |
| `spool withdraw <sid\|url>`                                       | 对分享做 tombstone，URL 不再解析                                                                                                                                          |
| `spool resume <sid\|url>[@<n>] [--workspace <dir>]`               | 物化并原生 fork Claude/Codex 分享；`--no-exec` 只打印命令不启动                                                                                                            |
