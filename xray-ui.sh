#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

#Add some basic function here
function LOGD() {
    echo -e "${yellow}[DEG] $* ${plain}"
}

function LOGE() {
    echo -e "${red}[ERR] $* ${plain}"
}

function LOGI() {
    echo -e "${green}[INF] $* ${plain}"
}
# check root
[[ $EUID -ne 0 ]] && LOGE "Error: This script must be run with the root user!\n" && exit 1

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
    LOGE "System version not detected, please contact the script author !!!\n" && exit 1
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
        LOGE "Please use CentOS 7 or higher !!!\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        LOGE "Please use Ubuntu 16 or higher !!!\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        LOGE "Please use Debian 8 or higher !!!\n" && exit 1
    fi
fi

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [Default$2]: " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

confirm_restart() {
    confirm "Do you want to restart the panel, restarting the panel will also restart the xray" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}Press Enter to return to the main menu: ${plain}" && read temp
    show_menu
}

install() {
    bash <(curl -Ls https://raw.githubusercontent.com/jvdi/xray-ui/master/install.sh)
    if [[ $? == 0 ]]; then
        if [[ $# == 0 ]]; then
            start
        else
            start 0
        fi
    fi
}

update() {
    confirm "This function will be forced to reinstall the current latest version. The data will not be lost. Do you continue?" "n"
    if [[ $? != 0 ]]; then
        LOGE "Canceled"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 0
    fi
    bash <(curl -Ls https://raw.githubusercontent.com/jvdi/xray-ui/master/install.sh)
    if [[ $? == 0 ]]; then
        LOGI "The update is complete and the panel has been automatically restarted"
        exit 0
    fi
}

uninstall() {
    confirm "Are you sure you want to uninstall the panel, xray will uninstall it too?" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    systemctl stop xray-ui
    systemctl disable xray-ui
    rm /etc/systemd/system/xray-ui.service -f
    systemctl daemon-reload
    systemctl reset-failed
    rm /etc/xray-ui/ -rf
    rm /usr/local/xray-ui/ -rf

    echo ""
    echo -e "Uninstall successful - if you want to delete this script, exit the script and run ${green}rm /usr/bin/xray-ui -f${plain} to do delete"
    echo ""

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

reset_user() {
    confirm "Are you sure you want to reset the username and password of the admin?" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/xray-ui/xray-ui setting -username admin -password admin
    echo -e "Username and password have been reset to ${green}admin${plain}, Now please restart the panel"
    confirm_restart
}

reset_config() {
    confirm "Are you sure you want to reset all the panel settings, the account data will not be lost, the username and password will not be changed" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/xray-ui/xray-ui setting -reset
    echo -e "All panel settings have been reset to their default values, now please restart the panel and use the default port: ${green}54321${plain} to access the panel"
    confirm_restart
}

check_config() {
    info=$(/usr/local/xray-ui/xray-ui setting -show true)
    if [[ $? != 0 ]]; then
        LOGE "get current settings error,please check logs"
        show_menu
    fi
    LOGI "${info}"
}

set_port() {
    echo && echo -n -e "Enter the port number between [1-65535]: " && read port
    if [[ -z "${port}" ]]; then
        LOGD "Canceled"
        before_show_menu
    else
        /usr/local/xray-ui/xray-ui setting -port ${port}
        echo -e "After setting the port, now please restart the panel and use the newly set port ${green}${port}${plain} to access the panel"
        confirm_restart
    fi
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        LOGI "Panel is running, no need to start again, if you want to restart please select restart"
    else
        systemctl start xray-ui
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            LOGI "xray-ui Successful start-up"
        else
            LOGE "The panel failed to start, probably because it took more than two seconds to start, please check the log information later"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    check_status
    if [[ $? == 1 ]]; then
        echo ""
        LOGI "Panel is stopped, no need to stop again"
    else
        systemctl stop xray-ui
        sleep 2
        check_status
        if [[ $? == 1 ]]; then
            LOGI "xray-ui and xray stop successfully"
        else
            LOGE "The panel failed to stop, probably because it took more than two seconds to stop, please check the log information later"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart() {
    systemctl restart xray-ui
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        LOGI "xray-ui and xray Reboot successful"
    else
        LOGE "Panel reboot failed, probably because the boot time exceeded two seconds, please check the log information later"
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

status() {
    systemctl status xray-ui -l
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable() {
    systemctl enable xray-ui
    if [[ $? == 0 ]]; then
        LOGI "xray-ui set boot up successfully"
    else
        LOGE "xray-ui Failed to set boot-up"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

disable() {
    systemctl disable xray-ui
    if [[ $? == 0 ]]; then
        LOGI "xray-ui Cancel boot up successfully"
    else
        LOGE "xray-ui Failed to cancel boot-up"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    journalctl -u xray-ui.service -e --no-pager -f
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

migrate_v2_ui() {
    /usr/local/xray-ui/xray-ui v2-ui

    before_show_menu
}

install_bbr() {
    # temporary workaround for installing bbr
    bash <(curl -L -s https://raw.githubusercontent.com/teddysun/across/master/bbr.sh)
    echo ""
    before_show_menu
}

update_shell() {
    wget -O /usr/bin/xray-ui -N --no-check-certificate https://github.com/jvdi/xray-ui/raw/master/xray-ui.sh
    if [[ $? != 0 ]]; then
        echo ""
        LOGE "Download script failed, please check if you can connect to Github on your local computer"
        before_show_menu
    else
        chmod +x /usr/bin/xray-ui
        LOGI "Upgrade script successfully, please re-run the script" && exit 0
    fi
}

# 0: running, 1: not running, 2: not installed
check_status() {
    if [[ ! -f /etc/systemd/system/xray-ui.service ]]; then
        return 2
    fi
    temp=$(systemctl status xray-ui | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        return 0
    else
        return 1
    fi
}

check_enabled() {
    temp=$(systemctl is-enabled xray-ui)
    if [[ x"${temp}" == x"enabled" ]]; then
        return 0
    else
        return 1
    fi
}

check_uninstall() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        LOGE "Panel is already installed, please do not repeat the installation"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

check_install() {
    check_status
    if [[ $? == 2 ]]; then
        echo ""
        LOGE "Please install the panel first"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

show_status() {
    check_status
    case $? in
    0)
        echo -e "Panel Status: ${green}Running${plain}"
        show_enable_status
        ;;
    1)
        echo -e "Panel Status: ${yellow}Not running${plain}"
        show_enable_status
        ;;
    2)
        echo -e "Panel Status: ${red}Not installed${plain}"
        ;;
    esac
    show_xray_status
}

show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "Whether to boot up: ${green}Yes${plain}"
    else
        echo -e "Whether to boot up or not: ${red}No${plain}"
    fi
}

check_xray_status() {
    count=$(ps -ef | grep "xray-linux" | grep -v "grep" | wc -l)
    if [[ count -ne 0 ]]; then
        return 0
    else
        return 1
    fi
}

show_xray_status() {
    check_xray_status
    if [[ $? == 0 ]]; then
        echo -e "Xray Status: ${green}Run${plain}"
    else
        echo -e "Xray Status: ${red}Not running${plain}"
    fi
}

ssl_cert_issue() {
    echo -E ""
    LOGD "******Instructions for use******"
    LOGI "This script will use the Acme to apply for a certificate, and need to:"
    LOGI "1.Know the Cloudflare registration email"
    LOGI "2.Know the Cloudflare Global API Key"
    LOGI "3.The domain name has been resolved to the current server via Cloudflare"
    LOGI "4.The default installation path for this script to request a cert is /root/cert"
    confirm "I have confirmed the above[y/n]" "y"
    if [ $? -eq 0 ]; then
        cd ~
        LOGI "Install Acme script"
        curl https://get.acme.sh | sh
        if [ $? -ne 0 ]; then
            LOGE "Failed to install acme script"
            exit 1
        fi
        CF_Domain=""
        CF_GlobalKey=""
        CF_AccountEmail=""
        certPath=/root/cert
        if [ ! -d "$certPath" ]; then
            mkdir $certPath
        else
            rm -rf $certPath
            mkdir $certPath
        fi
        LOGD "Please set the domain name:"
        read -p "Input your domain here:" CF_Domain
        LOGD "Your domain name is set to:${CF_Domain}"
        LOGD "Please set the API key:"
        read -p "Input your key here:" CF_GlobalKey
        LOGD "Your API key is:${CF_GlobalKey}"
        LOGD "Please set the registration email:"
        read -p "Input your email here:" CF_AccountEmail
        LOGD "Your registered email address is:${CF_AccountEmail}"
        ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
        if [ $? -ne 0 ]; then
            LOGE "Modify default CA to Lets'Encrypt fails, script exits"
            exit 1
        fi
        export CF_Key="${CF_GlobalKey}"
        export CF_Email=${CF_AccountEmail}
        ~/.acme.sh/acme.sh --issue --dns dns_cf -d ${CF_Domain} -d *.${CF_Domain} --log
        if [ $? -ne 0 ]; then
            LOGE "Cert issuance failure, script exit"
            exit 1
        else
            LOGI "Cert issued successfully, installation in progress..."
        fi
        ~/.acme.sh/acme.sh --installcert -d ${CF_Domain} -d *.${CF_Domain} --ca-file /root/cert/ca.cer \
        --cert-file /root/cert/${CF_Domain}.cer --key-file /root/cert/${CF_Domain}.key \
        --fullchain-file /root/cert/fullchain.cer
        if [ $? -ne 0 ]; then
            LOGE "Cert installation failed, script exited"
            exit 1
        else
            LOGI "The cert is installed successfully, turn on automatic update..."
        fi
        ~/.acme.sh/acme.sh --upgrade --auto-upgrade
        if [ $? -ne 0 ]; then
            LOGE "Auto update setting failed, script quit"
            ls -lah cert
            chmod 755 $certPath
            exit 1
        else
            LOGI "The cert has been installed and automatic update has been enabled, the specific information is as follows"
            ls -lah cert
            chmod 755 $certPath
        fi
    else
        show_menu
    fi
}

show_usage() {
    echo "How to use the xray-ui administration script: "
    echo "----------------------------------------------"
    echo "xray-ui              - Show Admin Menu (more functions)"
    echo "xray-ui start        - Launching the xray-ui panel"
    echo "xray-ui stop         - Stop xray-ui panel"
    echo "xray-ui restart      - Restart the xray-ui panel"
    echo "xray-ui status       - View xray-ui status"
    echo "xray-ui enable       - Set xray-ui to boot on its own"
    echo "xray-ui disable      - Cancel xray-ui boot-up"
    echo "xray-ui log          - View xray-ui logs"
    echo "xray-ui v2-ui        - Migrate the v2-ui account data from this machine to xray-ui"
    echo "xray-ui update       - Update xray-ui panel"
    echo "xray-ui install      - Installing the xray-ui panel"
    echo "xray-ui uninstall    - Uninstall the xray-ui panel"
    echo "----------------------------------------------"
}

show_menu() {
    echo -e "
  ${green}xray-ui panel management script${plain}
  ${green}0.${plain} Exit Script
————————————————
  ${green}1.${plain} Install xray-ui
  ${green}2.${plain} Update xray-ui
  ${green}3.${plain} Uninstall xray-ui
————————————————
  ${green}4.${plain} Reset username password
  ${green}5.${plain} Reset Panel Settings
  ${green}6.${plain} Setting the panel port
  ${green}7.${plain} View current panel settings
————————————————
  ${green}8.${plain} Start xray-ui
  ${green}9.${plain} Stop xray-ui
  ${green}10.${plain} Restart xray-ui
  ${green}11.${plain} View xray-ui status
  ${green}12.${plain} View xray-ui logs
————————————————
  ${green}13.${plain} Set xray-ui to boot on its own
  ${green}14.${plain} Cancel xray-ui boot-up
————————————————
  ${green}15.${plain} One-click install of bbr (latest kernel)
  ${green}16.${plain} One-click app for SSL cert (acme app)
 "
    show_status
    echo && read -p "Please enter the selection [0-16]: " num

    case "${num}" in
    0)
        exit 0
        ;;
    1)
        check_uninstall && install
        ;;
    2)
        check_install && update
        ;;
    3)
        check_install && uninstall
        ;;
    4)
        check_install && reset_user
        ;;
    5)
        check_install && reset_config
        ;;
    6)
        check_install && set_port
        ;;
    7)
        check_install && check_config
        ;;
    8)
        check_install && start
        ;;
    9)
        check_install && stop
        ;;
    10)
        check_install && restart
        ;;
    11)
        check_install && status
        ;;
    12)
        check_install && show_log
        ;;
    13)
        check_install && enable
        ;;
    14)
        check_install && disable
        ;;
    15)
        install_bbr
        ;;
    16)
        ssl_cert_issue
        ;;
    *)
        LOGE "Please enter the correct number [0-16]"
        ;;
    esac
}

if [[ $# > 0 ]]; then
    case $1 in
    "start")
        check_install 0 && start 0
        ;;
    "stop")
        check_install 0 && stop 0
        ;;
    "restart")
        check_install 0 && restart 0
        ;;
    "status")
        check_install 0 && status 0
        ;;
    "enable")
        check_install 0 && enable 0
        ;;
    "disable")
        check_install 0 && disable 0
        ;;
    "log")
        check_install 0 && show_log 0
        ;;
    "v2-ui")
        check_install 0 && migrate_v2_ui 0
        ;;
    "update")
        check_install 0 && update 0
        ;;
    "install")
        check_uninstall 0 && install 0
        ;;
    "uninstall")
        check_install 0 && uninstall 0
        ;;
    *) show_usage ;;
    esac
else
    show_menu
fi