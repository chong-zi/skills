---
name: server-profile
description: 服务器信息采集与三层档案维护（静态档案 + 服务子对象 + 动态快照 + 月度变更日志）。支持首次建档、定期只读采集更新、操作后归档与 GPU 专题。触发：「整理服务器档案」「采集服务器信息」「更新服务器档案」「server-profile」。
version: 2.0.0
category: ops
type: skill
tags: [服务器, 采集, 档案, 运维, Docker, GPU, changelog]
platforms: [macos, linux]
---

# server-profile

采集服务器信息，并按**三层信息模型**维护标准化服务器档案目录：

- **静态层**：`profile.md`（机器与访问控制事实）、`services.md`（服务子对象与部署配置位置）
- **动态层**：`current.md`（最近一次只读采集快照，每次整体覆盖）
- **日志层**：`changelog/YYYY-MM.md`（按服务器 / 服务子对象追加变更记录）

> ⚠️ **安全与脱敏要求**：密码、Session/Crypto Secret、OAuth `client_secret`、私钥正文、可用 Token 一律不写入档案，只记录“已配置”及服务器上的配置文件路径。采集敏感客户机时，输出到不受公开版本控制的目录。

## 资产位置

以下均为本 skill 根目录下的相对路径：

- 采集脚本：`collect.sh`（零依赖 bash，只读采集基底、Docker 容器/Compose/镜像/挂载、Nginx、TLS 证书、端口、GPU）
- 采集清单：`collect-spec.md`（`=== [标签] ===` 与目标文件映射表）
- 建模与维护规范：`references/maintenance-model.md`
- 模板：`templates/{README.md, profile.md, services.md, current.md, changelog.md, gpu.md, index.md}`
- 单文件兼容模板：`templates/base.md`（仅当用户明确要求单文件档案时使用）

## 输入路由

| 用户输入 | 动作 |
|---|---|
| **ssh 别名 + sudo 免密** | `ssh <别名> 'sudo bash -s' < collect.sh` |
| **ssh 别名 + sudo 需密码** | `scp collect.sh <别名>:/tmp/collect.sh && ssh <别名> 'echo <密码> \| sudo -S bash /tmp/collect.sh && rm -f /tmp/collect.sh'`（密码用完即弃，不落盘） |
| **user@ip + 密码** | `SSHPASS=密码 sshpass -e ssh -t user@ip 'echo "$SSHPASS" \| sudo -S bash -s' < collect.sh`（密码不落盘） |
| **collect.sh 输出文本/文件** | 直接按 `collect-spec.md` 解析 |
| **已有档案 +「更新 / 巡检 / 采集」** | 走「定期采集更新流程」 |
| **已有档案 +「刚完成了某操作」** | 走「主动操作归档流程」 |

## 输出目录结构（默认）

每台服务器一个目录，推荐命名 `{别名}-{地址}/`：

```text
{别名}-{地址}/
├── README.md            唯一入口：定位、架构图、入口表、文档导航、维护约定
├── profile.md           静态机器档案：身份、系统、CPU、内存、存储布局、网络、安全、证书
├── services.md          静态服务清单：每个服务一个子对象（部署、端口、挂载、配置位置、健康检查）
├── current.md           动态现状：本次采集快照（整体覆盖，全文只对顶部采集时间负责）
├── changelog/
│   └── YYYY-MM.md       月度变更日志：按服务器 / 服务子对象只追加记录
└── archive/             旧版单文件或历史手工文档归档（迁移旧档案时创建）
```

## 首次建档流程

1. **只读采集**：按输入路由执行 `collect.sh`，拿全量段落输出。
2. **解析分层**：对照 `collect-spec.md` 与 `references/maintenance-model.md`：
   - 机器身份、硬件规格、分区布局、网络拓扑、SSH/防火墙策略、证书元数据 → `profile.md`
   - 若有 `=== [GPU详情-卡表] ===` → 将 `templates/gpu.md` 填入 `profile.md` 的 `<!-- GPU INSERT POINT -->`（静态规格进 `profile.md`，实时温度/功耗/显存占用进 `current.md`）
   - Docker Compose 项目、容器、systemd 业务服务、Nginx 路由、持久化挂载、环境变量名清单、健康检查 → `services.md`
   - 采集时间、uptime/load、内存已用/可用、磁盘使用率、运行容器状态、镜像 ID/RepoDigest、监听端口、健康检查结果 → `current.md`
