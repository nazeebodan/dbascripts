Primary：查询主库的最大日志 
SQL> select max(sequence#) from v$archived_log;
SQL> select max(sequence#) from v$archived_log where applied='YES'; 
 

standby:查询备库的最大日志
SQL> select max(sequence#) from v$archived_log;
SQL> select max(sequence#) from v$archived_log where applied='YES';


查询主库日志与备库是否一致

SQL> select sequence# from v$archived_log  where recid = (select max(recid) from v$archived_log) and applied = 'YES';
SQL> select sequence#  from v$archived_log where recid = (select max(recid) from v$archived_log);

有个最简单的看备库是否和主库一致的方法：
SQL> select max(lh.SEQUENCE#) ,max(al.SEQUENCE#)  fromv$log_history lh,v$archived_log al;
如果2列的值一样，说明同步了.


查主备库的日志是否已经一致了

SELECT SEQUENCE#,APPLIED FROM V$ARCHIVED_LOG ORDER BY SEQUENCE#; 

发现2边的日志数不一致。这个不同步的原因就是日志没有传过去，然后去主库那边OS上看，日志还存在，也就是说是传输过程出的问题。

然后查看主库的归档日志的状态：

SQL> select dest_name,status,error from v$archive_dest where rownum<3;

DEST_NAME STATUS ERROR 
-------------------- --------- -------------------------------
LOG_ARCHIVE_DEST_1 VALID
LOG_ARCHIVE_DEST_2 ERROR ORA-16191: Primary log shipping client not logged on standby

 

发现传向备库的状态是error，报错ora-16191 ,官方文档的说明：

ORA-16191: Primary log shipping client not logged on standby

Cause: An attempt to ship redo to standby without logging on to standby or with invalid user credentials.
Action: Check that primary and standby are using password files and that both primary and standby have the same SYS password. Restart primary and/or standby after ensuring that password file is accessible and REMOTE_LOGIN_PASSWORDFILE initialization parameter is set to SHARED or EXCLUSIVE.



select * from v$archive_gap; 
 select STATUS, GAP_STATUS from V$ARCHIVE_DEST_STATUS where DEST_ID = 2; 



select process,status from v$managed_standby;

检查Standby数据库上是否归档有被应用：
 
在standby 上查看   select process,status from v$managed_standby;       是否出现mrp进程
 
SQL> select process,status from v$managed_standby;
 
PROCESS STATUS
------- ------------
ARCH CONNECTED
ARCH CONNECTED
MRP0 WAIT_FOR_LOG
RFS RECEIVING
 
如果没有MRP进程，说明没有开启为 recover managed standby database状态 ;
 
可以使用  alter database recover managed standby database disconnect from session ； 开standby。
 
MRP就是备库的恢复进程
RFS进程接受从主库来的日志
没有MRP进程，说明你的备库没有处于恢复状态