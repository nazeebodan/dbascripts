--查看数据库版本，建议10.2.0.4以及上
SELECT * FROM v$version;

--查看有哪些组件被载入
SELECT comp_id
  ,  comp_name
  , version
  , DECODE(   status
            , 'VALID',    status 
            , 'INVALID',  status 
            ,status)
  , modified 
  , control
  , schema
  , procedure
FROM dba_registry
ORDER BY comp_name;

--显示数据库高水位的一些统计信息
SELECT name statistic_name,
       version,
       highwater highwater,
       last_value last_value,
       description description
  FROM dba_high_water_mark_statistics
 ORDER BY name;

--查看初始化参数，是否是默认值，以及是否是静态参数
SELECT name,
       instance_name,
       SUBSTR(p.value, 0, 512) value,
       isdefault,
       issys_modifiable
  FROM gv$parameter p, gv$instance i
 WHERE p.inst_id = i.inst_id
 ORDER BY p.name, i.instance_name;

--监控每天每小时的redo的切换次数
SELECT
     SUBSTR(TO_CHAR(first_time, 'MM/DD/RR HH:MI:SS'),1,5)  DAY
  , SUM(DECODE(SUBSTR(TO_CHAR(first_time, 'MM/DD/RR HH24:MI:SS'),10,2),'00',1,0)) H00
  , SUM(DECODE(SUBSTR(TO_CHAR(first_time, 'MM/DD/RR HH24:MI:SS'),10,2),'01',1,0)) H01
  , SUM(DECODE(SUBSTR(TO_CHAR(first_time, 'MM/DD/RR HH24:MI:SS'),10,2),'02',1,0)) H02
  , SUM(DECODE(SUBSTR(TO_CHAR(first_time, 'MM/DD/RR HH24:MI:SS'),10,2),'03',1,0)) H03
  , SUM(DECODE(SUBSTR(TO_CHAR(first_time, 'MM/DD/RR HH24:MI:SS'),10,2),'04',1,0)) H04
  , SUM(DECODE(SUBSTR(TO_CHAR(first_time, 'MM/DD/RR HH24:MI:SS'),10,2),'05',1,0)) H05
  , SUM(DECODE(SUBSTR(TO_CHAR(first_time, 'MM/DD/RR HH24:MI:SS'),10,2),'06',1,0)) H06
  , SUM(DECODE(SUBSTR(TO_CHAR(first_time, 'MM/DD/RR HH24:MI:SS'),10,2),'07',1,0)) H07
  , SUM(DECODE(SUBSTR(TO_CHAR(first_time, 'MM/DD/RR HH24:MI:SS'),10,2),'08',1,0)) H08
  , SUM(DECODE(SUBSTR(TO_CHAR(first_time, 'MM/DD/RR HH24:MI:SS'),10,2),'09',1,0)) H09
  , SUM(DECODE(SUBSTR(TO_CHAR(first_time, 'MM/DD/RR HH24:MI:SS'),10,2),'10',1,0)) H10
  , SUM(DECODE(SUBSTR(TO_CHAR(first_time, 'MM/DD/RR HH24:MI:SS'),10,2),'11',1,0)) H11
  , SUM(DECODE(SUBSTR(TO_CHAR(first_time, 'MM/DD/RR HH24:MI:SS'),10,2),'12',1,0)) H12
  , SUM(DECODE(SUBSTR(TO_CHAR(first_time, 'MM/DD/RR HH24:MI:SS'),10,2),'13',1,0)) H13
  , SUM(DECODE(SUBSTR(TO_CHAR(first_time, 'MM/DD/RR HH24:MI:SS'),10,2),'14',1,0)) H14
  , SUM(DECODE(SUBSTR(TO_CHAR(first_time, 'MM/DD/RR HH24:MI:SS'),10,2),'15',1,0)) H15
  , SUM(DECODE(SUBSTR(TO_CHAR(first_time, 'MM/DD/RR HH24:MI:SS'),10,2),'16',1,0)) H16
  , SUM(DECODE(SUBSTR(TO_CHAR(first_time, 'MM/DD/RR HH24:MI:SS'),10,2),'17',1,0)) H17
  , SUM(DECODE(SUBSTR(TO_CHAR(first_time, 'MM/DD/RR HH24:MI:SS'),10,2),'18',1,0)) H18
  , SUM(DECODE(SUBSTR(TO_CHAR(first_time, 'MM/DD/RR HH24:MI:SS'),10,2),'19',1,0)) H19
  , SUM(DECODE(SUBSTR(TO_CHAR(first_time, 'MM/DD/RR HH24:MI:SS'),10,2),'20',1,0)) H20
  , SUM(DECODE(SUBSTR(TO_CHAR(first_time, 'MM/DD/RR HH24:MI:SS'),10,2),'21',1,0)) H21
  , SUM(DECODE(SUBSTR(TO_CHAR(first_time, 'MM/DD/RR HH24:MI:SS'),10,2),'22',1,0)) H22
  , SUM(DECODE(SUBSTR(TO_CHAR(first_time, 'MM/DD/RR HH24:MI:SS'),10,2),'23',1,0)) H23
  , COUNT(*)                                                                      TOTAL
