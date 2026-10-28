#!/usr/bin/env bash
# server-profile 采集脚本 · 三层档案（静态 + 服务 + 动态 + GPU）· 零依赖 bash · 只读采集
set +e

# --- root 自检（仅脚本文件模式有效；stdin 模式请由调用方使用 'sudo bash -s'）---
if [ "$(id -u)" != "0" ] && [ -f "$0" ]; then
  echo "需 root，自动重提权..." >&2
  exec sudo "$0" "$@"
fi

# --- helper ---
has() { command -v "$1" >/dev/null 2>&1 && return 0 || { echo "（未安装：$1）"; return 1; }; }
run() {
  local label="$1"; shift
  echo "=== [$label] ==="
  local out; out=$("$@" 2>&1); local rc=$?
  echo "$out"
  [ $rc -ne 0 ] && [ -z "$out" ] && echo "FAILED: $* (退出码 $rc)"
  echo
}

probe_torch() {
  python3 -c "import torch;print('host:',torch.__version__,torch.version.cuda,torch.backends.cudnn.version())" 2>/dev/null && return
  command -v docker >/dev/null || { echo "（主机无 torch，且无 docker）"; return; }
  for c in $(docker ps --format '{{.Names}}' 2>/dev/null); do
    docker exec "$c" python3 -c "import torch;print(\"container $c:\",torch.__version__,torch.version.cuda)" 2>/dev/null && return
  done
  echo "（主机与容器均无 torch）"
}

collect_login_users() {
  getent passwd | awk -F: '$7 ~ /(bash|sh|zsh)$/ {print $1":"$3":"$6":"$7}'
}

collect_docker_overview() {
  docker version --format 'Server={{.Server.Version}}' 2>/dev/null
  docker compose version 2>/dev/null || true
  docker info --format 'Containers={{.Containers}} Running={{.ContainersRunning}} Paused={{.ContainersPaused}} Stopped={{.ContainersStopped}} Images={{.Images}}' 2>/dev/null
  docker ps -a --no-trunc --format '{{.Names}}|{{.Image}}|{{.Status}}|{{.Ports}}' 2>/dev/null
}

collect_docker_compose() {
  docker compose ls 2>/dev/null || echo "（docker compose ls 不可用或无项目）"
}

collect_docker_containers() {
  command -v docker >/dev/null || { echo "（无 docker）"; return; }
  local ids; ids=$(docker ps -aq 2>/dev/null)
  [ -z "$ids" ] && { echo "（无容器）"; return; }
  for c in $ids; do
    docker inspect "$c" --format 'CONTAINER|name={{.Name}}|image={{.Config.Image}}|image_id={{.Image}}|status={{.State.Status}}|health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}|created={{.Created}}|started={{.State.StartedAt}}|restart={{.HostConfig.RestartPolicy.Name}}|working_dir={{.Config.WorkingDir}}|compose_project={{index .Config.Labels "com.docker.compose.project"}}|compose_working_dir={{index .Config.Labels "com.docker.compose.project.working_dir"}}|compose_config_files={{index .Config.Labels "com.docker.compose.project.config_files"}}|entrypoint={{json .Config.Entrypoint}}|cmd={{json .Config.Cmd}}|network_mode={{.HostConfig.NetworkMode}}' 2>/dev/null
    docker inspect "$c" --format '{{range $p, $conf := .NetworkSettings.Ports}}PORT|{{$.Name}}|{{$p}} -> {{json $conf}}{{println}}{{end}}' 2>/dev/null
    docker inspect "$c" --format '{{range $k, $v := .NetworkSettings.Networks}}NETWORK|{{$.Name}}|{{$k}}|ip={{$v.IPAddress}}{{println}}{{end}}' 2>/dev/null
    docker inspect "$c" --format '{{range .Config.Env}}ENV_KEY|{{$.Name}}|{{println .}}{{end}}' 2>/dev/null | sed -E 's/=.*$/=<redacted>/'
  done
}

collect_docker_mounts() {
  command -v docker >/dev/null || { echo "（无 docker）"; return; }
  local names; names=$(docker ps -a --format '{{.Names}}' 2>/dev/null)
  [ -z "$names" ] && { echo "（无容器）"; return; }
  for c in $names; do
    echo "[$c]"
    docker inspect "$c" --format '{{range .Mounts}}  {{.Source}} -> {{.Destination}} (type={{.Type}},rw={{.RW}}){{println}}{{end}}' 2>/dev/null
    [ -z "$(docker inspect "$c" --format '{{range .Mounts}}{{.Destination}}{{end}}' 2>/dev/null)" ] && echo "  （无挂载）"
  done
}

collect_docker_images() {
  docker image ls --digests --format '{{.Repository}}|{{.Tag}}|{{.Digest}}|{{.ID}}|{{.CreatedAt}}|{{.Size}}' 2>/dev/null
}

collect_nginx() {
  if ! command -v nginx >/dev/null 2>&1 && [ ! -d /etc/nginx ]; then
    echo "（未安装 nginx）"
    return
  fi
  nginx -t 2>&1 || true
  if [ -d /etc/nginx/conf.d ]; then
    find /etc/nginx/conf.d -maxdepth 1 -type f -printf 'FILE|%f|%TY-%Tm-%Td %TH:%TM:%TS\n' 2>/dev/null | sort
    grep -RInE '^\s*(listen|server_name|proxy_pass|ssl_certificate|client_max_body_size|deny)\b' /etc/nginx/conf.d 2>/dev/null || true
  fi
}

