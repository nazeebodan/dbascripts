### MySQL的相关地址:
```
https://dev.mysql.com  #社区版主页
https://dev.mysql.com/worklog #内核开发人员专看..
https://dev.mysql.com/downloads/ #社区版下载地址
```


#### MySQL和MySQL cluster是完全两个不一样的东西.  
两者的存储引擎是不一样的东西!  
可以把MySQL cluster想象成一个独立的产品


#### MySQL fabric 是MySQL的一个中间件工具,可以和 MySQL Utilities 配合起来使用
#### MySQL Connectors是一些驱动


#### 注意的问题:  
1.在哪里下载MySQL  
2.linux环境下下载哪一个数据库
- source code   //主要用于研究
- linux generic //绝大多数情况下推荐使用

迅雷下载?

MD5值的校验

install初始化的时候,my.cnf
/etc/my.cnf
/etc/mysql/my.cnf


mysqld_safe 守护进程,保护mysql的能正常进行

bin文件夹


说说my.cnf--实际在生产环境中的安装:


设置环境变量!
export PATH
防止5.5或者5.6的mysql-client 拿去dump 5.6/5.7的数据了