FROM
  v$log_history  a
GROUP BY SUBSTR(TO_CHAR(first_time, 'MM/DD/RR HH:MI:SS'),1,5)
ORDER BY SUBSTR(TO_CHAR(first_time, 'MM/DD/RR HH:MI:SS'),1,5)；

--监控表空间的创建方式以及使用情况
SELECT status,
       d.tablespace_name name,
       d.contents type,
       d.extent_management extent_mgt,
       d.segment_space_management segment_mgt,
       NVL(a.bytes, 0) ts_size,
       NVL(f.bytes, 0) free,
       NVL(a.bytes - NVL(f.bytes, 0), 0) used,
       DECODE((1 - SIGN(1 - SIGN(TRUNC(NVL((a.bytes - NVL(f.bytes, 0)) /
                                           a.bytes * 100,
                                           0)) - 90))),
              1,
              TO_CHAR(TRUNC(NVL((a.bytes - NVL(f.bytes, 0)) / a.bytes * 100,
                                0)))) pct_used
  FROM sys.dba_tablespaces d,
       (select tablespace_name, sum(bytes) bytes
          from dba_data_files
         group by tablespace_name) a,
       (select tablespace_name, sum(bytes) bytes
          from dba_free_space
         group by tablespace_name) f
 WHERE d.tablespace_name = a.tablespace_name(+)
   AND d.tablespace_name = f.tablespace_name(+)
   AND NOT
        (d.extent_management like 'LOCAL' AND d.contents like 'TEMPORARY')
UNION ALL
SELECT d.status status,
       d.tablespace_name name,
       d.contents type,
       d.extent_management extent_mgt,
       d.segment_space_management segment_mgt,
       NVL(a.bytes, 0) ts_size,
       NVL(a.bytes - NVL(t.bytes, 0), 0) free,
       NVL(t.bytes, 0) used,
       DECODE((1 -
              SIGN(1 - SIGN(TRUNC(NVL(t.bytes / a.bytes * 100, 0)) - 90))),
              1,
              TO_CHAR(TRUNC(NVL(t.bytes / a.bytes * 100, 0)))) pct_used
  FROM sys.dba_tablespaces d,
       (select tablespace_name, sum(bytes) bytes
          from dba_temp_files
         group by tablespace_name) a,
       (select tablespace_name, sum(bytes_cached) bytes
          from v$temp_extent_pool
         group by tablespace_name) t
 WHERE d.tablespace_name = a.tablespace_name(+)
   AND d.tablespace_name = t.tablespace_name(+)
   AND d.extent_management like 'LOCAL'
   AND d.contents like 'TEMPORARY'
 ORDER BY 2;

--查看rman的配置情况
SELECT name, value FROM v$rman_configuration ORDER BY name;

