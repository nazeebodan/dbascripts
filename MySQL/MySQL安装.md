### 1.下载二进制包
https://dev.mysql.com/downloads/mysql/  
linux操作系统下,下载linux-generic

<kbd>注意! 不要用自己编译的!直接用编译好的版本即可!!!</kbd>

### 2.阅读官方的安装文档
#### 大致的步骤如下:
```
shell> groupadd mysql
shell> useradd -r -g mysql -s /bin/false mysql
shell> cd /usr/local
shell> tar zxvf /path/to/mysql-VERSION-OS.tar.gz
shell> ln -s full-path-to-mysql-VERSION-OS mysql
shell> cd mysql
shell> mkdir mysql-files
shell> chown mysql:mysql mysql-files
shell> chmod 750 mysql-files
shell> bin/mysqld --initialize --user=mysql
shell> bin/mysql_ssl_rsa_setup              
shell> bin/mysqld_safe --user=mysql &
# Next command is optional
shell> cp support-files/mysql.server /etc/init.d/mysql.server
```

### 3.安装依赖包
MySQL依赖于libaio 库。如果这个库没有在本地安装, 数据目录初始化和后续的服务器启动步骤将会失败。  
故需要先将这个包安装上去.
```
shell> yum install libaio
```

### 4.创建mysql用户和用户组
```
shell> groupadd mysql
shell> useradd -r -g mysql -s /bin/false mysql
```
<kbd>因为只想让mysql用户仅用于运行mysql服务，而不是登录；此使用useradd -r和-s /bin/false的命令选项来创建对服务器主机没有登录权限的用户。</kbd>

### 5.解压到指定的目录
```
shell> cd /usr/local
shell> tar zxvf /path/to/mysql-VERSION-OS.tar.gz
shell> ln -s full-path-to-mysql-VERSION-OS mysql
```

### 6.配置数据库目录
```
数据目录：/u01/mysql/mysql_data
参数文件my.cnf：/etc/my.cnf
错误日志log-error：/u01/mysql/log/mysql_error.log
二进制日志log-bin：/u01/mysql/log/mysql_bin.log
慢查询日志slow_query_log_file：/u01/mysql/log/mysql_slow_query.log
```

```
mkdir -p /u01/mysql/{mysql_data }
chown -R mysql.mysql /u01/mysql
```

### 7.配置my.cnf
my.cnf的内容,建议如下:
```
[mysqld]
########basic settings########
server-id = 11
port = 3306
user = mysql
#bind_address = 192.168.0.175
#autocommit = 0
character_set_server=utf8mb4
skip_name_resolve = 1
max_connections = 800
max_connect_errors = 1000
datadir = /u01/mysql/mysql_data/
transaction_isolation = READ-COMMITTED
explicit_defaults_for_timestamp = 1
join_buffer_size = 134217728
tmp_table_size = 67108864
tmpdir = /tmp
max_allowed_packet = 16777216
sql_mode = "STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER"
interactive_timeout = 1800
wait_timeout = 1800
read_buffer_size = 16777216
read_rnd_buffer_size = 33554432
sort_buffer_size = 33554432
########log settings########
log_error = /u01/mysql/log/mysql_error.log
slow_query_log = 1
slow_query_log_file = /u01/mysql/log/mysql_slow_query.log
log_queries_not_using_indexes = 1
log_slow_admin_statements = 1
log_slow_slave_statements = 1
log_throttle_queries_not_using_indexes = 10
expire_logs_days = 90
long_query_time = 2
min_examined_row_limit = 100
########replication settings########
master_info_repository = TABLE
relay_log_info_repository = TABLE
log_bin = bin.log
sync_binlog = 1
gtid_mode = on
enforce_gtid_consistency = 1
log_slave_updates
binlog_format = row
relay_log = relay.log
relay_log_recovery = 1
binlog_gtid_simple_recovery = 1
slave_skip_errors = ddl_exist_errors
########innodb settings########
innodb_page_size = 8192
innodb_buffer_pool_size = 4G
innodb_buffer_pool_instances = 8
innodb_buffer_pool_load_at_startup = 1
innodb_buffer_pool_dump_at_shutdown = 1
innodb_lru_scan_depth = 2000
innodb_lock_wait_timeout = 5
innodb_io_capacity = 4000
innodb_io_capacity_max = 8000
innodb_flush_method = O_DIRECT
innodb_file_format = Barracuda
innodb_file_format_max = Barracuda
innodb_log_group_home_dir = /u01/mysql/mysql_redolog/
innodb_undo_directory = /u01/mysql/mysql_undolog/
innodb_undo_logs = 128
innodb_undo_tablespaces = 3
innodb_flush_neighbors = 1
innodb_log_file_size = 1G   #注意,生产环境建议调成4G+
innodb_log_buffer_size = 16777216
innodb_purge_threads = 4
innodb_large_prefix = 1
innodb_thread_concurrency = 64
innodb_print_all_deadlocks = 1
innodb_strict_mode = 1
innodb_sort_buffer_size = 67108864
########semi sync replication settings########
plugin_dir=/usr/local/mysql/lib/plugin
plugin_load = "rpl_semi_sync_master=semisync_master.so;rpl_semi_sync_slave=semisync_slave.so"
loose_rpl_semi_sync_master_enabled = 1
loose_rpl_semi_sync_slave_enabled = 1
loose_rpl_semi_sync_master_timeout = 5000

[mysqld-5.7]
innodb_buffer_pool_dump_pct = 40
innodb_page_cleaners = 4
innodb_undo_log_truncate = 1
innodb_max_undo_log_size = 2G
innodb_purge_rseg_truncate_frequency = 128
binlog_gtid_simple_recovery=1
log_timestamps=system
transaction_write_set_extraction=MURMUR32
show_compatibility_56=on
```

