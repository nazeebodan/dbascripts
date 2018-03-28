### 1. 环境介绍
ip地址 | 主机名 | 角色
:-: | :-: | :-:
192.168.0.175| nazeebo| master
192.168.0.176 | lowa | slave
192.168.0.200 | ai2018 | slave + manager

```
shell> cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
192.168.0.175 nazeebo
192.168.0.176 lowa
192.168.0.200 ai2018
```

### 2. 配置步骤
- [ ] 配置3台MySQL服务器1主2从(_基于gtid_)
- [ ] 在数据节点和管理节点安装相应的 mha 软件包
- [ ] 安装mha manager
- [ ] 配置ssh的互通
- [ ] 对从库进行一些设置:只读,relaylog清理
- [ ] 在管理节点配置 mha 的配置信息和脚本
- [ ] 添加虚拟IP

#### 2.1.配置3台MySQL服务器1主2从(_基于gtid_)
###### 2.1.1 在主库上创建复制用户和管理用户:  
创建复制用户并授权
```
SQL> GRANT REPLICATION SLAVE ON *.* TO repluser@192.168.0.176 IDENTIFIED BY  'Oracle123';
SQL> GRANT REPLICATION SLAVE ON *.* TO repluser@192.168.0.200 IDENTIFIED BY  'Oracle123';
SQL> flush privileges;
```
创建管理用户并授权
```
SQL> grant all privileges on *.* to 'mhamon'@'192.168.0.200' identified  by 'Oracle123';
SQL> flush privileges;
```

###### 2.1.2 在两台从库上配置主从复制
```
SQL> CHANGE MASTER TO MASTER_HOST='192.168.0.175',   
MASTER_USER='repluser',                   
MASTER_PASSWORD='Oracle123',              
MASTER_AUTO_POSITION=1;
```

#### 2.2 安装相应的perl包

在每个节点安装mha4node
```
[root@lowa mha4mysql-0.57]# cd mha4mysql-node-0.57
[root@lowa mha4mysql-node-0.57]# ls
AUTHORS  bin  COPYING  debian  inc  lib  Makefile.PL  MANIFEST  META.yml  README  rpm  t
[root@lowa mha4mysql-node-0.57]# perl Makefile.PL
*** Module::AutoInstall version 1.06
*** Checking for Perl dependencies...
[Core Features]
- DBI        ...loaded. (1.609)
- DBD::mysql ...loaded. (4.013)
*** Module::AutoInstall configuration finished.
Checking if your kit is complete...
Looks good
Writing Makefile for mha4mysql::node
[root@lowa mha4mysql-node-0.57]# make && make install
cp lib/MHA/BinlogPosFinderElp.pm blib/lib/MHA/BinlogPosFinderElp.pm
cp lib/MHA/NodeUtil.pm blib/lib/MHA/NodeUtil.pm
cp lib/MHA/BinlogManager.pm blib/lib/MHA/BinlogManager.pm
cp lib/MHA/SlaveUtil.pm blib/lib/MHA/SlaveUtil.pm
cp lib/MHA/NodeConst.pm blib/lib/MHA/NodeConst.pm
cp lib/MHA/BinlogPosFindManager.pm blib/lib/MHA/BinlogPosFindManager.pm
cp lib/MHA/BinlogPosFinderXid.pm blib/lib/MHA/BinlogPosFinderXid.pm
cp lib/MHA/BinlogHeaderParser.pm blib/lib/MHA/BinlogHeaderParser.pm
cp lib/MHA/BinlogPosFinder.pm blib/lib/MHA/BinlogPosFinder.pm
cp bin/filter_mysqlbinlog blib/script/filter_mysqlbinlog
/usr/bin/perl "-Iinc" -MExtUtils::MY -e 'MY->fixin(shift)' -- blib/script/filter_mysqlbinlog
cp bin/apply_diff_relay_logs blib/script/apply_diff_relay_logs
/usr/bin/perl "-Iinc" -MExtUtils::MY -e 'MY->fixin(shift)' -- blib/script/apply_diff_relay_logs
cp bin/purge_relay_logs blib/script/purge_relay_logs
/usr/bin/perl "-Iinc" -MExtUtils::MY -e 'MY->fixin(shift)' -- blib/script/purge_relay_logs
cp bin/save_binary_logs blib/script/save_binary_logs
/usr/bin/perl "-Iinc" -MExtUtils::MY -e 'MY->fixin(shift)' -- blib/script/save_binary_logs
Manifying blib/man1/filter_mysqlbinlog.1
Manifying blib/man1/apply_diff_relay_logs.1
Manifying blib/man1/purge_relay_logs.1
Manifying blib/man1/save_binary_logs.1
Installing /usr/local/share/perl5/MHA/BinlogPosFinderXid.pm
Installing /usr/local/share/perl5/MHA/BinlogPosFinder.pm
Installing /usr/local/share/perl5/MHA/NodeUtil.pm
Installing /usr/local/share/perl5/MHA/BinlogPosFindManager.pm
Installing /usr/local/share/perl5/MHA/SlaveUtil.pm
Installing /usr/local/share/perl5/MHA/NodeConst.pm
Installing /usr/local/share/perl5/MHA/BinlogHeaderParser.pm
Installing /usr/local/share/perl5/MHA/BinlogPosFinderElp.pm
Installing /usr/local/share/perl5/MHA/BinlogManager.pm
Installing /usr/local/share/man/man1/filter_mysqlbinlog.1
Installing /usr/local/share/man/man1/save_binary_logs.1
Installing /usr/local/share/man/man1/apply_diff_relay_logs.1
Installing /usr/local/share/man/man1/purge_relay_logs.1
Installing /usr/local/bin/apply_diff_relay_logs
Installing /usr/local/bin/purge_relay_logs
Installing /usr/local/bin/save_binary_logs
Installing /usr/local/bin/filter_mysqlbinlog
Appending installation info to /usr/lib64/perl5/perllocal.pod
```

