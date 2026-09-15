### GPU 专题

> **结论：{{LLM 按拓扑生成的 GPU 互连结论，如"两两 NVLink 直连，跨对走 PCIe"}}**

#### GPU 详情
{{GPU详情-头部（驱动/CUDA 粗体行）+ 卡表：Index | 型号 | 显存 | Bus-Id | PCIe}}

| Index | 型号 | 显存 | Bus-Id | PCIe |
|---|---|---|---|---|
| {{0}} | {{RTX 3090}} | {{24576 MB}} | {{00000000:01:00.0}} | {{Gen4 x16}} |

> 温度 / 功耗 / 利用率属动态，见「动态用量」段。

> 每张卡 TDP；满载功耗上限。
> **PCIe**：{{GPU-PCIe + 验证结论，如"卡原生 Gen4，平台限 Gen3 x16，单向 ~15.75 GB/s"}}

#### GPU 软件栈
{{GPU软件栈-nvcc/torch}}

#### GPU 互连与拓扑
`nvidia-smi topo -m` 实测：
```text
{{GPU拓扑-topo 原始矩阵}}
```

{{LLM 生成的拓扑图 + 带宽表}}

> {{GPU 代际说明，如"RTX 3090 GA102 是 30 系唯一带 NVLink，只能两两配对"}}

**实测带宽**（nccl-tests `all_reduce_perf`，按需手动跑）：

> 占位：nccl-tests 不自动采集。需要时手动执行：
> 1. 容器内编译 nccl-tests（镜像源 clone）
> 2. `docker run --rm --gpus all --shm-size=2g --ipc=host ... ./build/all_reduce_perf -g N -e 1G`
> 3. 把 busbw 结果回填下表

| 场景 | 1 GB busbw | 传输通道 | 达理论 |
|---|---|---|---|
| {{待填}} | | | |
