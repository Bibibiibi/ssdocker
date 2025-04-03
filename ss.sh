#!/bin/bash

echo "========== Xray Docker 一键部署（智能优化版） =========="

# 容器名称
read -p "请输入容器名称 (默认: xray): " CONTAINER_NAME
CONTAINER_NAME=${CONTAINER_NAME:-xray}

# 端口
read -p "请输入你希望使用的端口 (默认: 39761): " PORT
PORT=${PORT:-39761}

# 密码
echo "请输入 Shadowsocks 密码（留空将自动生成）:"
read -r PASSWORD
PASSWORD=$(echo "$PASSWORD" | tr -d '[:space:]')
if [ -z "$PASSWORD" ]; then
  PASSWORD=$(openssl rand -base64 16)
  echo "自动生成的随机密码为：$PASSWORD"
else
  echo "你设置的密码为：$PASSWORD"
fi

# 加密方式
echo "选择加密方式（默认: aes-128-gcm）:"
echo "1) aes-128-gcm"
echo "2) aes-256-gcm"
echo "3) chacha20-ietf-poly1305"
read -p "请输入选项 [1-3]: " METHOD_OPT
case $METHOD_OPT in
  2) METHOD="aes-256-gcm" ;;
  3) METHOD="chacha20-ietf-poly1305" ;;
  *) METHOD="aes-128-gcm" ;;
esac

# TCP + HTTP 伪装参数
read -p "请输入伪装路径 (默认: /): " FAKE_PATH
FAKE_PATH=${FAKE_PATH:-/}

read -p "请输入伪装 Host (默认: weKbP9SVYU.download.windowsupdate.com): " FAKE_HOST
FAKE_HOST=${FAKE_HOST:-weKbP9SVYU.download.windowsupdate.com}

# 检测系统资源并决定优化等级
CORES=$(nproc)
MEM_MB=$(free -m | awk '/Mem:/ { print $2 }')

echo "检测到 CPU 核心数：$CORES"
echo "检测到内存：${MEM_MB}MB"

if [[ $CORES -ge 2 && $MEM_MB -ge 2048 ]]; then
  OPT_LEVEL="custom"
elif [[ $CORES -ge 1 && $MEM_MB -ge 1024 ]]; then
  OPT_LEVEL="mid"
else
  OPT_LEVEL="low"
fi

echo "⚙️ 系统优化等级：$OPT_LEVEL"

read -p "是否应用智能系统优化？[Y/n]: " DO_OPT
DO_OPT=${DO_OPT:-Y}

if [[ "$DO_OPT" == "Y" || "$DO_OPT" == "y" ]]; then

  echo ""
  echo "请选择优化等级："
  echo "1) 低配服务器优化（1C1G 或更低）"
  echo "2) 中配服务器优化（2C2G 左右）"
  echo "3) 高配服务器优化（4C8G 或更高）"
  read -p "请输入选项 [1-3]（默认：2）: " OPT_LEVEL_INPUT
  case $OPT_LEVEL_INPUT in
    1) OPT_LEVEL="low" ;;
    3) OPT_LEVEL="high" ;;
    *) OPT_LEVEL="mid" ;;
  esac

  echo "🚀 正在应用 $OPT_LEVEL 级别的优化参数..."

  echo "🚀 正在应用 $OPT_LEVEL 级别的优化参数..."

  case "$OPT_LEVEL" in
    high)
      ulimit -n 1048576
      echo "ulimit -n 1048576" >> /etc/profile
      cat > /etc/sysctl.conf <<EOF
fs.file-max = 6815744
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 65535
net.ipv4.tcp_fastopen = 3
net.core.rmem_max=67108864
net.core.wmem_max=67108864
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
      ;;
    mid)
      ulimit -n 524288
      echo "ulimit -n 524288" >> /etc/profile
      cat > /etc/sysctl.conf <<EOF
fs.file-max = 262144
net.core.netdev_max_backlog = 100000
net.core.somaxconn = 32768
net.ipv4.tcp_fastopen = 2
net.core.rmem_max=33554432
net.core.wmem_max=33554432
net.ipv4.tcp_rmem=4096 87380 33554432
net.ipv4.tcp_wmem=4096 65536 33554432
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
      ;;
    low)
      ulimit -n 65536
      echo "ulimit -n 65536" >> /etc/profile
      cat > /etc/sysctl.conf <<EOF
fs.file-max = 65536
net.core.netdev_max_backlog = 8192
net.core.somaxconn = 8192
net.ipv4.tcp_fastopen = 1
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 65536 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
      ;;
  esac

  sysctl -p && sysctl --system
  echo "✅ 系统优化参数应用完成"
fi

echo "-----------------------------------"
echo "容器名称: $CONTAINER_NAME"
echo "端口: $PORT"
echo "密码: $PASSWORD"
echo "加密方式: $METHOD"
echo "传输协议: tcp（HTTP伪装）"
echo "伪装路径: $FAKE_PATH"
echo "伪装 Host: $FAKE_HOST"
echo "-----------------------------------"

read -p "确认部署? [y/N]: " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo "已取消部署。"
  exit 1
fi

# 根据等级设置 Docker 启动参数
case "$OPT_LEVEL" in
  high) DOCKER_ULIMIT="1048576:1048576" ;;
  mid) DOCKER_ULIMIT="524288:524288" ;;
  low) DOCKER_ULIMIT="65536:65536" ;;
esac

docker run -d \
  --restart=always \
  --name "$CONTAINER_NAME" \
  --network=host \
  --ulimit nofile=$DOCKER_ULIMIT \
  -e PORT=$PORT \
  -e PASSWORD=$PASSWORD \
  -e METHOD=$METHOD \
  -e NETWORK=tcp \
  -e FAKE_PATH=$FAKE_PATH \
  -e FAKE_HOST=$FAKE_HOST \
  kingfalse/onekey-docker-xray:dogdi

echo "✅ Xray 容器已部署完成！"
echo "连接信息："
echo "容器名称: $CONTAINER_NAME"
echo "IP: $(curl -s ifconfig.me)"
echo "端口: $PORT"
echo "加密方式: $METHOD"
echo "伪装路径: $FAKE_PATH"
echo "伪装 Host: $FAKE_HOST"


echo ""
echo "================== 节点配置信息 =================="

SSR_IP=$(curl -s ifconfig.me)
SSR_PORT=$PORT
SSR_METHOD=$METHOD
SSR_PASSWORD=$PASSWORD

# Clash 配置
echo ""
echo "📦 Clash 配置："
echo "proxies:"
echo "  - name: xray-ss"
echo "    type: ss"
echo "    server: $SSR_IP"
echo "    port: $SSR_PORT"
echo "    cipher: $SSR_METHOD"
echo "    password: "$SSR_PASSWORD""
echo "    udp: true"

# Surge 配置
echo ""
echo "📱 Surge 配置："
echo "[Proxy]"
echo "xray-ss = ss, $SSR_IP, $SSR_PORT, encrypt-method=$SSR_METHOD, password=$SSR_PASSWORD, udp-relay=true"
