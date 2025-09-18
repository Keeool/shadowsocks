#!/bin/bash
# Shadowsocks 安装/卸载管理脚本
# 用法: bash ss_manage.sh install|uninstall

ACTION=$1
PORT_DEFAULT=8388

install_ss() {
  mkdir -p /opt/shadowsocks && cd /opt/shadowsocks || exit
  wget -qO ss-rust.tar.xz https://github.com/shadowsocks/shadowsocks-rust/releases/download/v1.21.2/shadowsocks-v1.21.2.x86_64-unknown-linux-gnu.tar.xz
  tar -xJf ss-rust.tar.xz && rm -f ss-rust.tar.xz

  PORT=$PORT_DEFAULT
  while ss -lntup | grep -q ":$PORT "; do PORT=$((PORT+1)); done
  PASSWORD=$(./ssservice genkey -m aes-256-gcm)

  cat > /opt/shadowsocks/config.json <<EOF
{
  "server": "0.0.0.0",
  "server_port": $PORT,
  "password": "$PASSWORD",
  "method": "aes-256-gcm"
}
EOF

  cat > /etc/systemd/system/shadowsocks.service <<EOF
[Unit]
Description=Shadowsocks Rust Service
After=network.target

[Service]
ExecStart=/opt/shadowsocks/ssserver -c /opt/shadowsocks/config.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reexec
  systemctl enable shadowsocks
  systemctl restart shadowsocks

  if command -v firewall-cmd >/dev/null 2>&1; then
    firewall-cmd --zone=public --add-port=${PORT}/tcp --permanent
    firewall-cmd --zone=public --add-port=${PORT}/udp --permanent
    firewall-cmd --reload
  elif command -v iptables >/dev/null 2>&1; then
    iptables -I INPUT -p tcp --dport $PORT -j ACCEPT
    iptables -I INPUT -p udp --dport $PORT -j ACCEPT
  fi

  SERVER_IP=$(hostname -I | awk '{print $1}')
  SS_LINK="ss://$(echo -n "aes-256-gcm:$PASSWORD" | base64 -w0)@$SERVER_IP:$PORT"

  echo "=============================="
  echo "Shadowsocks 已安装完成"
  echo "IP:       $SERVER_IP"
  echo "端口:     $PORT"
  echo "密码:     $PASSWORD"
  echo "加密:     aes-256-gcm"
  echo "SS链接:   $SS_LINK"
  echo "=============================="
}

uninstall_ss() {
  systemctl stop shadowsocks 2>/dev/null
  systemctl disable shadowsocks 2>/dev/null
  rm -f /etc/systemd/system/shadowsocks.service
  systemctl daemon-reexec
  rm -rf /opt/shadowsocks
  echo "Shadowsocks 已卸载 ✅"
}

if [ "$ACTION" == "install" ]; then
  install_ss
elif [ "$ACTION" == "uninstall" ]; then
  uninstall_ss
else
  echo "用法: bash $0 install|uninstall"
fi
