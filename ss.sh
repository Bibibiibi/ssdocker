#!/bin/bash
echo ""
echo "请选择操作模式："
echo "1) 安装部署 Xray"
echo "2) 卸载并清理 Xray 容器"
read -p "请输入选项 [1-2]（默认：1）: " ACTION_CHOICE

if [[ "$ACTION_CHOICE" == "2" ]]; then
  echo "🧹 正在卸载 Xray 容器及相关资源..."

  read -p "请输入要删除的容器名称（默认: xray）: " UNINSTALL_NAME
  UNINSTALL_NAME=${UNINSTALL_NAME:-xray}

  if docker ps -a --format '{{.Names}}' | grep -qw "$UNINSTALL_NAME"; then
    docker stop "$UNINSTALL_NAME"
    docker rm "$UNINSTALL_NAME"
    echo "✅ 容器 $UNINSTALL_NAME 已删除"
  else
    echo "⚠️ 未找到容器 $UNINSTALL_NAME，无需删除"
  fi

  echo "是否清理 Docker 镜像（kingfalse/onekey-docker-xray:dogdi）？[y/N]: "
  read CLEAN_IMAGE
  if [[ "$CLEAN_IMAGE" == "y" || "$CLEAN_IMAGE" == "Y" ]]; then
    docker rmi kingfalse/onekey-docker-xray:dogdi
    echo "✅ 镜像已删除"
  fi

  echo "✅ 卸载完成，脚本退出"
  exit 0
fi

echo "========== Xray Docker 一键部署（终极融合版） =========="

echo ""
echo "🔍 正在检测 Docker 是否安装..."
if ! command -v docker &> /dev/null; then
  echo "❌ 未检测到 Docker，正在自动安装..."
  curl -fsSL https://get.docker.com | bash
  systemctl enable docker
  systemctl start docker
  echo "✅ Docker 安装完成"
else
  echo "✅ 已安装 Docker"
fi


read -p "请输入容器名称 (默认: xray): " CONTAINER_NAME
CONTAINER_NAME=${CONTAINER_NAME:-xray}

read -p "请输入你希望使用的端口 (默认: 39761): " PORT
PORT=${PORT:-39761}

echo "请输入 Shadowsocks 密码（留空将自动生成）:"
read -r PASSWORD
PASSWORD=$(echo "$PASSWORD" | tr -d '[:space:]')
if [ -z "$PASSWORD" ]; then
  PASSWORD=$(openssl rand -base64 16)
  echo "自动生成的随机密码为：$PASSWORD"
else
  echo "你设置的密码为：$PASSWORD"
fi

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

read -p "请输入伪装路径 (默认: /): " FAKE_PATH
FAKE_PATH=${FAKE_PATH:-/}

read -p "请输入伪装 Host (默认: weKbP9SVYU.download.windowsupdate.com): " FAKE_HOST
FAKE_HOST=${FAKE_HOST:-weKbP9SVYU.download.windowsupdate.com}

echo ""
read -p "是否优先使用 IPv6 地址？[y/N]: " USE_IPV6
USE_IPV6=${USE_IPV6:-N}

if [[ "$USE_IPV6" == "y" || "$USE_IPV6" == "Y" ]]; then
  SSR_IP=$(curl -s -6 ifconfig.co)
else
  SSR_IP=$(curl -s -4 ifconfig.me)
fi

echo ""
read -p "是否进行系统优化？[Y/n]: " DO_OPT
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

case "$OPT_LEVEL" in
  high) DOCKER_ULIMIT="1048576:1048576" ;;
  mid) DOCKER_ULIMIT="524288:524288" ;;
  low) DOCKER_ULIMIT="65536:65536" ;;
  *) DOCKER_ULIMIT="524288:524288" ;;  # 默认中配
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

echo ""
echo "================== 节点配置信息 =================="

SSR_PORT=$PORT
SSR_METHOD=$METHOD
SSR_PASSWORD=$PASSWORD
SSR_HOST=$FAKE_HOST
SSR_PATH=$FAKE_PATH

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
echo "    plugin: obfs"
echo "    plugin-opts:"
echo "      mode: http"
echo "      host: "$SSR_HOST""
echo "      path: "$SSR_PATH""
echo "    udp: true"

# Surge 配置
echo ""
echo "📱 Surge 配置："
echo "[Proxy]"
echo "xray-ss = ss, $SSR_IP, $SSR_PORT, encrypt-method=$SSR_METHOD, password=$SSR_PASSWORD, obfs=http, obfs-host=$SSR_HOST, obfs-uri=$SSR_PATH, udp-relay=true"

# SS URI
PLUGIN_STRING="plugin=obfs-local%3Bobfs%3Dhttp%3Bobfs-host%3D${SSR_HOST}"
ENCODED=$(echo -n "${SSR_METHOD}:${SSR_PASSWORD}@${SSR_IP}:${SSR_PORT}" | base64 -w 0)
SS_URI="ss://${ENCODED}?${PLUGIN_STRING}#xray-ss"

echo ""
echo "🔗 SS 连接（带 obfs 插件）："
echo "$SS_URI"
