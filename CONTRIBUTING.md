# 贡献与维护规范

## 新 skill 创建流程

1. 复制 `template/` 到 `skills/<skill-name>/`（skill 名用 kebab-case，小写连字符）
2. 填写 `SKILL.md` 的 frontmatter，至少需要 `name` 和 `description` 两个字段
3. 按需添加 `references/`（参考资料）、`scripts/`（脚本）、`assets/`（资源）
4. 提交前本地自查：`name` 是否小写连字符、`description` 是否描述用途和触发时机

## SKILL.md frontmatter 规范

```yaml
---
name: my-skill-name            # 必填，小写连字符
description: 一句话说明用途和触发时机   # 必填
# 以下为可选字段
allowed-tools: Bash, Read, Write
disable-model-invocation: false
version: 1.0.0
---
```

## 目录结构约定

```text
skills/<skill-name>/
├── SKILL.md           # 必填，核心指令
├── references/        # 可选，参考资料
├── scripts/           # 可选，可执行脚本
└── assets/            # 可选，图片等资源
```

## 脱敏要求

- **禁止**提交任何个人绝对路径（如 `/Users/xxx/...`），参数改用环境变量或首次运行询问
- **禁止**提交 API key、token、密码等凭据，一律用环境变量占位
- **禁止**提交公司内部信息（内网 IP、主机名、业务数据）；相关 skill 应放入 private 仓库 `skills-private`

## CI 校验

提交后 GitHub Action `check-skills.yml` 会校验每个 `skills/*/SKILL.md` 是否有合法 frontmatter（含 `name` 和 `description`）。

## 目录分类

目前 skill 规模较小，采用平铺结构（`skills/<name>/`）。未来若超过 ~20 个，可引入 `skills/<category>/<name>/` 分类（skills.sh 支持最多三层嵌套）。
