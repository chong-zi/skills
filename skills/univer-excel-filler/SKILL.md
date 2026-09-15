---
name: univer-excel-filler
description: Fill Univer format Excel documents (Obsidian plugin format). Use when working with .univer.md files that contain spreadsheet data in JSON format. CRITICAL - Always use \r (carriage return) for line breaks within cell values, never \n (line feed), as \n will corrupt the file.
---

# Univer Excel Filler

Fill Univer format Excel documents safely without corrupting the JSON structure.

## Critical Rule: Use \r for Line Breaks

**The most common error**: Using `\n` instead of `\r` for line breaks in cell values will corrupt the file.

```python
# ❌ WRONG - Will corrupt the file
cell_value = "第一行\n第二行"

# ✅ CORRECT
cell_value = "第一行\r第二行"
```

## Quick Start

### Method 1: Use the Helper Script

```bash
python scripts/fill_univer.py <path-to-univer-file>
```

The script provides `fill_cell()` function:

```python
from scripts.fill_univer import parse_univer_file, fill_cell, save_univer_file

# Parse file
yaml_content, json_data, _ = parse_univer_file("file.univer.md")

# Fill cells (remember: use \r for line breaks)
fill_cell(json_data, row=1, col=12, value="已完成\r详细说明", style_id="t1RAYf")

# Save
save_univer_file("file.univer.md", yaml_content, json_data)
```

### Method 2: Direct JSON Manipulation

When editing JSON directly:

1. Read the file and parse the JSON from the ```sheet block
2. Navigate to `sheets[sheet_id].cellData[row_index][col_index]`
3. Set cell value with `\r` for line breaks
4. Write back maintaining the exact file structure

## Common Patterns

### Fill a single cell
```python
json_data['sheets'][sheet_id]['cellData']["1"]["12"] = {
    "s": "t1RAYf",  # style ID
    "v": "内容\r多行内容",  # value with \r
    "t": 1  # type: 1=text, 2=number
}
```

### Fill percentage cell
```python
json_data['sheets'][sheet_id]['cellData']["1"]["13"] = {
    "s": "HR7fez",  # percentage style
    "v": 0.8,  # 80%
    "t": 2
}
```

## Troubleshooting

**File won't open after editing**: Check if you used `\n` instead of `\r` in cell values. This is the #1 cause of corruption.

**Cell not showing**: Verify row/col indices are strings ("0", "1", not 0, 1) and the sheet_id matches `sheetOrder[0]`.

## Resources

This skill includes example resource directories that demonstrate how to organize different types of bundled resources:

### scripts/
Executable code (Python/Bash/etc.) that can be run directly to perform specific operations.

**Examples from other skills:**
- PDF skill: `fill_fillable_fields.py`, `extract_form_field_info.py` - utilities for PDF manipulation
- DOCX skill: `document.py`, `utilities.py` - Python modules for document processing

**Appropriate for:** Python scripts, shell scripts, or any executable code that performs automation, data processing, or specific operations.

**Note:** Scripts may be executed without loading into context, but can still be read by Claude for patching or environment adjustments.

### references/
Documentation and reference material intended to be loaded into context to inform Claude's process and thinking.

**Examples from other skills:**
- Product management: `communication.md`, `context_building.md` - detailed workflow guides
- BigQuery: API reference documentation and query examples
- Finance: Schema documentation, company policies

**Appropriate for:** In-depth documentation, API references, database schemas, comprehensive guides, or any detailed information that Claude should reference while working.

### assets/
Files not intended to be loaded into context, but rather used within the output Claude produces.

**Examples from other skills:**
- Brand styling: PowerPoint template files (.pptx), logo files
- Frontend builder: HTML/React boilerplate project directories
- Typography: Font files (.ttf, .woff2)

**Appropriate for:** Templates, boilerplate code, document templates, images, icons, fonts, or any files meant to be copied or used in the final output.

---

**Any unneeded directories can be deleted.** Not every skill requires all three types of resources.
