#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red} Error ${plain} must run this script with root user!\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}System version not detected，please contact the script author! ${plain}\n" && exit 1
fi

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
    arch="amd64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
    arch="arm64"
elif [[ $arch == "s390x" ]]; then
    arch="s390x"
else
    arch="amd64"
    echo -e "${red}Detect architecture failure and use default architecture: ${arch}${plain}"
fi

echo "Architecture: ${arch}"

if [ $(getconf WORD_BIT) != '32' ] && [ $(getconf LONG_BIT) != '64' ]; then
    echo "This software does not support 32-bit system (x86)，please use 64-bit system (x86_64)，if the detection is wrong，please contact the author"
    exit -1
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}Please use CentOS 7 or higher! ${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}Please use Ubuntu 16 or higher! ${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}Please use Debian 8 or higher! ${plain}\n" && exit 1
    fi
fi

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install wget curl tar -y
    else
        apt install wget curl tar -y
    fi
}

#This function will be called when user installed xray-ui out of security
config_after_install() {
    echo -e "${yellow}For security reasons，you need to change the port and account password after complete the installation/update${plain}"
    read -p "Are you want go to Setting?[y/n]": config_confirm
    if [[ x"${config_confirm}" == x"y" || x"${config_confirm}" == x"Y" ]]; then
        read -p "Please set your account Username:" config_account
        echo -e "${yellow}Your account Username will be set to:${config_account}${plain}"
        read -p "Please set your account password:" config_password
        echo -e "${yellow}Your account password will be set to:${config_password}${plain}"
        read -p "Please set the panel access port:" config_port
        echo -e "${yellow}Your panel access port will be set to:${config_port}${plain}"
        echo -e "${yellow}Confirmation of setting，setting in progress${plain}"
        /usr/local/xray-ui/xray-ui setting -username ${config_account} -password ${config_password}
        echo -e "${yellow}Account password setting completed${plain}"
        /usr/local/xray-ui/xray-ui setting -port ${config_port}
        echo -e "${yellow}Panel port setting complete${plain}"
    else
        echo -e "${red}Cancelled，all settings are the default settings，please modify in time${plain}"
    fi
}

install_xray-ui() {
    systemctl stop xray-ui
    cd /usr/local/

    if [ $# == 0 ]; then
        last_version=$(curl -Ls "https://api.github.com/repos/jvdi/xray-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$last_version" ]]; then
            echo -e "${red}Failed to detect xray-ui version，may be out of Github API limit，please try again later，or manually specify xray-ui version to install${plain}"
            exit 1
        fi
        echo -e "The latest version of xray-ui is detected: ${last_version}，start installation"
        wget -N --no-check-certificate -O /usr/local/xray-ui-linux-${arch}.tar.gz https://github.com/jvdi/xray-ui/releases/download/${last_version}/xray-ui-linux-${arch}.tar.gz
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Downloading xray-ui failed，please make sure your server can download the Github file${plain}"
            exit 1
        fi
    else
        last_version=$1
        url="https://github.com/jvdi/xray-ui/releases/download/${last_version}/xray-ui-linux-${arch}.tar.gz"
        echo -e "Start Installation xray-ui v$1"
        wget -N --no-check-certificate -O /usr/local/xray-ui-linux-${arch}.tar.gz ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Download xray-ui v$1 failed，please make sure this version exists${plain}"
            exit 1
        fi
    fi

    if [[ -e /usr/local/xray-ui/ ]]; then
        rm /usr/local/xray-ui/ -rf
    fi

    tar zxvf xray-ui-linux-${arch}.tar.gz
    rm xray-ui-linux-${arch}.tar.gz -f
    cd xray-ui
    chmod +x xray-ui bin/xray-linux-${arch}
    cp -f xray-ui.service /etc/systemd/system/
    wget --no-check-certificate -O /usr/bin/xray-ui https://raw.githubusercontent.com/jvdi/xray-ui/main/xray-ui.sh
    chmod +x /usr/local/xray-ui/xray-ui.sh
    chmod +x /usr/bin/xray-ui
    config_after_install
    #echo -e "If it is a fresh installation， the default web port is ${green}54321${plain}，and the default username and password are ${green}admin${plain}"
    #echo -e "Please make sure that this port is not occupied by another application， ${yellow}and that port 54321 is released${plain}"
    #    echo -e "To change 54321 to another port， enter the xray-ui command to do so，Also make sure that the port you are modifying is also released"
    #echo -e ""
    #echo -e "If it's an update panel， access the panel the way you did before"
    #echo -e ""
    systemctl daemon-reload
    systemctl enable xray-ui
    systemctl start xray-ui
    echo -e "${green}xray-ui v${last_version}${plain} The installation is complete，the panel is up and，"
    echo -e ""
    echo -e "How to use the xray-ui administration script: "
    echo -e "----------------------------------------------"
    echo -e "xray-ui              - Show Admin Menu (more functions)"
    echo -e "xray-ui start        - Launching the xray-ui panel"
    echo -e "xray-ui stop         - Stop xray-ui panel"
    echo -e "xray-ui restart      - Restart the xray-ui panel"
    echo -e "xray-ui status       - View xray-ui status"
    echo -e "xray-ui enable       - Set xray-ui to boot on its own"
    echo -e "xray-ui disable      - Cancel xray-ui autostart"
    echo -e "xray-ui log          - View xray-ui logs"
    echo -e "xray-ui v2-ui        - Migrate the v2-ui account data from this machine to xray-ui"
    echo -e "xray-ui update       - Update xray-ui panel"
    echo -e "xray-ui install      - Installing the xray-ui panel"
    echo -e "xray-ui uninstall    - Uninstall the xray-ui panel"
    echo -e "----------------------------------------------"
}

echo -e "${green}Start Installation${plain}"
install_base
install_xray-ui $1