3. **初始化日志**：创建 `changelog/YYYY-MM.md`，记录首次建档基线。
4. **生成入口**：创建 `README.md`，汇总一句话定位、入口架构图、访问入口和文件导航。
5. **登记索引**（默认开启）：将 `{别名}/README.md` 登记到索引文件（解析规则见下）。

## 定期采集更新流程（解决静态漂移问题）

更新已有档案时，**禁止只刷动态而静默忽略静态变化**：

1. **读取旧状态**：先读现有 `profile.md`、`services.md`、`current.md`（若仍是旧版单文件档案，先将其移入 `archive/` 并拆分为三层目录）。
2. **执行全量只读采集**：照常运行 `collect.sh`（必要时补充只读健康检查，如本机 `/api/status`、`/.well-known/openid-configuration`）。
3. **对比差异（Diff）**：
   - **动态差异**：磁盘使用率、内存、负载、容器运行时长、镜像 ID / RepoDigest、应用版本、端口监听、健康检查状态。
   - **静态差异**：新增或下线容器/服务、Compose 路径或镜像标签变化、挂载路径变化、端口绑定变化、Nginx 路由或黑名单变化、证书变化、系统内核或硬件变化。
4. **先更新静态层**：若静态事实发生变化，先修改 `profile.md` 或 `services.md`，保证静态层永远代表最新已确认事实。
5. **整体覆盖动态层**：用本次采集结果重写 `current.md`，顶部标注唯一采集时间。
6. **追加月度日志**：在 `changelog/YYYY-MM.md` 按子对象记录 `旧值 → 新值`；若无架构或配置变化，也追加一条“已采集，未发现服务配置变化”，证明已完成巡检。

## 主动操作归档流程

当用户执行了升级、改配置、安全封禁、迁移等操作后：

1. 验证操作结果（容器状态、应用版本、配置语法、健康检查、外部链路）。
2. 若部署方式、镜像标签、挂载、端口、配置文件路径变化，同步更新 `profile.md` / `services.md`。
3. 刷新 `current.md` 对应运行态段落与采集时间。
4. 在 `changelog/YYYY-MM.md` 追加操作条目，包含：**背景/根因、执行内容、验证结果、备份与回滚方式**。

## 索引定位与配置

索引文件只存导航信息（别名、定位摘要、状态、`README.md` 路径），不放档案正文。位置解析顺序：

1. 读 `~/.skills/server-profile/config.json` 的 `index_path`；
2. 若无配置，首次登记时询问用户索引路径并写回 `config.json`；用户跳过则默认 `~/.skills/server-profile/index.md`；
3. 若索引同级目录已有服务器子目录（如 `{索引目录}/{别名}-{IP}/README.md`），优先在该目录维护三层档案。

## nccl-tests 子能力（按需，用户说「测带宽」时触发）

1. 单独流程（不走 `collect.sh`）：克隆并容器内编译 `nccl-tests`
2. 执行 `all_reduce_perf`，解读 `busbw`
3. 将静态测试结论更新到 `profile.md` 的 GPU 专题，并在 `changelog/YYYY-MM.md` 记录测试条件与结果

## 错误与边界处理

- 某采集段 `FAILED`：对应字段写“采集失败”，不得沿用旧值冒充当前值。
- 主机内无法证明的外部状态（云安全组、云备份策略、远端镜像仓库最新 digest）：明确标注“未核实”。
- `latest` 标签：在 `services.md` 注明“可漂移标签，非版本号”，在 `current.md` 记录实际镜像 ID 与应用版本。
- 序列号为占位值（如 `0123456789`）：标注“主板未写入真实 SN”。
- `last/who` 为空：标注“wtmp 为空，无历史登录记录”。
