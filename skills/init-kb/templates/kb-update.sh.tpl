#!/usr/bin/env bash
# 会话首次检测 + 增量更新知识库

KB_DIR="{{TARGET_DIR}}/.knowledge"
INDEX="$KB_DIR/index.md"
TARGET_DIR="{{TARGET_DIR}}"
PPID_MARK="/tmp/kb-session-${PPID}"

# 非首次调用直接退出
[ -f "$PPID_MARK" ] && exit 0
touch "$PPID_MARK"

mkdir -p "$KB_DIR/projects"

# 初始化 index.md（如不存在）
if [ ! -f "$INDEX" ]; then
  printf '# {{THEME}} 索引\n\n| 名称 | 摘要 | 类型 | 详情 |\n|------|------|------|------|\n' > "$INDEX"
fi

# 扫描一级子目录（排除隐藏目录和基础设施目录）
DIRS=$(find "$TARGET_DIR" -maxdepth 1 -mindepth 1 -type d \
  ! -name '.*' ! -name 'docs' ! -name 'skills' \
  -exec basename {} \; | sort)

# 找出尚未收录的新条目
NEW_ITEMS=()
while IFS= read -r dir; do
  [ -z "$dir" ] && continue
  if ! grep -q "| $dir |" "$INDEX" 2>/dev/null; then
    NEW_ITEMS+=("$dir")
  fi
done <<< "$DIRS"

# 有新条目时输出提示
if [ ${#NEW_ITEMS[@]} -gt 0 ]; then
  echo "[kb] 发现新条目，请为以下内容生成知识条目并更新 .knowledge/index.md："
  for item in "${NEW_ITEMS[@]}"; do
    echo "  - $item"
  done
  echo "[kb] 格式：.knowledge/projects/<name>.md（5W1H + 示例 + 关联）"
fi