在管理节点安装mha4manager

安装相应的perl包
```
[root@ai2018 mha4mysql-manager-0.57]# perl -MDBD::mysql -e "print\"module installed\n\""
module installed
[root@ai2018 mha4mysql-manager-0.57]# perl -Config::Tiny -e "print\"module installed\n\""
Unknown Unicode option letter 'n'.
[root@ai2018 mha4mysql-manager-0.57]# ls
AUTHORS  bin  blib  COPYING  debian  inc  lib  Makefile  Makefile.PL  MANIFEST  META.yml  README  rpm  samples  t  tests
[root@ai2018 mha4mysql-manager-0.57]# perl Makefile.PL
*** Module::AutoInstall version 1.06
*** Checking for Perl dependencies...
[Core Features]
- DBI                   ...loaded. (1.609)
- DBD::mysql            ...loaded. (4.013)
- Time::HiRes           ...loaded. (1.9721)
- Config::Tiny          ...missing.
- Log::Dispatch         ...missing.
- Parallel::ForkManager ...loaded. (0.7.9)
- MHA::NodeConst        ...loaded. (0.57)
==> Auto-install the 2 mandatory module(s) from CPAN? [y] y
*** Dependencies will be installed the next time you type 'make'.
*** Module::AutoInstall configuration finished.
Warning: prerequisite Config::Tiny 0 not found.
Warning: prerequisite Log::Dispatch 0 not found.
Writing Makefile for mha4mysql::manager
```


采用cpanm来进行安装.

