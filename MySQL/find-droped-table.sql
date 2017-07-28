恢复被误删的表
前提： mysql开启了bin log日志

1.找到bin log的位置
找到 最近被修改的bin log ：master-bin.00000xxx
如果误删除跨越了好几个binlog，那么找回数据的时候就必须一个个的binlog去找回了

2.将这一段时间所有执行的sql语句存入到 待恢复的 sql文件中。
mysqlbinlog --start-date='2017-07-28 19:00:00' --stop-date='2017-07-28 209:00:00' binlog的位置 > restore_20170728.sql

3. 新建一个临时库，在手工去掉 delete 语句之后
source < restore_20170728.sql	

4.将恢复的表source回原库