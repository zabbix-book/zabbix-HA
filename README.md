# zabbix-HA
Zabbix Server HA 使用keepalived构建Zabbix-Server的HA功能，作为《Zabbix企业级分布式监控系统》书籍内容的补充

# 1.系统环境
- CentOS 7 X64   
- rpm安装的zabbix_server，非官方安装包请修改脚本对应文件路径即可使用 
- pidof  arping 命令存在 
- root用户执行以下操作

IP地址|角色|机器名
-|-|-
192.168.0.3|  MASTER|  NODE1
192.168.0.4|  BACKUP|  NODE2
192.168.0.5 | VIP| 存在于MASTER机器之上

# 2.安装keepalived
分别在主机MASTER和BACKUP安装keepalived
```
yum install -y keepalived
systemctl keepalived enable
```

#  3. 配置MASTER
```
wget https://raw.githubusercontent.com/zabbix-book/zabbix-HA/master/keepalived.conf-master
mv keepalived.conf-master /etc/keepalived.conf

mkdir -p /etc/keepalived/
cd /etc/keepalived/
wget https://raw.githubusercontent.com/zabbix-book/zabbix-HA/master/ha_switch.sh
chmod 755 /etc/keepalived/ha_switch.sh
```
- 修改/etc/keepalived.conf配置文件 
```
  virtual_ipaddress {
        192.168.0.5  #VIP地址
    }
```
- 修改脚本ha_switch.sh
```
VIP="192.168.0.5"  #VIP
```

#  4. 配置BACKUP
```
wget https://raw.githubusercontent.com/zabbix-book/zabbix-HA/master/keepalived.conf-backup
mv keepalived.conf-master /etc/keepalived.conf

mkdir -p /etc/keepalived/
cd /etc/keepalived/
wget https://raw.githubusercontent.com/zabbix-book/zabbix-HA/master/ha_switch.sh
chmod 755 /etc/keepalived/ha_switch.sh
```
- 修改/etc/keepalived.conf配置文件
```
  virtual_ipaddress {
        192.168.0.5  #VIP地址
    }
```

- 修改脚本ha_switch.sh
```
VIP="192.168.0.5"  #VIP
```

#  5. 启动MASTER keepalived (MASTER机器操作)
在zabbix_server配置就绪后，即zabbix_server.conf配置文件修改完毕，zabbix_server可以在单机环境中正常运行后

- 手动停止zabbix_server
```
systemctl stop zabbix-server
```
- 启动keepalived,此操作会在keepalived的MASTER角色自动开启zabbix_server服务
```
systemctl start keepalived
```

#  6. 启动BACKUP  keepalived  (BACKUP机器操作)
- 手动停止zabbix_server
```
systemctl stop zabbix-server
```
- 启动keepalived
```
systemctl start keepalived
```

# 7. 验证
- 分别在MASTER和BACKUP查看zabbix_server进程是否存在
```
ps -ef |grep zabbix_server
```

- 将MASTER上的zabbix_server手动停止
```
systemctl stop zabbix-server
```
- 将会看到keepalived将zabbix_server进程自动拉起


# 8. 注意事项
由于当前版本的zabbix_server本身并没有设计支持HA工作的方式，
即2个zabbix_server在不同的机器上面工作，
后端连接同一个数据库的情况，故只能采取主备的方式。

如同时将2个zabbix_server启动，
则会造成数据库主键冲突，
以及告警触发2次的问题