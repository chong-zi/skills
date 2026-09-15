#!/usr/bin/env bash
# 知识库脚手架脚本
# 用法：scaffold.sh <目标目录> <主题名>

set -e

TARGET_DIR="$1"
THEME="$2"

if [ -z "$TARGET_DIR" ] || [ -z "$THEME" ]; then
  echo "用法：scaffold.sh <目标目录> <主题名>"
  exit 1
fi

TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
TPL_DIR="$SKILL_DIR/templates"

# 创建目录结构
mkdir -p "$TARGET_DIR/.knowledge/projects"
mkdir -p "$TARGET_DIR/skills/kb"
mkdir -p "$TARGET_DIR/.claude"

# 替换模板占位符的函数
render() {
  sed -e "s|{{TARGET_DIR}}|$TARGET_DIR|g" \
      -e "s|{{THEME}}|$THEME|g" "$1"
}

# 复制并渲染模板
render "$TPL_DIR/CLAUDE.md.tpl"        > "$TARGET_DIR/CLAUDE.md"
render "$TPL_DIR/SKILL.md.tpl"         > "$TARGET_DIR/skills/kb/SKILL.md"
render "$TPL_DIR/kb-update.sh.tpl"     > "$TARGET_DIR/skills/kb/kb-update.sh"
chmod +x "$TARGET_DIR/skills/kb/kb-update.sh"

# 初始化 index.md
if [ ! -f "$TARGET_DIR/.knowledge/index.md" ]; then
  printf "# %s 索引\n\n| 名称 | 摘要 | 类型 | 详情 |\n|------|------|------|------|\n" "$THEME" \
    > "$TARGET_DIR/.knowledge/index.md"
fi

# 合并或创建 settings.json
SETTINGS="$TARGET_DIR/.claude/settings.json"
HOOK_CMD="$TARGET_DIR/skills/kb/kb-update.sh"

if [ -f "$SETTINGS" ]; then
  # 已存在：检查是否已有该 hook，没有则提示用户手动合并
  if grep -q "kb-update.sh" "$SETTINGS" 2>/dev/null; then
    echo "[scaffold] settings.json 已包含 kb hook，跳过"
  else
    echo "[scaffold] 警告：settings.json 已存在，请手动添加以下 hook："
    echo "  UserPromptSubmit → $HOOK_CMD"
  fi
else
  render "$TPL_DIR/settings.json.tpl" > "$SETTINGS"
fi

echo "[scaffold] 完成：$TARGET_DIR 已初始化为「$THEME」知识库"
echo "[scaffold] 结构："
echo "  .knowledge/index.md"
echo "  skills/kb/SKILL.md"
echo "  skills/kb/kb-update.sh"
echo "  .claude/settings.json"
echo "  CLAUDE.md"