--查看rman的备份集情况
SELECT bs.recid bs_key,
       DECODE(backup_type,
              'L',
              'Archived Redo Logs',
              'D',
              'Datafile Full Backup',
              'I',
              'Incremental Backup') backup_type,
       device_type,
       DECODE(bs.controlfile_included, 'NO', '-', bs.controlfile_included) controlfile_included,
       NVL(sp.spfile_included, '-') spfile_included,
       bs.incremental_level incremental_level,
       bs.pieces pieces,
       TO_CHAR(bs.start_time, 'mm/dd/yyyy HH24:MI:SS') start_time,
       TO_CHAR(bs.completion_time, 'mm/dd/yyyy HH24:MI:SS') completion_time,
       bs.elapsed_seconds elapsed_seconds,
       bp.tag tag,
       bs.block_size block_size,
       bs.keep keep,
       NVL(TO_CHAR(bs.keep_until, 'mm/dd/yyyy HH24:MI:SS'), '<br>') keep_until,
       bs.keep_options keep_options
  FROM v$backup_set bs,
       (select distinct set_stamp, set_count, tag, device_type
          from v$backup_piece
         where status in ('A', 'X')) bp,
       (select distinct set_stamp, set_count, 'YES' spfile_included
          from v$backup_spfile) sp
 WHERE bs.set_stamp = bp.set_stamp
   AND bs.set_count = bp.set_count
   AND bs.set_stamp = sp.set_stamp(+)
   AND bs.set_count = sp.set_count(+)
 ORDER BY bs.recid;

--查看rman的备份片情况
SELECT bs.recid  bs_key,
       bp.piece# piece#,
       bp.copy#  copy#,
       bp.recid  bp_key,       
       DECODE(bs.controlfile_included, 'NO', '-', bs.controlfile_included) controlfile_included,
       status,
       handle handle
  FROM v$backup_set bs, v$backup_piece bp
 WHERE bs.set_stamp = bp.set_stamp
   AND bs.set_count = bp.set_count
   AND bp.status IN ('A', 'X')
   AND bs.controlfile_included != 'NO'
 ORDER BY bs.recid, piece#;

--查看数据库闪回的状态
SELECT TO_CHAR(oldest_flashback_time, 'mm/dd/yyyy HH24:MI:SS') oldest_flashback_time,
       oldest_flashback_scn oldest_flashback_scn,
       retention_target retention_target,
       retention_target / 60 retention_target_hours,
       flashback_size flashback_size,
       estimated_flashback_size estimated_flashback_size
  FROM v$flashback_database_log
 ORDER BY 1;
 
--查看sga_max_size和sga_target参数值，确定设置的sga的大小和使用的大小
--数据库使用内存不超过总内存的80%(其中包括Oracle各进程使用的内存、SGA占用大小、进程的pga使用的内存、ASM使用的内存)
select name, to_char(round(value / 1024 / 1024,2)) || ' (MB)' value, isdefault
  from v$parameter
 where name = 'sga_max_size'
union
select name, to_char(round(value / 1024 / 1024,2)) || ' (MB)' value, isdefault
  from v$parameter
 where name = 'sga_target';


--查看sga的分配情况
SELECT i.instance_name instance_name, s.name, s.value
  FROM gv$sga s, gv$instance i
 WHERE s.inst_id = i.inst_id
 ORDER BY i.instance_name, s.value DESC;

--查看sga各组件情况
SELECT i.instance_name,
       sdc.component,
       sdc.current_size,
       sdc.min_size,
       sdc.max_size,
       sdc.user_specified_size,
       sdc.oper_count,
       sdc.last_oper_type,
       sdc.last_oper_mode,       
       NVL(TO_CHAR(sdc.last_oper_time, 'mm/dd/yyyy HH24:MI:SS'), '<br>') last_oper_time,
       sdc.granule_size
  FROM gv$sga_dynamic_components sdc, gv$instance i
 ORDER BY i.instance_name, sdc.component DESC;
 
--pga设置情况
SELECT i.instance_name,
       p.name name,
       (CASE p.name
         WHEN 'pga_aggregate_target' THEN
          TO_CHAR(p.value, '999,999,999,999,999')
         ELSE
          p.value
       END) value
  FROM gv$parameter p, gv$instance i
 WHERE p.inst_id = i.inst_id
   AND p.name IN ('pga_aggregate_target', 'workarea_size_policy')
 ORDER BY i.instance_name, p.name;
 