安装mha4manager
```
[root@ai2018 mha4mysql-manager-0.57]# pwd
/softdb/mha4mysql-0.57/mha4mysql-manager-0.57
[root@ai2018 mha4mysql-manager-0.57]# ls
AUTHORS  bin  blib  COPYING  debian  inc  lib  Makefile  Makefile.PL  MANIFEST  META.yml  README  rpm  samples  t  tests
[root@ai2018 mha4mysql-manager-0.57]# perl Makefile.PL
*** Module::AutoInstall version 1.06
*** Checking for Perl dependencies...
[Core Features]
- DBI                   ...loaded. (1.609)
- DBD::mysql            ...loaded. (4.013)
- Time::HiRes           ...loaded. (1.9721)
- Config::Tiny          ...loaded. (2.23)
- Log::Dispatch         ...loaded. (2.67)
- Parallel::ForkManager ...loaded. (0.7.9)
- MHA::NodeConst        ...loaded. (0.57)
*** Module::AutoInstall configuration finished.
Generating a Unix-style Makefile
Writing Makefile for mha4mysql::manager
Writing MYMETA.yml and MYMETA.json
[root@ai2018 mha4mysql-manager-0.57]# make && make install
cp lib/MHA/ManagerUtil.pm blib/lib/MHA/ManagerUtil.pm
cp lib/MHA/HealthCheck.pm blib/lib/MHA/HealthCheck.pm
cp lib/MHA/Config.pm blib/lib/MHA/Config.pm
cp lib/MHA/ServerManager.pm blib/lib/MHA/ServerManager.pm
cp lib/MHA/ManagerConst.pm blib/lib/MHA/ManagerConst.pm
cp lib/MHA/FileStatus.pm blib/lib/MHA/FileStatus.pm
cp lib/MHA/ManagerAdmin.pm blib/lib/MHA/ManagerAdmin.pm
cp lib/MHA/MasterFailover.pm blib/lib/MHA/MasterFailover.pm
cp lib/MHA/ManagerAdminWrapper.pm blib/lib/MHA/ManagerAdminWrapper.pm
cp lib/MHA/MasterRotate.pm blib/lib/MHA/MasterRotate.pm
cp lib/MHA/MasterMonitor.pm blib/lib/MHA/MasterMonitor.pm
cp lib/MHA/Server.pm blib/lib/MHA/Server.pm
cp lib/MHA/SSHCheck.pm blib/lib/MHA/SSHCheck.pm
cp lib/MHA/DBHelper.pm blib/lib/MHA/DBHelper.pm
cp bin/masterha_check_repl blib/script/masterha_check_repl
"/usr/bin/perl" "-Iinc" -MExtUtils::MY -e 'MY->fixin(shift)' -- blib/script/masterha_check_repl
cp bin/masterha_check_ssh blib/script/masterha_check_ssh
"/usr/bin/perl" "-Iinc" -MExtUtils::MY -e 'MY->fixin(shift)' -- blib/script/masterha_check_ssh
cp bin/masterha_check_status blib/script/masterha_check_status
"/usr/bin/perl" "-Iinc" -MExtUtils::MY -e 'MY->fixin(shift)' -- blib/script/masterha_check_status
cp bin/masterha_conf_host blib/script/masterha_conf_host
"/usr/bin/perl" "-Iinc" -MExtUtils::MY -e 'MY->fixin(shift)' -- blib/script/masterha_conf_host
cp bin/masterha_manager blib/script/masterha_manager
"/usr/bin/perl" "-Iinc" -MExtUtils::MY -e 'MY->fixin(shift)' -- blib/script/masterha_manager
cp bin/masterha_master_monitor blib/script/masterha_master_monitor
"/usr/bin/perl" "-Iinc" -MExtUtils::MY -e 'MY->fixin(shift)' -- blib/script/masterha_master_monitor
cp bin/masterha_master_switch blib/script/masterha_master_switch
"/usr/bin/perl" "-Iinc" -MExtUtils::MY -e 'MY->fixin(shift)' -- blib/script/masterha_master_switch
cp bin/masterha_secondary_check blib/script/masterha_secondary_check
"/usr/bin/perl" "-Iinc" -MExtUtils::MY -e 'MY->fixin(shift)' -- blib/script/masterha_secondary_check
cp bin/masterha_stop blib/script/masterha_stop
"/usr/bin/perl" "-Iinc" -MExtUtils::MY -e 'MY->fixin(shift)' -- blib/script/masterha_stop
Manifying 9 pod documents
Manifying 9 pod documents
Installing /usr/local/share/perl5/MHA/MasterRotate.pm
Installing /usr/local/share/perl5/MHA/DBHelper.pm
Installing /usr/local/share/perl5/MHA/SSHCheck.pm
Installing /usr/local/share/perl5/MHA/FileStatus.pm
Installing /usr/local/share/perl5/MHA/ManagerConst.pm
Installing /usr/local/share/perl5/MHA/ManagerUtil.pm
Installing /usr/local/share/perl5/MHA/MasterFailover.pm
Installing /usr/local/share/perl5/MHA/ManagerAdminWrapper.pm
Installing /usr/local/share/perl5/MHA/Server.pm
Installing /usr/local/share/perl5/MHA/ServerManager.pm
Installing /usr/local/share/perl5/MHA/ManagerAdmin.pm
Installing /usr/local/share/perl5/MHA/MasterMonitor.pm
Installing /usr/local/share/perl5/MHA/HealthCheck.pm
Installing /usr/local/share/perl5/MHA/Config.pm
Installing /usr/local/share/man/man1/masterha_check_status.1
Installing /usr/local/share/man/man1/masterha_check_ssh.1
Installing /usr/local/share/man/man1/masterha_manager.1
Installing /usr/local/share/man/man1/masterha_stop.1
Installing /usr/local/share/man/man1/masterha_conf_host.1
Installing /usr/local/share/man/man1/masterha_master_switch.1
Installing /usr/local/share/man/man1/masterha_secondary_check.1
Installing /usr/local/share/man/man1/masterha_master_monitor.1
Installing /usr/local/share/man/man1/masterha_check_repl.1
Installing /usr/local/bin/masterha_master_monitor
Installing /usr/local/bin/masterha_secondary_check
Installing /usr/local/bin/masterha_stop
Installing /usr/local/bin/masterha_check_status
Installing /usr/local/bin/masterha_check_ssh
Installing /usr/local/bin/masterha_master_switch
Installing /usr/local/bin/masterha_conf_host
Installing /usr/local/bin/masterha_manager
Installing /usr/local/bin/masterha_check_repl
Appending installation info to /usr/lib64/perl5/perllocal.pod
```

