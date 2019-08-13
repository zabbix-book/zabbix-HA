# cat ha_switch.sh 
#!/bin/bash
#https://github.com/zabbix-book/zabbix-HA
#author: itnihao

STATE="$3"

ulimit -n 40960
VIP="192.168.0.5"
ZBX_SERVER="zabbix_server"
ZBX_SERVER_PID="/var/run/zabbix/zabbix_server.pid"
#SERVER_PORCESS_NUM=$(pidstat -C "zabbix_server"|grep -c "$ZBX_SERVER")

if [ -f "${ZBX_SERVER_PID}" ];then
    SERVER_PID=$(cat "${ZBX_SERVER_PID}")
else
    SERVER_PID=$(pidof "${ZBX_SERVER}")
fi

if [ "${SERVER_PID}" == "" ];then
     SERVER_PID=$(pidof "${ZBX_SERVER}")
fi

case $STATE in
    "MASTER")
        if [ "${SERVER_PID}" == ""  ];then
            systemctl start zabbix-server
        fi
        echo "MASTER" >/etc/zabbix/.ha_role
        exit 0
        ;;
    "BACKUP")
        systemctl stop zabbix-server
        killall -9 zabbix_server
        echo "BACKUP" >/etc/zabbix/.ha_role
        arping "${VIP}" -c 2
        exit 0
        ;;
    "FAULT")
        systemctl stop zabbix-server
        killall -9 zabbix_server
        exit 0
        ;;
    "STATUS")
         #echo "$(date) status">>/tmp/date.log
         ROLE=$(cat /etc/zabbix/.ha_role)
         if [ "${SERVER_PID}" == ""  ];then
            if [ "$ROLE" == "MASTER" ];then
                killall -9 "${ZBX_SERVER}" && rm -f "${ZBX_SERVER_PID}" 
                systemctl start zabbix-server
                exit 0
            elif [ "$ROLE" == "BACKUP" ];then
                ps -ef |grep "/usr/sbin/zabbix_server"|grep -v "grep"|awk '{print $2}'|xargs kill -9 && rm  -f "${ZBX_SERVER_PID}" 
                systemctl stop zabbix-server
                ps -ef |grep "/usr/sbin/zabbix_server"|grep -v "grep"|awk '{print $2}'|xargs kill -9
                if [ -f "${ZBX_SERVER_PID}" ];then
                    rm  -f "${ZBX_SERVER_PID}" 
                fi
                exit 0
            else
                exit 0
            fi
         fi
         ;;
    *)
         echo "unknown state"
         exit 1
         ;;
esac