### 8.初始化
需要注意的一个地方是:5.7较5.6的改进和替换的脚本
```
bin/mysqld --initialize --user=mysql  
```
可以在error.log日志中找到
```
shell> grep 'temporary password' /u01/mysql/log/mysql_error.log
```
生成ssl
```
shell> mysql_ssl_rsa_setup --basedir=/opt/mysql-5.7.21 --datadir=/opt/mysql-5.7.21/data/
```

### 9.配置服务
```
[root@nazeebo mysql]# cp support-files/mysql.server /etc/init.d/suremysql
[root@nazeebo mysql]# chkconfig --add suremysql
[root@nazeebo mysql]# chkconfig --list
```

### 10.启动服务
```
[root@nazeebo mysql]# service suremysql start
Starting MySQL...                                          [  OK  ]
[root@nazeebo mysql]# ps -ef | grep mysql
root       333     1  1 15:32 pts/2    00:00:00 /bin/sh /usr/local/mysql/bin/mysqld_safe --datadir=/u01/mysql/mysql_data/ --pid-file=/u01/mysql/mysql_data//nazeebo.pid
mysql     1300   333 33 15:32 pts/2    00:00:01 /usr/local/mysql/bin/mysqld --basedir=/usr/local/mysql --datadir=/u01/mysql/mysql_data --plugin-dir=/usr/local/mysql/lib/plugin --user=mysql --log-error=/u01/mysql/log/mysql_error.log --pid-file=/u01/mysql/mysql_data//nazeebo.pid --port=3306
root      1345 32073  0 15:32 pts/2    00:00:00 grep mysql
root     32697 32371  0 15:28 pts/3    00:00:00 tail -f mysql_error.log
```

### 11.配置环境变量
在/etc/profile 中加入:
export PATH=$PATH:/usr/local/mysql/bin

### 12.进行安全的配置
```
[root@nazeebo bin]# mysql_secure_installation

Securing the MySQL server deployment.

Enter password for user root:

The existing password for the user account root has expired. Please set a new password.

New password:

Re-enter new password:

VALIDATE PASSWORD PLUGIN can be used to test passwords
and improve security. It checks the strength of password
and allows the users to set only those passwords which are
secure enough. Would you like to setup VALIDATE PASSWORD plugin?

Press y|Y for Yes, any other key for No: y

There are three levels of password validation policy:

LOW    Length >= 8
MEDIUM Length >= 8, numeric, mixed case, and special characters
STRONG Length >= 8, numeric, mixed case, special characters and dictionary                  file

Please enter 0 = LOW, 1 = MEDIUM and 2 = STRONG: 0
Using existing password for root.

Estimated strength of the password: 100
Change the password for root ? ((Press y|Y for Yes, any other key for No) : no

 ... skipping.
By default, a MySQL installation has an anonymous user,
allowing anyone to log into MySQL without having to have
a user account created for them. This is intended only for
testing, and to make the installation go a bit smoother.
You should remove them before moving into a production
environment.

Remove anonymous users? (Press y|Y for Yes, any other key for No) : y
Success.


Normally, root should only be allowed to connect from
'localhost'. This ensures that someone cannot guess at
the root password from the network.

Disallow root login remotely? (Press y|Y for Yes, any other key for No) : y
Success.

By default, MySQL comes with a database named 'test' that
anyone can access. This is also intended only for testing,
and should be removed before moving into a production
environment.


Remove test database and access to it? (Press y|Y for Yes, any other key for No) : y
 - Dropping test database...
Success.

 - Removing privileges on test database...
Success.

Reloading the privilege tables will ensure that all changes
made so far will take effect immediately.

Reload privilege tables now? (Press y|Y for Yes, any other key for No) : y
Success.

All done!
```

###  13.将时区导入mysql数据库
```
shell> mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root -p mysql
```
> 说明:  
> mysql内部有一个时区变量time_zone，会影响函数NOW()与CURTIME()的显示，而且会影响TIMESTAMP列的存储，因为TIMESTAMP列的值在存储时会从当前时区转换到UTC，取数据时再从UTC转换为当前时区。
time_zone的默认值时System，也可以设置为'+10:00' or '-8:00'.意思是与UTC的偏移一样。
如果需要设置为Europe/Helsinki', 'US/Eastern', or 'MET'.之类的名称，需要手动load数据到mysql的time zone information table,命令如上。

### 14.验证安装
```
[root@nazeebo bin]#  mysqladmin version -u root -p
Enter password:
mysqladmin  Ver 8.42 Distrib 5.7.21, for linux-glibc2.12 on x86_64
Copyright (c) 2000, 2018, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Server version		5.7.21-log
Protocol version	10
Connection		Localhost via UNIX socket
UNIX socket		/tmp/mysql.sock
Uptime:			22 min 14 sec

Threads: 1  Questions: 8648  Slow queries: 0  Opens: 121  Flush tables: 1  Open tables: 114  Queries per second avg: 6.482
```

### 参考
> https://dev.mysql.com/doc/refman/5.7/en/binary-installation.html