#### 2.3 配置ssh互通
采用ssh-copy-id是最方便的手段,如果OS上面没有这个命令,可以先用
`yum install openssl/openssl-client` 来进行安装

```
shell> ssh-keygen
shell> ssh-copy-id  -i  /root/.ssh/id_rsa.pub  "-p 10022  root@192.168.0.175"
shell> ssh-copy-id  -i  /root/.ssh/id_rsa.pub  "-p 10022  root@192.168.0.176"
shell> ssh-copy-id  -i  /root/.ssh/id_rsa.pub  "-p 10022  root@192.168.0.200"
```
```
或者修改全局的
vim /etc/ssh/ssh_config
Port 20022
```

#### 2.4 对从库进行设置
###### 2.4.1 设置只读

###### 2.4.2 relaylog的清理

#### 2.5 mha管理节点的配置
###### 2.5.1 节点的脚本配置
###### 2.5.2 failover脚本的设置
###### 2.5.3 sendmail脚本的设置
###### 2.5.4 互通性的验证
报错:
```
[root@ai2018 .ssh]# masterha_check_ssh --conf=/etc/mha/app1/app1.cnf
Mon Mar 26 22:36:57 2018 - [warning] Global configuration file /etc/masterha_default.cnf not found. Skipping.
Mon Mar 26 22:36:57 2018 - [info] Reading application default configuration from /etc/mha/app1/app1.cnf..
Mon Mar 26 22:36:57 2018 - [info] Reading server configuration from /etc/mha/app1/app1.cnf..
Mon Mar 26 22:36:57 2018 - [info] Starting SSH connection tests..
Mon Mar 26 22:36:58 2018 - [debug]
Mon Mar 26 22:36:57 2018 - [debug]  Connecting via SSH from root@192.168.0.175(192.168.0.175:10022) to root@192.168.0.176(192.168.0.176:10022)..
Mon Mar 26 22:36:57 2018 - [debug]   ok.
Mon Mar 26 22:36:57 2018 - [debug]  Connecting via SSH from root@192.168.0.175(192.168.0.175:10022) to root@192.168.0.200(192.168.0.200:10022)..
Mon Mar 26 22:36:58 2018 - [debug]   ok.
Mon Mar 26 22:36:58 2018 - [debug]
Mon Mar 26 22:36:57 2018 - [debug]  Connecting via SSH from root@192.168.0.176(192.168.0.176:10022) to root@192.168.0.175(192.168.0.175:10022)..
Mon Mar 26 22:36:58 2018 - [debug]   ok.
Mon Mar 26 22:36:58 2018 - [debug]  Connecting via SSH from root@192.168.0.176(192.168.0.176:10022) to root@192.168.0.200(192.168.0.200:10022)..
Mon Mar 26 22:36:58 2018 - [debug]   ok.
Mon Mar 26 22:36:58 2018 - [error][/usr/local/share/perl5/MHA/SSHCheck.pm, ln63]
Mon Mar 26 22:36:58 2018 - [debug]  Connecting via SSH from root@192.168.0.200(192.168.0.200:10022) to root@192.168.0.175(192.168.0.175:10022)..
Permission denied (publickey,password,keyboard-interactive).
Mon Mar 26 22:36:58 2018 - [error][/usr/local/share/perl5/MHA/SSHCheck.pm, ln111] SSH connection from root@192.168.0.200(192.168.0.200:10022) to root@192.168.0.175(192.168.0.175:10022) failed!
SSH Configuration Check Failed!
```

