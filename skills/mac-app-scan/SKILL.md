---
name: mac-app-scan
description: 扫描 /Applications 目录，对比 Mac 应用 wiki，自动处理新增和已删除的应用
triggers:
  - mac-app-scan
  - 扫描mac应用
  - 扫描应用变化
disable-model-invocation: false
allowed-tools: Bash, Read, Write, Edit, WebFetch
---

# mac-app-scan

## 用途

对比 `/Applications` 目录和本地的 Mac 应用 wiki 目录，处理变化：
- **新增应用**：创建 wiki 文件 + 更新 INDEX.md
- **已删除应用**：在 wiki 文件顶部标记删除 + 更新 INDEX.md

> **wiki 目录**：默认为当前目录（首次使用会提示你指定。也可用环境变量 `MAC_WIKI_DIR` 覆盖）。下文命令中的 `$WIKI` 一律替换成实际 wiki 目录路径。

## 执行步骤

### 第一步：获取当前应用列表

```bash
ls /Applications/*.app 2>/dev/null | sed 's|/Applications/||;s|\.app$||' | sort
```

### 第二步：获取已有 wiki 文件列表

```bash
ls "$WIKI"*.md | \
  xargs -I{} basename {} .md | \
  grep -v "^CLAUDE$\|^INDEX$" | sort
```

注意：`Claude（应用）` 对应 `Claude.app`，需特殊处理这个映射。

### 第三步：计算差异

- **新增** = 在 /Applications 有、wiki 没有的
- **已删除** = wiki 有、/Applications 没有的（排除已标记删除的文件）

### 第四步：处理新增应用

对每个新增应用：
1. 用 WebFetch 搜索该应用的官网、费用、功能描述（搜索 `<应用名> mac app official site`）
2. 按以下模板创建 wiki 文件：

```markdown
# <应用名>

## 是什么
<一句话描述>

## 使用场景
- <实际使用场景>

## 获取方式
<App Store / 官网下载 / Homebrew>

## 官网
<URL，不确定写"待补充">

## 官方文档
<URL，不确定写"待补充">

## 费用
<免费 / 买断 / 订阅，不确定写"待确认">

## 替代品
- <同类竞品>

## 注意事项
- <坑或限制，无则省略此节>
```

3. 在 INDEX.md 对应分类下追加条目：`- [应用名](文件名.md) — 一句话描述`

### 第五步：处理已删除应用

对每个已删除应用（wiki 存在但 /Applications 中不存在）：
1. 读取 wiki 文件，在文件最顶部插入删除标记：

```markdown
> **[已删除]** 该应用已于 <YYYY-MM-DD> 从 /Applications 中移除。

```

2. 在 INDEX.md 中找到该应用条目，在描述后追加 `~~（已删除）~~`

### 第六步：输出扫描报告

```text
## 扫描结果 <日期>

### 新增（N 个）
- AppName — 一句话描述

### 已删除（N 个）
- AppName

### 无变化
共 N 个应用，wiki 已是最新。
```
## 注意事项

- wiki 目录：由 `$WIKI` / `MAC_WIKI_DIR` 指定，首次运行会提示配置
- INDEX.md 更新后同步修改文件头的"最后更新"日期和应用总数
- `Claude.app` 对应的 wiki 文件名是 `Claude（应用）.md`（避免与 CLAUDE.md 冲突）
- 已标记 `[已删除]` 的 wiki 文件不重复标记
