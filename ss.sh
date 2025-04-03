#!/bin/bash

echo "========== Xray Docker 一键部署（完整增强版） =========="

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
  sysctl -p && sysctl --system
  echo "✅ 系统优化参数应用完成"
fi

docker run -d \
  --restart=always \
  --name "$CONTAINER_NAME" \
  --network=host \
  --ulimit nofile=1048576:1048576 \
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