正确配置后,验证应该如下:
```
[root@ai2018 ~]# masterha_check_ssh --conf=/etc/mha/app1/app1.cnf
Mon Mar 26 23:01:32 2018 - [warning] Global configuration file /etc/masterha_default.cnf not found. Skipping.
Mon Mar 26 23:01:32 2018 - [info] Reading application default configuration from /etc/mha/app1/app1.cnf..
Mon Mar 26 23:01:32 2018 - [info] Reading server configuration from /etc/mha/app1/app1.cnf..
Mon Mar 26 23:01:32 2018 - [info] Starting SSH connection tests..
Mon Mar 26 23:01:33 2018 - [debug]
Mon Mar 26 23:01:32 2018 - [debug]  Connecting via SSH from root@192.168.0.175(192.168.0.175:10022) to root@192.168.0.176(192.168.0.176:10022)..
Mon Mar 26 23:01:33 2018 - [debug]   ok.
Mon Mar 26 23:01:33 2018 - [debug]  Connecting via SSH from root@192.168.0.175(192.168.0.175:10022) to root@192.168.0.200(192.168.0.200:10022)..
Mon Mar 26 23:01:33 2018 - [debug]   ok.
Mon Mar 26 23:01:34 2018 - [debug]
Mon Mar 26 23:01:33 2018 - [debug]  Connecting via SSH from root@192.168.0.176(192.168.0.176:10022) to root@192.168.0.175(192.168.0.175:10022)..
Mon Mar 26 23:01:33 2018 - [debug]   ok.
Mon Mar 26 23:01:33 2018 - [debug]  Connecting via SSH from root@192.168.0.176(192.168.0.176:10022) to root@192.168.0.200(192.168.0.200:10022)..
Mon Mar 26 23:01:33 2018 - [debug]   ok.
Mon Mar 26 23:01:34 2018 - [debug]
Mon Mar 26 23:01:33 2018 - [debug]  Connecting via SSH from root@192.168.0.200(192.168.0.200:10022) to root@192.168.0.175(192.168.0.175:10022)..
Mon Mar 26 23:01:34 2018 - [debug]   ok.
Mon Mar 26 23:01:34 2018 - [debug]  Connecting via SSH from root@192.168.0.200(192.168.0.200:10022) to root@192.168.0.176(192.168.0.176:10022)..
Mon Mar 26 23:01:34 2018 - [debug]   ok.
Mon Mar 26 23:01:34 2018 - [info] All SSH connection tests passed successfully.
```
###### 2.5.5 复制正确性的验证

