---
name: server-profile
description: 服务器信息采集与档案整理。无法直连时用 collect.sh 采集，或提供 ssh 别名/密码直接采集；按模板整理成标准化服务器档案（基底+GPU 专题）。触发：「整理服务器档案」「采集服务器信息」「server-profile」。
version: 1.0.0
category: ops
type: skill
tags: [服务器, 采集, 档案, GPU, 运维]
platforms: [macos, linux]
---

# server-profile

采集服务器信息并整理成标准化档案（含基底 + GPU 专题两块结构）。

> ⚠️ **安全提示**：档案含敏感信息（IP / 用户 / sudoers / 最近登录 / 序列号），且 vault 由 obsidian-git 自动提交。若采集的是客户机或敏感机，请输出到 **vault 外目录**，或手动脱敏（密码 / sudoers / last）。后续会支持 `--redact` 自动打码（v2）。

## 资产位置

- 采集脚本：`src/server-profile/collect.sh`（零依赖 bash，全 sudo）
- 采集清单：`src/server-profile/collect-spec.md`（标签 = 章节映射 key）
- 模板：`src/server-profile/templates/{base.md, gpu.md}`
- 参考：任意一份已整理的服务器档案（输出格式以模板为准）

## 输入路由（判断用户给的是什么）

| 用户输入 | 动作 |
|---|---|
| **ssh 别名 + sudo NOPASSWD** | `ssh <别名> 'sudo bash -s' < collect.sh`（stdin 模式，最简洁） |
| **ssh 别名 + sudo 需密码**（最常见） | `scp collect.sh <别名>:/tmp/collect.sh && ssh <别名> 'echo <密码> \| sudo -S bash /tmp/collect.sh'`（脚本模式，避开 stdin+sudo 冲突；密码用完即弃） |
| **user@ip + 密码** | `SSHPASS=密码 sshpass -e ssh -t user@ip 'echo SSHPASS \| sudo -S bash -s' < collect.sh`；密码用完即弃，不落盘 |
| **脚本输出文本**（粘贴/文件路径） | 直接当 collect.sh 输出解析 |
| **已有档案 + "更新"** | 更新模式（见下） |

## 整理流程

1. **解析**：按 `=== [标签] ===` 切分文本段，标签映射到模板章节（见 collect-spec.md）
2. **GPU 检测**：有 `=== [GPU详情-卡表] ===` 段 → 拼接 gpu.md 到 base.md 的 `<!-- GPU INSERT POINT -->`；否则跳过
3. **LLM 生成**（参考下方 few-shot 风格）：
   - 顶部信息块（**密码字段留空**，不自动填）
   - 一句话定位 + 定位依据（按显存/CPU/互连推断用途）
   - 各章结论句（如「机器整体空闲，可立即使用」）
   - GPU 互连拓扑结论 + 带宽表（若有 GPU）
4. **输出**：写到 `{输出目录}/{别名}-{用途}.md`（输出目录由用户指定，未提供则询问是否用当前目录）；索引页默认追加到「研发服务器清单.md」——用户可指定别的索引页路径，或明确说「不要追加索引」

## 更新模式

读已有档案：**保留** 静态信息（标识/系统/硬件/网络拓扑/用户/GPU 硬件）+ 用户手写注释；**服务持久化（Docker 挂载）属静态**，更新时保留；**刷新** 动态用量（含 GPU 利用率/温度/功耗）/安装的服务运行状态/监听端口/防火墙。合并写回，标注「动态段刷新于 YYYY-MM-DD」。

**实现方式（方案 A）**：照常跑 collect.sh **全量采集**，技能只取【动态用量 / 安装的服务 / 监听端口 / 安全-防火墙】段去合并，静态段（含 `服务-Docker挂载`）原样保留。不修改 collect.sh，不另设 `--section` 参数。

## nccl-tests 子能力（按需，用户说"测带宽"时触发）

1. 单独流程（不走 collect.sh）：`git clone https://ghfast.top/https://github.com/NVIDIA/nccl-tests.git`
2. 容器内编译：`docker run --rm -v /tmp/nccl-tests:/work ... make CUDA_HOME=... NCCL_HOME=...`
3. 跑：`docker run --rm --gpus all --shm-size=2g --ipc=host ... ./build/all_reduce_perf -g 4 -e 1G -f 2`
4. 解读 busbw，回填档案「实测带宽」表

## few-shot 风格示例（GPU 档案）

**定位句**：某公司研发用 GPU 物理机，4× RTX 3090（96 GB 显存），适合中小模型训练/推理。

**定位依据**：
- 显存：总计 96 GB，推理可承载 30–40B 级别，训练规模缩小
- 互连：两两 NVLink 直连（~56 GB/s），适合 DDP
- 兜底：更大模型走 H100 算力机

**静态结论**：NUMA 节点与 GPU 分组对齐（node0↔GPU0/1），多卡训练绑核即拿满 NVLink。

**动态结论**：当前机器整体空闲（负载 0.00、4 卡 0%），可立即投入使用。

**GPU 互连结论**：两两 NVLink 直连，跨对走 PCIe（SYS）。

**容器挂载整理示例**（new-api，bind mount + SQLite）：

> 采集输出：
> ```text
> [new-api]
>   /home/user/www/new-api/data -> /data (bind)
> ```
>
> 整理进档案「持久化」段：
> - **new-api**：`/home/user/www/new-api/data → /data`（bind mount，SQLite 数据库 `one-api.db` 在此目录，迁移需整目录拷贝）

## 标签 → 章节映射（严格，源自 collect-spec.md）

- `标识-*` → 标识章
- `安全-*` → 安全章对应二级标题（防火墙/SELinux/sudoers/SSH配置/最近登录）
- `GPU详情-*` / `GPU拓扑-*` → GPU 专题（条件）
- 其余一一对应（见 collect-spec.md 表）

## 错误处理

- 命令 FAILED 段（标签下出现 `FAILED:`）→ 档案对应字段标「采集失败」或按实际输出描述
- ssh 连接失败 → 建议「改用脚本模式：把 collect.sh 拷到目标机 sudo bash 跑，输出粘回」
- sudo 非交互失败 → 建议「目标机配 NOPASSWD，或走脚本模式」