--pga大小建议
SELECT i.instance_name,
       p.pga_target_for_estimate,
       p.estd_extra_bytes_rw,
       p.estd_pga_cache_hit_percentage,
       p.estd_overalloc_count
  FROM gv$pga_target_advice p, gv$instance i
 WHERE p.inst_id = i.inst_id
 ORDER BY i.instance_name, p.pga_target_for_estimate;
 
--I/O读写状态统计
SELECT df.tablespace_name tablespace_name,
       df.file_name       fname,
       fs.phyrds          phyrds,
       
       ROUND((fs.phyrds * 100) / (fst.pr + tst.pr), 2) || '%' read_pct,
       fs.phywrts phywrts,
       
       ROUND((fs.phywrts * 100) / (fst.pw + tst.pw), 2) || '%' write_pct,
       (fs.phyrds + fs.phywrts) total_io
  FROM sys.dba_data_files df,
       v$filestat fs,
       (select sum(f.phyrds) pr, sum(f.phywrts) pw from v$filestat f) fst,
       (select sum(t.phyrds) pr, sum(t.phywrts) pw from v$tempstat t) tst
 WHERE df.file_id = fs.file#
UNION
SELECT tf.tablespace_name tablespace_name,
       tf.file_name       fname,
       ts.phyrds          phyrds,
       
       ROUND((ts.phyrds * 100) / (fst.pr + tst.pr), 2) || '%' read_pct,
       ts.phywrts phywrts,
       
       ROUND((ts.phywrts * 100) / (fst.pw + tst.pw), 2) || '%' write_pct,
       (ts.phyrds + ts.phywrts) total_io
  FROM sys.dba_temp_files tf,
       v$tempstat ts,
       (select sum(f.phyrds) pr, sum(f.phywrts) pw from v$filestat f) fst,
       (select sum(t.phyrds) pr, sum(t.phywrts) pw from v$tempstat t) tst
 WHERE tf.file_id = ts.file#
 ORDER BY phyrds DESC;

--全表扫描中，大表的比例
SELECT a.value large_table_scans,
       b.value small_table_scans,
      
       ROUND(100 * a.value /
             DECODE((a.value + b.value), 0, 1, (a.value + b.value)),
             2) || '%' pct_large_scans
  FROM v$sysstat a, v$sysstat b
 WHERE a.name = 'table scans (long tables)'
   AND b.name = 'table scans (short tables)';

--排序中，磁盘和内存排序的比例
SELECT a.value disk_sorts,
       b.value memory_sorts,
       ROUND(100 * a.value /
             DECODE((a.value + b.value), 0, 1, (a.value + b.value)),
             2) || '%' pct_disk_sorts
  FROM v$sysstat a, v$sysstat b
 WHERE a.name = 'sorts (disk)'
   AND b.name = 'sorts (memory)';

--逻辑读排名靠前的20个sql
/*SELECT UPPER(b.username) username,
       a.buffer_gets buffer_gets,
       a.executions executions,
       (a.buffer_gets / decode(a.executions, 0, 1, a.executions)) gets_per_exec,
       a.sql_text sql_text
  FROM (SELECT ai.buffer_gets,
               ai.executions,
               ai.sql_text,
               ai.parsing_user_id
          FROM sys.v_$sqlarea ai
         ORDER BY ai.buffer_gets) a,
       dba_users b
 WHERE a.parsing_user_id = b.user_id
   AND a.buffer_gets > 1000
   AND b.username NOT IN ('SYS', 'SYSTEM','SYSMAN')
   AND rownum < 20
 ORDER BY a.buffer_gets DESC;*/

--物理读排名靠前的20个sql
/*SELECT UPPER(b.username)  username,
       a.disk_reads disk_reads,
       a.executions executions,
       (a.disk_reads / decode(a.executions, 0, 1, a.executions)) reads_per_exec,
       a.sql_text sql_text
  FROM (SELECT ai.disk_reads, ai.executions, ai.sql_text, ai.parsing_user_id
          FROM sys.v_$sqlarea ai
         ORDER BY ai.buffer_gets) a,
       dba_users b
 WHERE a.parsing_user_id = b.user_id
   AND a.disk_reads > 1000
   AND b.username NOT IN ('SYS', 'SYSTEM','SYSMAN')
   AND rownum < 20
 ORDER BY a.disk_reads DESC;*/