报错1
```
[root@ai2018 app1]# masterha_check_repl --conf=/etc/mha/app1/app1.cnf
Mon Mar 26 22:51:18 2018 - [warning] Global configuration file /etc/masterha_default.cnf not found. Skipping.
Mon Mar 26 22:51:18 2018 - [info] Reading application default configuration from /etc/mha/app1/app1.cnf..
Mon Mar 26 22:51:18 2018 - [info] Reading server configuration from /etc/mha/app1/app1.cnf..
Mon Mar 26 22:51:18 2018 - [info] MHA::MasterMonitor version 0.57.
Mon Mar 26 22:51:18 2018 - [info] GTID failover mode = 1
Mon Mar 26 22:51:18 2018 - [info] Dead Servers:
Mon Mar 26 22:51:18 2018 - [info] Alive Servers:
Mon Mar 26 22:51:18 2018 - [info]   192.168.0.175(192.168.0.175:3306)
Mon Mar 26 22:51:18 2018 - [info]   192.168.0.176(192.168.0.176:3306)
Mon Mar 26 22:51:18 2018 - [info]   192.168.0.200(192.168.0.200:3306)
Mon Mar 26 22:51:18 2018 - [info] Alive Slaves:
Mon Mar 26 22:51:18 2018 - [info]   192.168.0.176(192.168.0.176:3306)  Version=5.7.21-log (oldest major version between slaves) log-bin:enabled
Mon Mar 26 22:51:18 2018 - [info]     GTID ON
Mon Mar 26 22:51:18 2018 - [info]     Replicating from 192.168.0.175(192.168.0.175:3306)
Mon Mar 26 22:51:18 2018 - [info]   192.168.0.200(192.168.0.200:3306)  Version=5.7.21-log (oldest major version between slaves) log-bin:enabled
Mon Mar 26 22:51:18 2018 - [info]     GTID ON
Mon Mar 26 22:51:18 2018 - [info]     Replicating from 192.168.0.175(192.168.0.175:3306)
Mon Mar 26 22:51:18 2018 - [info] Current Alive Master: 192.168.0.175(192.168.0.175:3306)
Mon Mar 26 22:51:18 2018 - [info] Checking slave configurations..
Mon Mar 26 22:51:18 2018 - [info] Checking replication filtering settings..
Mon Mar 26 22:51:18 2018 - [info]  binlog_do_db= , binlog_ignore_db=
Mon Mar 26 22:51:18 2018 - [info]  Replication filtering check ok.
Mon Mar 26 22:51:18 2018 - [error][/usr/local/share/perl5/MHA/MasterMonitor.pm, ln427] Error happened on checking configurations. Got MySQL error when checking replication privilege. 29: File './mysql/user.MYD' not found (Errcode: 2 - No such file or directory) query:SELECT Repl_slave_priv AS Value FROM mysql.user WHERE user = ?
 at /usr/local/share/perl5/MHA/Server.pm line 397
Mon Mar 26 22:51:18 2018 - [error][/usr/local/share/perl5/MHA/MasterMonitor.pm, ln525] Error happened on monitoring servers.
Mon Mar 26 22:51:18 2018 - [info] Got exit code 1 (Not master dead).

MySQL Replication Health is NOT OK!
```

检查过程
```
mysql> SELECT Repl_slave_priv AS Value FROM mysql.user WHERE user = 'repluser';
ERROR 29 (HY000): File './mysql/user.MYD' not found (Errcode: 2 - No such file or directory)
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
+--------------------+
1 row in set (0.00 sec)

mysql> exit
```

