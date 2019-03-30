#!/bin/bash
set -e

export config_path=${config_path:-/etc/wireguard}
export wg_port=${wg_port:-8080}
export wg_ip=${wg_ip:-127.0.0.1}

echo 1 > /proc/sys/net/ipv4/ip_forward

build_module(){
cd /wireguard/src
echo "Building the wireguard kernel module..."
make module
echo "Installing the wireguard kernel module..."
make module-install
echo "Cleaning up..."
make clean
echo "Successfully built and installed the wireguard kernel module!"
# shellcheck disable=SC2068
exec $@
}
#build_module


set_config(){
# 创建并进入WireGuard文件夹
mkdir -p ${config_path} && chmod 0777 ${config_path}
cd ${config_path}
umask 077
# 生成服务器和客户端密钥对
wg genkey | tee ${config_path}/server_privatekey | wg pubkey > ${config_path}/server_publickey
wg genkey | tee ${config_path}/client_privatekey | wg pubkey > ${config_path}/client_publickey

# 重要！如果名字不是eth0, 以下PostUp和PostDown处里面的eth0替换成自己服务器显示的名字
# ListenPort为端口号，可以自己设置想使用的数字
# 以下内容一次性粘贴执行，不要分行执行
echo "
[Interface]
PrivateKey = $(cat ${config_path}/server_privatekey)
Address = 10.0.0.1/24
PostUp   = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
ListenPort = ${wg_port}
DNS = 8.8.8.8
#k8s中coredns的地址
DNS = 10.96.0.2
#公司自己搭建的DNSMASQ服务器地址
DNS = 10.252.97.139
MTU = 1420

[Peer]
PublicKey = $(cat ${config_path}/client_publickey)
AllowedIPs = 10.0.0.2/32 " > ${config_path}/wg0.conf

# Endpoint是自己服务器ip和服务端配置文件中设置的端口号，自己在本地编辑好再粘贴到SSH里
# 以下内容一次性粘贴执行，不要分行执行
echo "
[Interface]
PrivateKey = $(cat ${config_path}/client_privatekey)
Address = 10.0.0.2/24
DNS = 8.8.8.8
#k8s中coredns的地址
DNS = 10.96.0.2
#公司自己搭建的DNSMASQ服务器地址
DNS = 10.252.97.139
MTU = 1420

[Peer]
PublicKey = $(cat ${config_path}/server_publickey)
Endpoint = ${wg_ip}:${wg_port}
AllowedIPs = 0.0.0.0/0, ::0/0
PersistentKeepalive = 25 " > ${config_path}/client.conf
}
set_config


add_user(){
# 生成新的客户端密钥对
wg genkey | tee client0_privatekey | wg pubkey > client0_publickey


# 在服务端配置文件中加入新的客户端公钥
# AllowedIPs重新定义一段
# 一次性复制粘贴，不要分行执行
echo "
[Peer]
PublicKey = $(cat client0_publickey)
AllowedIPs = 10.0.0.3/32" >> ${config_path}/wg0.conf


# 新建一个客户端文件，使用新客户端密钥的私钥
# Address与上面的AllowedIPs保持一致
# Endpoint和之前的一样，为服务器ip和设置好的ListenPort
# 一次性复制粘贴，不要分行执行
echo "
[Interface]
PrivateKey = $(cat client0_privatekey)
Address = 10.0.0.3/24
DNS = 8.8.8.8
#k8s中coredns的地址
DNS = 10.96.0.2
#公司自己搭建的DNSMASQ服务器地址
DNS = 10.252.97.139
MTU = 1420

[Peer]
PublicKey = $(cat server_publickey)
Endpoint = ${wg_ip}:${wg_port}
AllowedIPs = 0.0.0.0/0, ::0/0
PersistentKeepalive = 25 " > client0.conf
}
#add_user

/bin/bash "$@"

wg show

# check if Wireguard is running
if [[ $(wg) ]]
then
    syslogd -n      # keep container alive
else
    echo "stopped"  # else exit container
fi