--用户数模型
SELECT  i.instance_name ,
       i.thread#,
      NVL(sess.username, '[B.G. Process]') username,
       count(*) num_user_sess,
       NVL(act.count, 0) count_a,
       NVL(inact.count, 0) count_i,
       NVL(killed.count, 0) count_k
  FROM gv$session sess,
       gv$instance i,
       (SELECT count(*) count,
               NVL(username, '[B.G. Process]') username,
               inst_id
          FROM gv$session
         WHERE status = 'ACTIVE'
         GROUP BY username, inst_id) act,
       (SELECT count(*) count,
               NVL(username, '[B.G. Process]') username,
               inst_id
          FROM gv$session
         WHERE status = 'INACTIVE'
         GROUP BY username, inst_id) inact,
       (SELECT count(*) count,
               NVL(username, '[B.G. Process]') username,
               inst_id
          FROM gv$session
         WHERE status = 'KILLED'
         GROUP BY username, inst_id) killed
 WHERE sess.inst_id = i.inst_id
   AND (NVL(sess.username, '[B.G. Process]') = act.username(+) AND
       sess.inst_id = act.inst_id(+))
   AND (NVL(sess.username, '[B.G. Process]') = inact.username(+) AND
       sess.inst_id = inact.inst_id(+))
   AND (NVL(sess.username, '[B.G. Process]') = killed.username(+) AND
       sess.inst_id = killed.inst_id(+))
   AND sess.username NOT IN ('SYS')
 GROUP BY i.instance_name,
          i.thread#,
          sess.username,
          act.count,
          inact.count,
          killed.count
 ORDER BY i.instance_name, i.thread#, sess.username;

--监控用户状态
SELECT distinct a.username username,
                a.account_status,
                expiry_date,
                a.default_tablespace default_tablespace,
                a.temporary_tablespace temporary_tablespace,
                a.created,
                a.profile profile,
                sysdba,
                sysoper
  FROM dba_users a, v$pwfile_users p
 WHERE p.username(+) = a.username
 ORDER BY username;

--监控哪些用户有dba权限
SELECT grantee, granted_role, admin_option, default_role
  FROM dba_role_privs
 WHERE granted_role = 'DBA'
 ORDER BY grantee, granted_role;

--监控用户的各种对象数
SELECT owner, object_type object_type, count(*) obj_count
  FROM dba_objects
 GROUP BY owner, object_type
 ORDER BY owner, object_type;

--监控无效的对象
SELECT  owner,
       object_name,
       object_type,
        status
  FROM dba_objects
 WHERE status <> 'VALID'
 ORDER BY owner, object_name;

--监控资源使用情况
select inst_id,
       resource_name,
       current_utilization,
       max_utilization,
       initial_allocation,
       limit_value
  from gv$resource_limit
 where ltrim(rtrim(limit_value)) != 'UNLIMITED'
 order by inst_id;

--软解析命中率,90%以上,过低的话表示系统中可能有大量的硬解析：
select round((1 - s1.VALUE / s2.VALUE) * 100, 2) "soft_parse%"
  from v$sysstat s1, v$sysstat s2
 where s1.name = 'parse count (hard)'
   and s2.name = 'parse count (total)';
   
--pga命中率检查，如果不是100%表示一部分排序或者连接操作在非内存区域完成
select inst_id,value from gv$pgastat where name='cache hit percentage';

--重做日志缓冲区命中率检查95%以上，如果该值过小表示日志缓冲区过小或者事务提交过于频繁，或者系统IO写存在性能瓶颈：
SELECT a.inst_id,
       a.VALUE redo_entries,
       b.VALUE redo_buffer_allocation_retries,
       ROUND((1 - b.VALUE / a.VALUE) * 100, 4) log_buffer_ratio
  FROM gv$sysstat a, gv$sysstat b
 WHERE a.NAME = 'redo entries'
   AND b.NAME = 'redo buffer allocation retries';
   