报错2
```
[root@ai2018 ~]# masterha_check_repl  --conf=/etc/mha/app1/app1.cnf
Mon Mar 26 23:01:44 2018 - [warning] Global configuration file /etc/masterha_default.cnf not found. Skipping.
Mon Mar 26 23:01:44 2018 - [info] Reading application default configuration from /etc/mha/app1/app1.cnf..
Mon Mar 26 23:01:44 2018 - [info] Reading server configuration from /etc/mha/app1/app1.cnf..
Mon Mar 26 23:01:44 2018 - [info] MHA::MasterMonitor version 0.57.
Mon Mar 26 23:01:44 2018 - [info] GTID failover mode = 1
Mon Mar 26 23:01:44 2018 - [info] Dead Servers:
Mon Mar 26 23:01:44 2018 - [info] Alive Servers:
Mon Mar 26 23:01:44 2018 - [info]   192.168.0.175(192.168.0.175:3306)
Mon Mar 26 23:01:44 2018 - [info]   192.168.0.176(192.168.0.176:3306)
Mon Mar 26 23:01:44 2018 - [info]   192.168.0.200(192.168.0.200:3306)
Mon Mar 26 23:01:44 2018 - [info] Alive Slaves:
Mon Mar 26 23:01:44 2018 - [info]   192.168.0.176(192.168.0.176:3306)  Version=5.7.21-log (oldest major version between slaves) log-bin:enabled
Mon Mar 26 23:01:44 2018 - [info]     GTID ON
Mon Mar 26 23:01:44 2018 - [info]     Replicating from 192.168.0.175(192.168.0.175:3306)
Mon Mar 26 23:01:44 2018 - [info]   192.168.0.200(192.168.0.200:3306)  Version=5.7.21-log (oldest major version between slaves) log-bin:enabled
Mon Mar 26 23:01:44 2018 - [info]     GTID ON
Mon Mar 26 23:01:44 2018 - [info]     Replicating from 192.168.0.175(192.168.0.175:3306)
Mon Mar 26 23:01:44 2018 - [info] Current Alive Master: 192.168.0.175(192.168.0.175:3306)
Mon Mar 26 23:01:44 2018 - [info] Checking slave configurations..
Mon Mar 26 23:01:44 2018 - [info]  read_only=1 is not set on slave 192.168.0.200(192.168.0.200:3306).
Mon Mar 26 23:01:44 2018 - [info] Checking replication filtering settings..
Mon Mar 26 23:01:44 2018 - [info]  binlog_do_db= , binlog_ignore_db=
Mon Mar 26 23:01:44 2018 - [info]  Replication filtering check ok.
Mon Mar 26 23:01:44 2018 - [info] GTID (with auto-pos) is supported. Skipping all SSH and Node package checking.
Mon Mar 26 23:01:44 2018 - [info] Checking SSH publickey authentication settings on the current master..
Mon Mar 26 23:01:44 2018 - [info] HealthCheck: SSH to 192.168.0.175 is reachable.
Mon Mar 26 23:01:44 2018 - [info]
192.168.0.175(192.168.0.175:3306) (current master)
 +--192.168.0.176(192.168.0.176:3306)
 +--192.168.0.200(192.168.0.200:3306)

Mon Mar 26 23:01:44 2018 - [info] Checking replication health on 192.168.0.176..
Mon Mar 26 23:01:44 2018 - [info]  ok.
Mon Mar 26 23:01:44 2018 - [info] Checking replication health on 192.168.0.200..
Mon Mar 26 23:01:44 2018 - [info]  ok.
Mon Mar 26 23:01:44 2018 - [info] Checking master_ip_failover_script status:
Mon Mar 26 23:01:44 2018 - [info]   /etc/mha/script/master_ip_failover --command=status --ssh_user=root --orig_master_host=192.168.0.175 --orig_master_ip=192.168.0.175 --orig_master_port=3306  --orig_master_ssh_port=10022
Mon Mar 26 23:01:44 2018 - [error][/usr/local/share/perl5/MHA/MasterMonitor.pm, ln427] Error happened on checking configurations. Can't exec "/etc/mha/script/master_ip_failover": Permission denied at /usr/local/share/perl5/MHA/ManagerUtil.pm line 68.
Mon Mar 26 23:01:44 2018 - [error][/usr/local/share/perl5/MHA/MasterMonitor.pm, ln525] Error happened on monitoring servers.
Mon Mar 26 23:01:44 2018 - [info] Got exit code 1 (Not master dead).

MySQL Replication Health is NOT OK!
Mon Mar 26 23:01:44 2018 - [error][/usr/local/share/perl5/MHA/MasterMonitor.pm, ln229]  Failed to get master_ip_failover_script status with return code 1:0.
Mon Mar 26 23:01:44 2018 - [error][/usr/local/share/perl5/MHA/MasterMonitor.pm, ln427] Error happened on checking configurations.  at /usr/local/bin/masterha_check_repl line 48
Mon Mar 26 23:01:44 2018 - [error][/usr/local/share/perl5/MHA/MasterMonitor.pm, ln525] Error happened on monitoring servers.
Mon Mar 26 23:01:44 2018 - [info] Got exit code 1 (Not master dead).

MySQL Replication Health is NOT OK!
```

