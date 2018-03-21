sqlplus -prelim "/as sysdba" --当数据库已经很慢或者hang到无法连接

--适用于非RAC
Collection commands for Hanganalyze and Systemstate: Non-RAC:

Hanganalyze
$ sqlplus '/ as sysdba'
SQL> oradebug setmypid
SQL> oradebug unlimit
SQL> oradebug hanganalyze 3
SQL> -- Wait one minute before getting the second hanganalyze(30-60秒)
SQL> oradebug hanganalyze 3
SQL> oradebug tracefile_name
SQL> exit

Systemstate
$ sqlplus '/ as sysdba'
SQL> oradebug setmypid
SQL> oradebug unlimit
SQL> oradebug dump systemstate 266
SQL> oradebug dump systemstate 266
SQL> oradebug tracefile_name
SQL> exit

--适用于RAC
Collection commands for Hanganalyze and Systemstate: RAC
可能会出现2个bug： RAC with fixes for bug 11800959.8 and bug 11827088.8，在11.2.0.3已经修复
For 11g:
$ sqlplus '/ as sysdba'
SQL> oradebug setorapname reco
SQL> oradebug  unlimit
SQL> oradebug -g all hanganalyze 3
SQL> oradebug -g all hanganalyze 3
SQL> oradebug -g all dump systemstate 266
SQL> oradebug -g all dump systemstate 266
SQL> exit


$ sqlplus '/ as sysdba'
SQL> oradebug setorapname reco
oSQL> radebug unlimit
SQL> oradebug -g all hanganalyze 3
SQL> oradebug -g all hanganalyze 3
SQL> oradebug -g all dump systemstate 258
SQL> oradebug -g all dump systemstate 258
SQL> exit


For 10g, run oradebug setmypid instead of oradebug setorapname reco:
$ sqlplus '/ as sysdba'
SQL> oradebug setmypid
SQL> oradebug unlimit
SQL> oradebug -g all hanganalyze 3
SQL> oradebug -g all hanganalyze 3
SQL> oradebug -g all dump systemstate 258
SQL> oradebug -g all dump systemstate 258
SQL> exit

In RAC environment, a dump will be created for all RAC instances in the DIAG trace file for each instance.

systemstate dump 的级别说明：
2: dump (不包括lock element)
10: dump
11: dump + global cache of RAC
256: short stack （函数堆栈）
258: 256+2 -->short stack +dump(不包括lock element)
266: 256+10 -->short stack+ dump
267: 256+11 -->short stack+ dump + global cache of RAC

/*
level 11和 267会 dump global cache, 会生成较大的trace 文件，一般情况下不推荐。
一般情况下，如果进程不是太多，推荐用266，因为这样可以dump出来进程的函数堆栈，可以用来分析进程在执行什么操作。
但是生成short stack比较耗时，如果进程非常多，比如2000个进程，那么可能耗时30分钟以上。
*/

这种情况下，可以生成level 10 或者 level 258， level 258 比 level 10会多收集short short stack, 但比level 10少收集一些lock element data。