#!/usr/bin/env python3
"""
安全填充Univer格式Excel文档的工具脚本
关键：使用 \r 而非 \n 作为单元格内换行符
"""
import json
import re
import sys
from pathlib import Path


def parse_univer_file(file_path):
    """解析Univer格式文件，返回YAML frontmatter和JSON数据"""
    content = Path(file_path).read_text(encoding='utf-8')

    # 提取YAML frontmatter
    yaml_match = re.match(r'^---\n(.*?)\n---\n', content, re.DOTALL)
    if not yaml_match:
        raise ValueError("未找到YAML frontmatter")

    # 提取JSON部分
    json_match = re.search(r'```sheet\n(\{.*?\})\n```', content, re.DOTALL)
    if not json_match:
        raise ValueError("未找到sheet JSON数据")

    yaml_content = yaml_match.group(1)
    json_data = json.loads(json_match.group(1))

    return yaml_content, json_data, content


def fill_cell(json_data, row, col, value, style_id=None):
    """
    填充单元格数据

    Args:
        json_data: Univer JSON数据对象
        row: 行索引（从0开始）
        col: 列索引（从0开始）
        value: 单元格值（多行文本使用 \r 分隔）
        style_id: 样式ID（可选）
    """
    sheet_id = json_data['sheetOrder'][0]
    cell_data = json_data['sheets'][sheet_id]['cellData']

    if str(row) not in cell_data:
        cell_data[str(row)] = {}

    cell_obj = {
        "v": value,
        "t": 1  # 文本类型
    }

    if style_id:
        cell_obj["s"] = style_id

    cell_data[str(row)][str(col)] = cell_obj


def save_univer_file(file_path, yaml_content, json_data):
    """保存Univer格式文件"""
    json_str = json.dumps(json_data, ensure_ascii=False, separators=(',', ':'))

    output = f"""---
{yaml_content}
---
```sheet
{json_str}
```

```multiSheet
{{"tabs":[{{"key":"sheet","type":"sheet","label":"Sheet"}}],"defaultActiveKey":"sheet"}}
```
"""

    Path(file_path).write_text(output, encoding='utf-8')


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python fill_univer.py <univer文件路径>")
        sys.exit(1)

    file_path = sys.argv[1]

    # 示例：读取并填充
    yaml_content, json_data, _ = parse_univer_file(file_path)

    # 示例填充（根据实际需求修改）
    # fill_cell(json_data, row=1, col=12, value="已完成\r详细说明", style_id="t1RAYf")

    print(f"已解析文件: {file_path}")
    print("使用 fill_cell() 函数填充数据，记住使用 \\r 作为换行符")