collect_tls_certs() {
  command -v openssl >/dev/null || { echo "（无 openssl）"; return; }
  local found=0
  for cert in /etc/nginx/certs/*.pem /etc/nginx/certs/*.crt /etc/nginx/ssl/*.pem /etc/nginx/ssl/*.crt; do
    [ -f "$cert" ] || continue
    case "$cert" in *key*.pem|*.key) continue ;; esac
    if grep -q "BEGIN CERTIFICATE" "$cert" 2>/dev/null; then
      found=1
      echo "[$cert]"
      openssl x509 -in "$cert" -noout -subject -issuer -dates -ext subjectAltName 2>/dev/null || true
    fi
  done
  [ "$found" -eq 0 ] && echo "（常见 Nginx 证书目录未发现公钥证书）"
}

echo "########## 基底采集开始 $(date '+%F %T') ##########"

run "采集-时间" date --iso-8601=seconds

# 标识
run "标识-主机名" hostname
run "标识-主机名静态" cat /etc/hostname
run "标识-型号" cat /sys/class/dmi/id/product_name
run "标识-虚拟化" systemd-detect-virt
run "标识-序列号" sh -c 'dmidecode -s system-serial-number 2>/dev/null; dmidecode -t bios 2>/dev/null | grep -E "Vendor|Version|Release"'

# 系统
run "系统-发行版" sh -c '. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME"'
run "系统-内核架构" sh -c 'uname -r; uname -m'
run "系统-时区" timedatectl show -p Timezone --value

# 计算 CPU
run "计算CPU-lscpu" sh -c 'LC_ALL=C lscpu'
run "计算CPU-核数" nproc

# 内存
run "内存-free" free -h
run "内存-内存条" sh -c "dmidecode -t memory 2>/dev/null | grep -E 'Size:|Speed:|Type:|Locator:' | grep -vi 'No Module\|Unknown'"

# 存储
run "存储-块设备" lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS,MODEL
run "存储-分区使用" df -hT -x tmpfs -x devtmpfs

# 网络
run "网络-接口" ip -brief addr
run "网络-路由" sh -c 'ip route | grep default'
run "网络-DNS" cat /etc/resolv.conf

# 用户与权限
run "用户-可登录" collect_login_users
run "用户-关键组" sh -c 'getent group sudo docker wheel 2>/dev/null'

# 安全
run "安全-防火墙iptables" iptables -S
run "安全-防火墙nft" sh -c 'nft list ruleset 2>/dev/null'
run "安全-防火墙ufw" sh -c 'ufw status 2>/dev/null; firewall-cmd --list-all 2>/dev/null || echo "（firewalld 未运行）"'
run "安全-SELinux" sh -c 'getenforce 2>/dev/null; sestatus 2>/dev/null; aa-status 2>/dev/null'
run "安全-sudoers" sh -c "grep -rv '^#\|\$' /etc/sudoers /etc/sudoers.d/ 2>/dev/null || echo '（无非注释 sudoers 规则）'"
run "安全-SSH配置" sh -c "sshd -T 2>/dev/null | grep -iE '^(permitrootlogin|passwordauthentication|port|gatewayports) '"
run "安全-最近登录" sh -c 'out=$(last -n 10 2>/dev/null); [ -z "$out" ] && out=$(who -a); [ -z "$out" ] && echo "（last/who 均无登录记录）" || echo "$out"'

# 动态用量
run "动态-负载" sh -c 'uptime; who; uptime -s'
run "动态-进程TOP" sh -c 'ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | head -10'
run "动态-进程数" sh -c 'ps -e --no-headers | wc -l'

# 安装的服务与入口
run "服务-运行中" systemctl list-units --type=service --state=running --no-pager --no-legend
if has docker; then
  run "服务-Docker概览" collect_docker_overview
  run "服务-DockerCompose项目" collect_docker_compose
  run "服务-Docker容器详情" collect_docker_containers
  run "服务-Docker挂载" collect_docker_mounts
  run "服务-Docker镜像" collect_docker_images
fi
run "服务-Nginx配置" collect_nginx
run "服务-TLS证书" collect_tls_certs
run "服务-cron" sh -c 'crontab -l 2>/dev/null; ls /etc/cron.* /etc/cron.d/ 2>/dev/null'

# 监听端口
run "端口-监听" ss -tlnp

echo "########## 基底采集结束 ##########"

# --- GPU 模块（条件）---
if has nvidia-smi; then
  echo "########## GPU 模块开始 ##########"
  run "GPU详情-头部" sh -c 'nvidia-smi | head -10'
  run "GPU详情-卡表" nvidia-smi --query-gpu=index,name,memory.total,memory.used,driver_version,temperature.gpu,power.draw,utilization.gpu --format=csv
  nvidia-smi -q > /tmp/nvidia-smi-q.txt 2>/dev/null && echo "=== [GPU详情-全量附录] ===" && echo "(见 /tmp/nvidia-smi-q.txt)"
  has nvcc && run "GPU软件栈-nvcc" sh -c 'nvcc --version | tail -1'
  run "GPU软件栈-torch" probe_torch
  run "GPU-PCIe" nvidia-smi --query-gpu=pci.bus_id,pcie.link.gen.current,pcie.link.gen.max,pcie.link.width.current,pcie.link.width.max --format=csv
  run "GPU-PCIe验证" sh -c "lspci -vvv -d ::0300 | grep -E 'LnkCap|LnkSta'"
  run "GPU拓扑-topo" nvidia-smi topo -m
  gpu_count=$(nvidia-smi --query-gpu=index --format=csv,noheader 2>/dev/null | wc -l | tr -d ' ')
  [ "${gpu_count:-0}" -gt 0 ] && run "GPU拓扑-NVLink" sh -c "for i in \$(seq 0 $((gpu_count - 1))); do nvidia-smi nvlink -s -i \$i; done"
  echo "########## GPU 模块结束 ##########"
else
  echo "########## 无 NVIDIA GPU，跳过 GPU 模块 ##########"
fi

exit 0
