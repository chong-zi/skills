# Univer格式参考

## 文件结构

Univer格式文件是Obsidian插件使用的Excel格式，以Markdown文件存储，包含：

```markdown
---
excel-pro-plugin: parsed
---
```sheet
{JSON数据}
```text

```
multiSheet
{标签页配置}
```text
```

## JSON数据结构

```
json
{
  "id": "唯一ID",
  "sheetOrder": ["sheet_id"],
  "name": "文件名",
  "styles": {
    "style_id": {样式定义}
  },
  "sheets": {
    "sheet_id": {
      "cellData": {
        "行索引": {
          "列索引": {
            "s": "样式ID",
            "v": "单元格值",
            "t": 1
          }
        }
      }
    }
  }
}
```text

## 关键规则

### 1. 换行符必须使用 `\r`

**错误示例**（会导致文件损坏）：
```
json
{
  "v": "第一行\n第二行"
}
```text

**正确示例**：
```
json
{
  "v": "第一行\r第二行"
}
```text

### 2. 单元格数据结构

```
json
{
  "s": "t1RAYf",           // 样式ID（可选）
  "v": "显示值",            // 单元格值
  "t": 1,                  // 类型：1=文本, 2=数字
  "p": {富文本对象}         // 富文本（可选）
}
```text

### 3. 行列索引

- 行索引和列索引都从0开始
- 在JSON中以字符串形式存储：`"0"`, `"1"`, `"2"`...

### 4. 样式引用

常见样式ID：
- `t1RAYf`: 普通文本样式
- `HR7fez`: 百分比格式
- `xvigYD`: 表头样式
- `8InCCO`: 高亮样式

## 示例

填充第1行第12列（3月完成情况）：

```
python
cell_data["1"]["12"] = {
    "s": "t1RAYf",
    "v": "已完成Demo上线\r完成资管团队演示",
    "t": 1
}
```
