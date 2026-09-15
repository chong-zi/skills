# 采集清单（collect-spec）

> `collect.sh` 与档案模板的**单一真理源**。标签名（`=== [标签] ===`）即章节映射 key，三者必须一致。

## 基底（11 分组）

| 标签 | 命令 | 类别 | root |
|---|---|---|:---:|
| `标识-主机名` | `hostname` | 静态 | |
| `标识-主机名静态` | `cat /etc/hostname` | 静态 | |
| `标识-型号` | `cat /sys/class/dmi/id/product_name` | 静态 | |
| `标识-虚拟化` | `systemd-detect-virt` | 静态 | |
| `标识-序列号` | `dmidecode -s system-serial-number; dmidecode -t bios` | 静态 | ✓ |
| `系统-发行版` | `. /etc/os-release && echo "$PRETTY_NAME"` | 静态 | |
| `系统-内核架构` | `uname -r; uname -m` | 静态 | |
| `系统-时区` | `timedatectl show -p Timezone --value` | 静态 | |
| `计算CPU-lscpu` | `LC_ALL=C lscpu` | 静态 | |
| `计算CPU-核数` | `nproc` | 静态 | |
| `内存-free` | `free -h` | 静态 | |
| `内存-内存条` | `dmidecode -t memory \| grep -E 'Size:\|Speed:\|Type:\|Locator:'` | 静态 | ✓ |
| `存储-块设备` | `lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,MODEL` | 静态 | |
| `存储-分区使用` | `df -hT -x tmpfs -x devtmpfs` | 静态 | |
| `网络-接口` | `ip -brief addr` | 静态 | |
| `网络-路由` | `ip route \| grep default` | 静态 | |
| `网络-DNS` | `cat /etc/resolv.conf` | 静态 | |
| `用户-可登录` | `getent passwd \| awk -F: '$7 ~ /(bash\|sh\|zsh)$/ {print $1":"$3":"$6}'` | 静态 | |
| `用户-关键组` | `getent group sudo docker wheel 2>/dev/null` | 静态 | |
| `安全-防火墙iptables` | `iptables -S` | 安全 | ✓ |
| `安全-防火墙nft` | `nft list ruleset 2>/dev/null` | 安全 | ✓ |
| `安全-防火墙ufw` | `ufw status 2>/dev/null; firewall-cmd --list-all 2>/dev/null` | 安全 | |
| `安全-SELinux` | `getenforce 2>/dev/null; sestatus 2>/dev/null; aa-status 2>/dev/null` | 安全 | |
| `安全-sudoers` | `grep -rv '^#\|^$' /etc/sudoers /etc/sudoers.d/ 2>/dev/null` | 安全 | ✓ |
| `安全-SSH配置` | `sshd -T 2>/dev/null \| grep -iE 'permitrootlogin\|passwordauthentication\|port'` | 安全 | ✓ |
| `安全-最近登录` | `last -n 10` | 安全 | |
| `动态-负载` | `uptime; who; uptime -s` | 动态 | |
| `动态-进程TOP` | `ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu \| head -8` | 动态 | |
| `动态-进程数` | `ps -e --no-headers \| wc -l` | 动态 | |
| `服务-运行中` | `systemctl list-units --type=service --state=running --no-pager` | 服务 | |
| `服务-Docker` | `docker info --format 'Containers:{{.Containers}}'; docker ps -a` | 服务 | |
| `服务-Docker镜像` | `docker images --format '{{.Repository}}:{{.Tag}} ({{.Size}})'` | 服务 | |
| `服务-Docker挂载` | `for c in $(docker ps --format '{{.Names}}'); do docker inspect "$c" --format '{{.Mounts}}'; done`（running 容器的挂载） | 服务 | |
| `服务-cron` | `crontab -l 2>/dev/null; ls /etc/cron.* /etc/cron.d/ 2>/dev/null` | 服务 | |
| `端口-监听` | `ss -tlnp` | 服务 | ✓ |

## GPU 模块（`has nvidia-smi` 才启用）

| 标签 | 命令 | 类别 | root |
|---|---|---|:---:|
| `GPU详情-头部` | `nvidia-smi \| head -10` | 静态（驱动/CUDA） | |
| `GPU详情-卡表` | `nvidia-smi --query-gpu=index,name,memory.total,memory.used,driver_version,temperature.gpu,power.draw,utilization.gpu --format=csv` | 静态（含动态字段：温度/功耗/利用率，模板仅取静态列） | |
| `GPU详情-全量附录` | `nvidia-smi -q > /tmp/nvidia-smi-q.txt`（附录文件，不进主文本段） | 静态 | |
| `GPU软件栈-nvcc` | `nvcc --version \| tail -1` | 静态 | |
| `GPU软件栈-torch` | `python3 -c "import torch;print(torch.__version__,torch.version.cuda,torch.backends.cudnn.version())" 2>/dev/null` | 静态 | |
| `GPU-PCIe` | `nvidia-smi --query-gpu=pci.bus_id,pcie.link.gen.current,pcie.link.gen.max,pcie.link.width.current,pcie.link.width.max --format=csv` | 静态 | |
| `GPU-PCIe验证` | `lspci -vvv -d ::0300 \| grep -E 'LnkCap\|LnkSta'` | 静态 | ✓ |
| `GPU拓扑-topo` | `nvidia-smi topo -m` | 静态 | |
| `GPU拓扑-NVLink` | `for i in $(seq 0 3); do nvidia-smi nvlink -s -i $i; done` | 静态 |
