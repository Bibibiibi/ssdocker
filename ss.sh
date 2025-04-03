#!/bin/bash

echo "========== Xray Docker 一键部署 =========="

read -p "请输入你希望使用的端口 (默认: 39761): " PORT
PORT=${PORT:-39761}

read -p "请输入 Shadowsocks 密码 (默认: 随机生成): " PASSWORD
if [ -z "$PASSWORD" ]; then
  PASSWORD=$(openssl rand -base64 16)
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

echo "-----------------------------------"
echo "端口: $PORT"
echo "密码: $PASSWORD"
echo "加密方式: $METHOD"
echo "传输协议: tcp（HTTP伪装）"
echo "伪装路径: $FAKE_PATH"
echo "伪装 Host: $FAKE_HOST"
echo "镜像: kingfalse/onekey-docker-xray:dogdi"
echo "-----------------------------------"

read -p "确认部署? [y/N]: " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo "已取消部署。"
  exit 1
fi

docker run -d \
  --restart=always \
  --name xray \
  --network=host \
  -e PORT=$PORT \
  -e PASSWORD=$PASSWORD \
  -e METHOD=$METHOD \
  -e NETWORK=tcp \
  -e FAKE_PATH=$FAKE_PATH \
  -e FAKE_HOST=$FAKE_HOST \
  kingfalse/onekey-docker-xray:dogdi

echo "✅ Xray 已部署完成！"
echo "连接信息："
echo "IP: $(curl -s ifconfig.me)"
echo "端口: $PORT"
echo "加密方式: $METHOD"
echo "伪装路径: $FAKE_PATH"
echo "伪装 Host: $FAKE_HOST"