正确的设置后,验证通过应该如下:
```
[root@ai2018 ~]# masterha_check_repl  --conf=/etc/mha/app1/app1.cnf
Mon Mar 26 23:02:21 2018 - [warning] Global configuration file /etc/masterha_default.cnf not found. Skipping.
Mon Mar 26 23:02:21 2018 - [info] Reading application default configuration from /etc/mha/app1/app1.cnf..
Mon Mar 26 23:02:21 2018 - [info] Reading server configuration from /etc/mha/app1/app1.cnf..
Mon Mar 26 23:02:21 2018 - [info] MHA::MasterMonitor version 0.57.
Mon Mar 26 23:02:21 2018 - [info] GTID failover mode = 1
Mon Mar 26 23:02:21 2018 - [info] Dead Servers:
Mon Mar 26 23:02:21 2018 - [info] Alive Servers:
Mon Mar 26 23:02:21 2018 - [info]   192.168.0.175(192.168.0.175:3306)
Mon Mar 26 23:02:21 2018 - [info]   192.168.0.176(192.168.0.176:3306)
Mon Mar 26 23:02:21 2018 - [info]   192.168.0.200(192.168.0.200:3306)
Mon Mar 26 23:02:21 2018 - [info] Alive Slaves:
Mon Mar 26 23:02:21 2018 - [info]   192.168.0.176(192.168.0.176:3306)  Version=5.7.21-log (oldest major version between slaves) log-bin:enabled
Mon Mar 26 23:02:21 2018 - [info]     GTID ON
Mon Mar 26 23:02:21 2018 - [info]     Replicating from 192.168.0.175(192.168.0.175:3306)
Mon Mar 26 23:02:21 2018 - [info]   192.168.0.200(192.168.0.200:3306)  Version=5.7.21-log (oldest major version between slaves) log-bin:enabled
Mon Mar 26 23:02:21 2018 - [info]     GTID ON
Mon Mar 26 23:02:21 2018 - [info]     Replicating from 192.168.0.175(192.168.0.175:3306)
Mon Mar 26 23:02:21 2018 - [info] Current Alive Master: 192.168.0.175(192.168.0.175:3306)
Mon Mar 26 23:02:21 2018 - [info] Checking slave configurations..
Mon Mar 26 23:02:21 2018 - [info]  read_only=1 is not set on slave 192.168.0.200(192.168.0.200:3306).
Mon Mar 26 23:02:21 2018 - [info] Checking replication filtering settings..
Mon Mar 26 23:02:21 2018 - [info]  binlog_do_db= , binlog_ignore_db=
Mon Mar 26 23:02:21 2018 - [info]  Replication filtering check ok.
Mon Mar 26 23:02:21 2018 - [info] GTID (with auto-pos) is supported. Skipping all SSH and Node package checking.
Mon Mar 26 23:02:21 2018 - [info] Checking SSH publickey authentication settings on the current master..
Mon Mar 26 23:02:21 2018 - [info] HealthCheck: SSH to 192.168.0.175 is reachable.
Mon Mar 26 23:02:21 2018 - [info]
192.168.0.175(192.168.0.175:3306) (current master)
 +--192.168.0.176(192.168.0.176:3306)
 +--192.168.0.200(192.168.0.200:3306)

Mon Mar 26 23:02:21 2018 - [info] Checking replication health on 192.168.0.176..
Mon Mar 26 23:02:21 2018 - [info]  ok.
Mon Mar 26 23:02:21 2018 - [info] Checking replication health on 192.168.0.200..
Mon Mar 26 23:02:21 2018 - [info]  ok.
Mon Mar 26 23:02:21 2018 - [info] Checking master_ip_failover_script status:
Mon Mar 26 23:02:21 2018 - [info]   /etc/mha/script/master_ip_failover --command=status --ssh_user=root --orig_master_host=192.168.0.175 --orig_master_ip=192.168.0.175 --orig_master_port=3306  --orig_master_ssh_port=10022
Unknown option: orig_master_ssh_port


IN SCRIPT TEST====/sbin/ifconfig eth2:91 down==/sbin/ifconfig eth2:91 192.168.0.177/24===

Checking the Status of the script.. OK
Mon Mar 26 23:02:21 2018 - [info]  OK.
Mon Mar 26 23:02:21 2018 - [warning] shutdown_script is not defined.
Mon Mar 26 23:02:21 2018 - [info] Got exit code 0 (Not master dead).

MySQL Replication Health is OK.
```
#### 2.6 添加虚拟Ip地址
```
[root@nazeebo mysql_data]# ifconfig eth2:91 192.168.0.177/24
[root@nazeebo mysql_data]# ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP qlen 1000
    link/ether 00:50:56:a5:b0:38 brd ff:ff:ff:ff:ff:ff
    inet 192.168.0.175/24 brd 192.168.0.255 scope global eth2
    inet 192.168.0.177/24 brd 192.168.0.255 scope global secondary eth2:91
    inet6 fe80::250:56ff:fea5:b038/64 scope link
       valid_lft forever preferred_lft forever
[root@nazeebo mysql_data]#
```

#### 2.7 切换验证
