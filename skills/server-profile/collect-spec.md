# 采集清单（collect-spec）

> `collect.sh` 与档案模板的**单一真理源**。标签名（`=== [标签] ===`）即字段映射 key，采集脚本、规范和模板必须一致。

## 基底与三层档案采集项

| 标签 | 命令 / 函数 | 目标层 | root |
|---|---|---|:---:|
| `采集-时间` | `date --iso-8601=seconds` | 动态 `current.md` | |
| `标识-主机名` | `hostname` | 静态 `profile.md` | |
| `标识-主机名静态` | `cat /etc/hostname` | 静态 `profile.md` | |
| `标识-型号` | `cat /sys/class/dmi/id/product_name` | 静态 `profile.md` | |
| `标识-虚拟化` | `systemd-detect-virt` | 静态 `profile.md` | |
| `标识-序列号` | `dmidecode -s system-serial-number; dmidecode -t bios` | 静态 `profile.md` | ✓ |
| `系统-发行版` | `. /etc/os-release && echo "$PRETTY_NAME"` | 静态 `profile.md` | |
| `系统-内核架构` | `uname -r; uname -m` | 静态 `profile.md` | |
| `系统-时区` | `timedatectl show -p Timezone --value` | 静态 `profile.md` | |
| `计算CPU-lscpu` | `LC_ALL=C lscpu` | 静态 `profile.md` | |
| `计算CPU-核数` | `nproc` | 静态 `profile.md` | |
| `内存-free` | `free -h` | 静态容量进 `profile.md`；已用/可用进 `current.md` | |
| `内存-内存条` | `dmidecode -t memory`（过滤有效槽位） | 静态 `profile.md` | ✓ |
| `存储-块设备` | `lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS,MODEL` | 静态 `profile.md` | |
| `存储-分区使用` | `df -hT -x tmpfs -x devtmpfs` | 布局进 `profile.md`；使用率进 `current.md` | |
| `网络-接口` | `ip -brief addr` | 静态 `profile.md`（容器 veth 波动除外） | |
| `网络-路由` | `ip route \| grep default` | 静态 `profile.md` | |
| `网络-DNS` | `cat /etc/resolv.conf` | 静态 `profile.md` | |
| `用户-可登录` | `getent passwd`（过滤可登录 shell） | 静态 `profile.md` | |
| `用户-关键组` | `getent group sudo docker wheel` | 静态 `profile.md` | |
| `安全-防火墙iptables` | `iptables -S` | 策略进 `profile.md`；异常变化进 `changelog/` | ✓ |
| `安全-防火墙nft` | `nft list ruleset` | 策略进 `profile.md` | ✓ |
| `安全-防火墙ufw` | `ufw status; firewall-cmd --list-all` | 静态 `profile.md` | |
| `安全-SELinux` | `getenforce; sestatus; aa-status` | 静态 `profile.md` | |
| `安全-sudoers` | 列出 `/etc/sudoers*` 非注释规则（审查后脱敏入档） | 静态 `profile.md` | ✓ |
| `安全-SSH配置` | `sshd -T`（port / permitrootlogin / passwordauthentication / gatewayports） | 静态 `profile.md` | ✓ |
| `安全-最近登录` | `last -n 10` | 动态参考（脱敏，不原样公开） | |
| `动态-负载` | `uptime; who; uptime -s` | 动态 `current.md` | |
| `动态-进程TOP` | `ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu \| head -10` | 动态 `current.md` | |
| `动态-进程数` | `ps -e --no-headers \| wc -l` | 动态 `current.md` | |
| `服务-运行中` | `systemctl list-units --type=service --state=running --no-pager` | 稳定组件进 `profile.md`/`services.md`；运行态进 `current.md` | |
| `服务-Docker概览` | `docker version; docker compose version; docker info; docker ps -a` | 动态 `current.md` | |
| `服务-DockerCompose项目` | `docker compose ls` | 静态 `services.md` + 动态 `current.md` | |
| `服务-Docker容器详情` | `collect_docker_containers`（镜像、image_id、启动时间、restart、entrypoint/cmd、端口、网络、环境变量名） | 部署关系进 `services.md`；状态/image_id/容器 IP 进 `current.md` | |
| `服务-Docker挂载` | `collect_docker_mounts`（Source → Destination、Type、RW） | 静态 `services.md` | |
| `服务-Docker镜像` | `docker image ls --digests` | 镜像源与标签进 `services.md`；digest/ID/大小进 `current.md` | |
| `服务-Nginx配置` | `collect_nginx`（`nginx -t`、`conf.d/` 文件列表、`listen/server_name/proxy_pass/ssl_certificate` 摘要） | 路由关系进 `services.md`；测试状态与告警进 `current.md` | ✓ |
| `服务-TLS证书` | `collect_tls_certs`（证书 subject/issuer/dates/SAN，不读私钥内容） | 静态 `profile.md`/`services.md`；到期风险进 `current.md` | ✓ |
| `服务-cron` | `crontab -l; ls /etc/cron.* /etc/cron.d/` | 静态 `services.md` | |
| `端口-监听` | `ss -tlnp` | 固定入口进 `services.md`；实况表进 `current.md` | ✓ |

## GPU 模块（`has nvidia-smi` 才启用）

| 标签 | 命令 | 目标层 | root |
|---|---|---|:---:|
| `GPU详情-头部` | `nvidia-smi \| head -10` | 驱动/CUDA 进 `profile.md`；实时占用进 `current.md` | |
| `GPU详情-卡表` | `nvidia-smi --query-gpu=index,name,memory.total,memory.used,driver_version,temperature.gpu,power.draw,utilization.gpu --format=csv` | 型号/总显存进 `profile.md`；显存占用/温度/功耗/利用率进 `current.md` | |
| `GPU详情-全量附录` | `nvidia-smi -q > /tmp/nvidia-smi-q.txt` | 临时附录文件，不进主文本段 | |
| `GPU软件栈-nvcc` | `nvcc --version \| tail -1` | 静态 `profile.md` | |
| `GPU软件栈-torch` | `probe_torch` | 静态 `profile.md` | |
| `GPU-PCIe` | `nvidia-smi --query-gpu=pci.bus_id,pcie.link.gen.current,pcie.link.gen.max,pcie.link.width.current,pcie.link.width.max --format=csv` | 静态 `profile.md` | |
| `GPU-PCIe验证` | `lspci -vvv -d ::0300 \| grep -E 'LnkCap\|LnkSta'` | 静态 `profile.md` | ✓ |
| `GPU拓扑-topo` | `nvidia-smi topo -m` | 静态 `profile.md` | |
| `GPU拓扑-NVLink` | `for i in $(seq 0 $((gpu_count-1))); do nvidia-smi nvlink -s -i $i; done` | 静态 `profile.md` | |

## 脱敏边界

- `collect_docker_containers` 只输出环境变量**字段名**（`KEY=<redacted>`），不输出环境变量值。
- `collect_tls_certs` 只用 `openssl x509 -noout` 读取公钥证书元数据，不输出任何 `.key` / `pem` 私钥正文。
- `collect_nginx` 只输出文件清单、语法检查结果和路由关键指令，不抓取业务凭据文件。