--缓冲区命中率95%以上，如果该值过小表明有大量的全表扫描或者SGA太小频繁的换入换出：
SELECT inst_id,
       physical_reads,
       db_block_gets,
       consistent_gets,
       NAME,
       100 * (1 - (physical_reads /
       (consistent_gets + db_block_gets - physical_reads))) "Data Buffer Hit Ratio"
  FROM gv$buffer_pool_statistics
 order by inst_id;

--检查数据字典缓冲区90%以上，如果是稳定的系统这个值应该是非常稳定的，如果出现过低说明shared pool值过小，或者有频繁的DDL操作：
SELECT inst_id, SUM(pinhits) / SUM(pins) * 100 "hit radio"
  FROM gv$librarycache
 group by inst_id
 order by inst_id;

--检查库缓冲区命令率95%以上，如果该值过小表明空间过小或者有大量SQL的硬解析存在：
SELECT inst_id,
       TO_CHAR(ROUND((1 - SUM(getmisses) / SUM(gets)) * 100, 1)) || '%' "Dictionary Cache Hit Ratio"
  FROM gv$rowcache
 group by inst_id
 order by inst_id;

--排序命中率检查100%,如果值过小表明排序工作一部分不在内存中完成
SELECT inst_id,
       a.VALUE disk_sort,
       b.VALUE memory_sort,
       ROUND((1 - a.VALUE / (a.VALUE + b.VALUE)) * 100, 4) sort_ratio
  FROM gv$sysstat a, v$sysstat b
 WHERE a.NAME = 'sorts (disk)'
   AND b.NAME = 'sorts (memory)';
   
--系统等待事件排名前五：
select *
  from (select *
          from gv$system_event
         where wait_class <> 'Idle'
         order by total_waits desc)
 where rownum < 6 order by inst_id;

--系统latch排名前五：
select *
  from (select inst_id, name, hash, gets, spin_gets
          from gv$latch
         order by sleeps, spin_gets desc)
 where rownum < 6
 order by inst_id;
 
--sql执行时间排名前五：
 select *
   from (select inst_id,
                sql_text,
                sql_id,
                sharable_mem,
                persistent_mem,
                version_count,
                executions,
                disk_reads,
                direct_writes,
                buffer_gets,
                cpu_time,
                elapsed_time
           from gv$sqlarea
          order by elapsed_time desc)
  where rownum < 6
  order by inst_id;

--cpu消耗排名前五：
 select *
   from (select inst_id,
                sql_text,
                sql_id,
                sharable_mem,
                persistent_mem,
                version_count,
                executions,
                disk_reads,
                direct_writes,
                buffer_gets,
                cpu_time,
                elapsed_time
           from gv$sqlarea
          order by cpu_time desc)
  where rownum < 6
  order by inst_id;
  
--sql逻辑读排名前五：
select inst_id, sql_text, buffer_gets
  from (select inst_id,
               sql_text,
               buffer_gets,
               dense_rank() over(order by buffer_gets desc) buffer_gets_rank
          from gv$sql)
 where buffer_gets_rank <= 5
 order by inst_id;
 
--sql物理读排名前五：
select inst_id, sql_text, disk_reads
  from (select inst_id,
               sql_text,
               disk_reads,
               dense_rank() over(order by disk_reads desc) disk_reads_rank
          from gv$sql)
 where disk_reads_rank <= 5
 order by inst_id;

--sql执行次数排名前五：
select inst_id, sql_text, executions
  from (select inst_id,
               sql_text,
               executions,
               rank() over(order by executions desc) exec_rank
          from gv$sql)
 where exec_rank <= 5
 order by inst_id;
 
--sql版本排名前五：
select *
  from (select v1.INST_ID, v1.sql_id, v1.VERSION_COUNT
          from gv$sqlarea v1
         where v1.parsing_schema_name not in ('SYS', 'SYSTEM', 'SYSMAN')
         order by v1.VERSION_COUNT desc)
 where rownum <= 5;

--sql执行次数等于1表示sql可能未绑定变量，存在硬解析的情况：
select inst_id, count(1)
  from gv$sqlarea
 where executions = 1
   and parsing_schema_name not in ('SYS', 'SYSTEM', 'SYSMAN')
 group by inst_id;
