# xray-ui

> This script provided by [vaxilu](https://github.com/vaxilu) - v0.0.0 of this repo just translate to English of [x-ui v0.3.2](https://github.com/vaxilu/x-ui)

xray web UI Panel - support user management system and multiprotocol proxy server

# Features

- System Status Monitoring
- Support multi-user and multi-protocol，web page visualization operation
- Supported protocols: vmess，vless，trojan，shadowsocks，dokodemo-door，socks，http
- Support for configuring more transport configurations
- Traffic statistics，limit traffic，limit expiration time
- Customizable xray configuration template
- Support https access panel (self-provided domain name + ssl certificate)
- Support one-click SSL certificate application and automatic renewal
- For more advanced configuration items，see Panel

# Install & Upgrade

```
bash <(curl -Ls https://raw.githubusercontent.com/jvdi/xray-ui/master/install.sh)
```

## Manual Installation & Upgrade

1. First download the latest package from https://github.com/jvdi/xray-ui/releases，usually choose the `amd64` architecture
2. Then upload this compressed package to `/root/` the directory ，and use `root`the user to log in to the server

> If your server cpu architecture is not `amd64` replace with other architectures

```
cd /root/
rm xray-ui/ /usr/local/xray-ui/ /usr/bin/xray-ui -rf
tar zxvf xray-ui-linux-amd64.tar.gz
chmod +x xray-ui/xray-ui xray-ui/bin/xray-linux-* xray-ui/xray-ui.sh
cp xray-ui/xray-ui.sh /usr/bin/xray-ui
cp -f xray-ui/xray-ui.service /etc/systemd/system/
mv xray-ui/ /usr/local/
systemctl daemon-reload
systemctl enable xray-ui
systemctl restart xray-ui
```

## Install with docker

> This docker tutorial and docker image is provided by [Chasing66](https://github.com/Chasing66)

1. Install docker

```shell
curl -fsSL https://get.docker.com | sh
```

2. Install xray-ui

```shell
mkdir xray-ui && cd xray-ui
docker run -itd --network=host \
    -v $PWD/db/:/etc/xray-ui/ \
    -v $PWD/cert/:/root/cert/ \
    --name xray-ui --restart=unless-stopped \
    javidi/xray-ui:latest
```

> Build your own image

```shell
docker build -t xray-ui .
```

## SSL Certificate Application

> This feature and tutorial is provided by [FranzKafkaYu](https://github.com/FranzKafkaYu) and Translate by [Mohammad Javidi](https://github.com/jvdi)

The script has a built-in SSL certificate application function. To apply for a certificate using this script，the following conditions must be met:

- Know the Cloudflare registered email address
- Know Cloudflare Global API Key
- The domain name has been resolved to the current server through cloudflare

How to get Cloudflare Global API Key:
    ![](media/bda84fbc2ede834deaba1c173a932223.png)
    ![](media/d13ffd6a73f938d1037d0708e31433bf.png)

You only need to input ，`Domain Name`，`Mail`，`API KEY` the schematic diagram is as follows:
        ![](media/2022-04-04_141259.png)

Precautions:

- This script uses DNS API for certificate request
- By default，Let'sEncrypt is used as the CA party
- The certificate installation directory is the /root/cert directory
- The certificates applied for by this script are all wild domain name certificates

## Use of Tlg robot (under development，temporarily unavailable)

> This feature and tutorial is provided by [FranzKafkaYu](https://github.com/FranzKafkaYu)

xray-ui supports daily traffic notifications and panel login reminders via Tg bot. To use Tg bot，you need to apply for it yourself. You can refer to the [blog link](https://coderfan.net/how-to-use-telegram-bot-to-alarm-you-when-someone-login-into-your-vps.html)
for the specific application tutorial. Instructions:Set the bot-related parameters in the panel background，including

- Tg Robot Token
- Tg Bot ChatId
- Tg robot cycle running time，using crontab syntax  

Reference syntax.
- 30 * * * * * * // Notify on the 30ths of every minute
- @hourly // Hourly notification
- @daily // Daily notification (at 00:00 am sharp)
- @every 8h // Notify every 8 hours  

TG Notification Content.
- Node traffic usage
- Panel login reminder
- Node expiration reminder
- Traffic alert reminders  

More features are being planned...
## Suggestion System

- CentOS 7+
- Ubuntu 16+
- Debian 8+

# FAQ

## Migration from v2-ui

First install the latest version of xray-ui on the server where v2-ui is installed，then use the following command to migrate `all inbound account data` from v2-ui to xray-ui，`panel settings and username and password will not be migrated`.

> After successful migration，please `shutdown v2-ui` and `restart xray-ui`，otherwise the inbound of v2-ui will have a `port conflict` with the inbound of xray-ui

```
Xray-ui v2-ui
```

## issue 关闭

各种小白问题看得血压很高

## Stargazers over time

[![Stargazers over time](https://starchart.cc/vaxilu/x-ui.svg)](https://starchart.cc/vaxilu/x-ui)
