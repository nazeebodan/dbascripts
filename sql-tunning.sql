
1.SELECT TABLE_NAME,--表名
       BLOCKS,--总的块数
       EMPTY_BLOCKS,--空块数
       PCT_FREE,--不解释
       NUM_ROWS,--表的行数
       AVG_USED_BLOCKS,--平均使用的块数
       CHAIN_PER,--行迁移OR行链接数
       GREATEST(ROUND(100 * (NVL(HWM - AVG_USED_BLOCKS, 0) /
                      GREATEST(NVL(HWM, 1), 1)),
                      2),
                0) WASTE_PER --浪费的百分比
  FROM (SELECT B.TABLE_NAME,
               A.BLOCKS,
               B.EMPTY_BLOCKS,
               B.PCT_FREE,
               B.NUM_ROWS,               
               (A.BLOCKS - B.EMPTY_BLOCKS - 1) HWM,
               ROUND((B.AVG_ROW_LEN * NUM_ROWS * (1 + (PCT_FREE / 100))) / 8192,
                     0) AS AVG_USED_BLOCKS,
               ROUND(100 *
                     (NVL(B.CHAIN_CNT, 0) / GREATEST(NVL(B.NUM_ROWS, 1), 1)),
                     2) CHAIN_PER
        
          FROM DBA_SEGMENTS A, DBA_TABLES B
         WHERE A.OWNER = B.OWNER
           AND A.SEGMENT_NAME = B.TABLE_NAME
              --AND A.SEGMENT_TYPE = 'TABLE'
           AND A.TABLESPACE_NAME = B.TABLESPACE_NAME
           AND B.TABLESPACE_NAME = '表空间名字')

2.其中的8192可以查DBA_TABLESPACES (TS$)获取
SELECT T.TABLESPACE_NAME,T.BLOCK_SIZE FROM DBA_TABLESPACES T;



3--统计信息不准确或者不确定的情况下使用(真实的基数和选择性)
select count(distinct column_name),
       count(*) total_rows,
       count(distinct column_name) / count(*) * 100 selectivity
  from table_name;
;

4--统计信息准确的情况下使用
select a.column_name,
       b.num_rows,
       a.num_distinct Cardinality,
       round(a.num_distinct / b.num_rows * 100, 2) selectivity,
  from dba_tab_col_statistics a, dba_tables b
 where a.owner = b.owner
   and a.table_name = b.table_name
   and a.owner = upper('&owner')
   and a.table_name = upper('&table_name');
--and a.column_name = upper('&column_name');

5.查看统计信息是否过期呢？可以通过下面SQL查看：
exec dbms_stats.flush_database_monitoring_info;

select owner, table_name name, object_type, stale_stats, last_analyzed
  from dba_tab_statistics
 where table_name in (table_name)
   and owner = 'OWNER_NAME'
   and (stale_stats = 'YES' or last_analyzed is null);
如果上面脚本运行之后返回结果，说明表过期了，如果上面脚本运行之后不返回结果，说明表统计信息没过期。

6.查看表的采样率，可以通过下面SQL查看：
SELECT owner,
       table_name,
       num_rows,
       sample_size,
       trunc(sample_size / num_rows * 100) estimate_percent 
  FROM DBA_TAB_STATISTICS
 WHERE owner='SCOTT' AND table_name='TEST';

做SQL优化第一步 就是 
(1)查看执行计划中的表统计信息是否有过期
(2)如果没过期,查看一下采样率
可以先 explain plan for ....SQL;
然后到 PLAN_TABLE 里面去查询 表名字 
select '''' || object_owner || '''', '''' || object_name || ''','
  from plan_table
 where object_type = 'TABLE'
union
---table in the index---------
select '''' || table_owner || '''', '''' || table_name || '*'','
  from dba_indexes
 where owner in
       (select distinct object_owner from plan_table where rownum > 0)
   and index_name in
       (select distinct object_name from plan_table where rownum > 0)
order by 2;

上面的SQL 就会 输出 你 一个 大SQL 用到了 哪些表 
那么 到时候粘贴 这些 输出的 数据  
放入到刚才脚本中 

7.select *
  from ( select a.parsing_schema_name,
               sum(a.executions_delta) executions,
               sum(a.DISK_READS_delta) disk_reads,
               sum(a.DIRECT_WRITES_delta) direct_writes,
               sum(a.CPU_TIME_delta) / 1000000 / 60 cpu_time_min,
               sum(a.ELAPSED_TIME_delta) / 1000000 / 60 elapsed_time_min,
               sum(a.PHYSICAL_READ_BYTES_delta) / 1024 / 1024 / 1024 physical_read_gb,
               sum(a.physical_write_bytes_delta) / 1024 / 1024 / 1024 physical_write_gb,
               ( select sql_text
                  from dba_hist_sqltext c
                 where c.sql_id = a.sql_id
                   and rownum = 1)
          from DBA_HIST_SQLSTAT a, DBA_HIST_SNAPSHOT b
         where a.SNAP_ID = b.SNAP_ID
           and b.BEGIN_INTERVAL_TIME >=
               to_date( '2012-11-28 00:00:00', 'YYYY-MM-DD HH24:MI:SS' ) ---开始时间   
           and END_INTERVAL_TIME <=
               to_date( '2012-11-28 23:00:00', 'YYYY-MM-DD HH24:MI:SS' ) ---结束时间 
         group by parsing_schema_name, a.sql_id
         order by 3 desc)
 where rownum <= 50 ;

8.查询上一次统计信息收集以来到现在的DML次数,如果收集了统计信息了,那么就清空了.
select *
  from (select *
          from (select *
                  from (select u.name owner,
                               o.name table_name,
                               null partition_name,
                               null subpartition_name,
                               m.inserts,
                               m.updates,
                               m.deletes,
                               m.timestamp,
                               decode(bitand(m.flags, 1), 1, 'YES', 'NO') truncated,
                               m.drop_segments
                          from sys.mon_mods_all$ m,
                               sys.obj$          o,
                               sys.tab$          t,
                               sys.user$         u
                         where o.obj# = m.obj#
                           and o.obj# = t.obj#
                           and o.owner# = u.user#
                        union all
                        select u.name,
                               o.name,
                               o.subname,
                               null,
                               m.inserts,
                               m.updates,
                               m.deletes,
                               m.timestamp,
                               decode(bitand(m.flags, 1), 1, 'YES', 'NO'),
                               m.drop_segments
                          from sys.mon_mods_all$ m, sys.obj$ o, sys.user$ u
                         where o.owner# = u.user#
                           and o.obj# = m.obj#
                           and o.type# = 19
                        union all
                        select u.name,
                               o.name,
                               o2.subname,
                               o.subname,
                               m.inserts,
                               m.updates,
                               m.deletes,
                               m.timestamp,
                               decode(bitand(m.flags, 1), 1, 'YES', 'NO'),
                               m.drop_segments
                          from sys.mon_mods_all$ m,
                               sys.obj$          o,
                               sys.tabsubpart$   tsp,
                               sys.obj$          o2,
                               sys.user$         u
                         where o.obj# = m.obj#
                           and o.owner# = u.user#
                           and o.obj# = tsp.obj#
                           and o2.obj# = tsp.pobj#)
                 where owner not like '%SYS%'
                   and owner not like 'XDB'
                union all
                select *
                  from (select u.name owner,
                               o.name table_name,
                               null partition_name,
                               null subpartition_name,
                               m.inserts,
                               m.updates,
                               m.deletes,
                               m.timestamp,
                               decode(bitand(m.flags, 1), 1, 'YES', 'NO') truncated,
                               m.drop_segments
                          from sys.mon_mods$ m,
                               sys.obj$      o,
                               sys.tab$      t,
                               sys.user$     u
                         where o.obj# = m.obj#
                           and o.obj# = t.obj#
                           and o.owner# = u.user#
                        union all
                        select u.name,
                               o.name,
                               o.subname,
                               null,
                               m.inserts,
                               m.updates,
                               m.deletes,
                               m.timestamp,
                               decode(bitand(m.flags, 1), 1, 'YES', 'NO'),
                               m.drop_segments
                          from sys.mon_mods$ m, sys.obj$ o, sys.user$ u
                         where o.owner# = u.user#
                           and o.obj# = m.obj#
                           and o.type# = 19
                        union all
                        select u.name,
                               o.name,
                               o2.subname,
                               o.subname,
                               m.inserts,
                               m.updates,
                               m.deletes,
                               m.timestamp,
                               decode(bitand(m.flags, 1), 1, 'YES', 'NO'),
                               m.drop_segments
                          from sys.mon_mods$   m,
                               sys.obj$        o,
                               sys.tabsubpart$ tsp,
                               sys.obj$        o2,
                               sys.user$       u
                         where o.obj# = m.obj#
                           and o.owner# = u.user#
                           and o.obj# = tsp.obj#
                           and o2.obj# = tsp.pobj#)
                 where owner not like '%SYS%'
                   and owner not like '%XDB%')
         order by inserts desc)
 where rownum <= 50;
相关的索引,只有delete次数多,delete数据量大,才需要rebuild

9.查找有问题的时间段
select i.db_name db_name, 
       s.snap_id snap_id, 
       to_char(s.startup_time, 'mm/dd/yyyy HH24:MI:SS') startup_time, 
       to_char(s.begin_interval_time, 'mm/dd/yyyy HH24:MI:SS') begin_interval_time, 
       to_char(s.end_interval_time, 'mm/dd/yyyy HH24:MI:SS') end_interval_time, 
       round(extract(day from s.end_interval_time - s.begin_interval_time) * 1440 + 
             extract(hour from s.end_interval_time - s.begin_interval_time) * 60 + 
             extract(minute from 
                     s.end_interval_time - s.begin_interval_time) + 
             extract(second from 
                     s.end_interval_time - s.begin_interval_time) / 60, 
             2) elapsed_time, 
       round((e.value - b.value) / 1000000 / 60, 2) db_time, 
       round(((((e.value - b.value) / 1000000 / 60) / 
             (extract(day from 
                        s.end_interval_time - s.begin_interval_time) * 1440 + 
             extract(hour from 
                        s.end_interval_time - s.begin_interval_time) * 60 + 
             extract(minute from 
                        s.end_interval_time - s.begin_interval_time) + 
             extract(second from 
                        s.end_interval_time - s.begin_interval_time) / 60)) * 100), 
             2 
              
             ) pct_db_time 
 
  from wrm$_snapshot s, 
       (select distinct dbid, db_name 
          from wrm$_database_instance 
         where db_name = 'ONIMEI') i, 
       dba_hist_sys_time_model e, 
       dba_hist_sys_time_model b 
 where i.dbid = s.dbid 
   and s.dbid = b.dbid 
   and b.dbid = e.dbid 
   and e.snap_id = s.snap_id 
   and b.snap_id = s.snap_id - 1 
   and e.stat_id = b.stat_id 
   and e.stat_name = 'DB time' 
 order by i.db_name, s.snap_id 

 10.查找热点块
 select decode(pd.bp_id,
              1,
              'KEEP',
              2,
              'RECYCLE',
              3,
              'DEFAULT',
              4,
              '2K SUBCACHE',
              5,
              '4K SUBCACHE',
              6,
              '8K SUBCACHE',
              7,
              '16K SUBCACHE',
              8,
              '32K SUBCACHE',
              'UNKNOWN') subcache,
       bh.object_name,
       bh.blocks,
       bh.tch
  from x$kcbwds ds,
       x$kcbwbpd pd,
       (select /*+ use_hash(x) */
         set_ds, o.name object_name, SUM(x.tch) tch, count(*) BLOCKS
          from obj$ o, x$bh x
         where o.dataobj# = x.obj
           and x.state != 0
           and o.owner# != 0
         group by set_ds, o.name) bh
 where ds.set_id >= pd.bp_lo_sid
   and ds.set_id <= pd.bp_hi_sid
   and pd.bp_size != 0
   and ds.addr = bh.set_ds
order by 4 desc ;

11.固定大的包或匿名块
查找,再固定到
Select * from v$db_object_cache where sharable_mem>10000 
and type in ('PACKAGE','PROCEDURE','FUNCTION','PACKAGE BODY') and kept='NO' and owner ='PMIS'

Execute dbms_shared_pool.keep(‘xxx.package_name’);



DECLARE
  CURSOR STALE_TABLE IS
    SELECT OWNER,
           SEGMENT_NAME,
           CASE
             WHEN SIZE_GB < 0.5 THEN
              30
             WHEN SIZE_GB >= 0.5 AND SIZE_GB < 1 THEN
              20
             WHEN SIZE_GB >= 1 AND SIZE_GB < 5 THEN
              10
             WHEN SIZE_GB >= 5 AND SIZE_GB < 10 THEN
              5
             WHEN SIZE_GB >= 10 THEN
              1
           END AS PERCENT,
           8 AS DEGREE
      FROM (SELECT OWNER,
                   SEGMENT_NAME,
                   SUM(BYTES / 1024 / 1024 / 1024) SIZE_GB
              FROM DBA_SEGMENTS
             WHERE OWNER = 'SCOTT'
               AND SEGMENT_NAME IN
                   (SELECT /*+ UNNEST */ DISTINCT TABLE_NAME
                      FROM DBA_TAB_STATISTICS
                     WHERE (LAST_ANALYZED IS NULL OR STALE_STATS = 'YES')
                       AND OWNER = 'SCOTT')
             GROUP BY OWNER, SEGMENT_NAME);
BEGIN
  DBMS_STATS.FLUSH_DATABASE_MONITORING_INFO;
  FOR STALE IN STALE_TABLE LOOP
    DBMS_STATS.GATHER_TABLE_STATS(OWNNAME          => STALE.OWNER,
                                  TABNAME          => STALE.SEGMENT_NAME,
                                  ESTIMATE_PERCENT => STALE.PERCENT,
                                  METHOD_OPT       => 'for all columns size skewonly',
                                  DEGREE           => 8,
                                  GRANULARITY      => 'ALL',
                                  CASCADE          => TRUE);
  END LOOP;
END;


12.检查外键没有添加索引的的表
column columns format a30 word_wrapped
column tablename format a15 word_wrapped
column constraint_name format a15 word_wrapped
select table_name, constraint_name,
     cname1 || nvl2(cname2,','||cname2,null) ||
     nvl2(cname3,','||cname3,null) || nvl2(cname4,','||cname4,null) ||
     nvl2(cname5,','||cname5,null) || nvl2(cname6,','||cname6,null) ||
     nvl2(cname7,','||cname7,null) || nvl2(cname8,','||cname8,null)
            columns
  from ( select b.table_name,
                b.constraint_name,
                max(decode( position, 1, column_name, null )) cname1,
                max(decode( position, 2, column_name, null )) cname2,
                max(decode( position, 3, column_name, null )) cname3,
                max(decode( position, 4, column_name, null )) cname4,
                max(decode( position, 5, column_name, null )) cname5,
                max(decode( position, 6, column_name, null )) cname6,
                max(decode( position, 7, column_name, null )) cname7,
                max(decode( position, 8, column_name, null )) cname8,
                count(*) col_cnt
           from (select substr(table_name,1,30) table_name,
                        substr(constraint_name,1,30) constraint_name,
                        substr(column_name,1,30) column_name,
                        position
                   from user_cons_columns ) a,
                user_constraints b
          where a.constraint_name = b.constraint_name
            and b.constraint_type = 'R'
          group by b.table_name, b.constraint_name
       ) cons
 where col_cnt > ALL
         ( select count(*)
             from user_ind_columns i
            where i.table_name = cons.table_name
              and i.column_name in (cname1, cname2, cname3, cname4,
                                    cname5, cname6, cname7, cname8 )
              and i.column_position <= cons.col_cnt
            group by i.index_name
         )


13.
select *
  from dba_hist_sqltext a
 where a.SQL_ID in (select sql_id                    
                      from DBA_HIST_ACTIVE_SESS_HISTORY
                     where to_char(SAMPLE_TIME, 'YY-MM-DD HH24:MI:SS') between
                           '12-07-08 11:19:14' and '12-07-11 13:29:14'
                       and sql_id is not null);
 
日常管理的库经常会有hang死的进程，就是指应用连接实际上已经断了，但是数据库这边还保持这连接：
比如:
 select * from v$session where seconds_in_wait >=24*3600*20;  ---大于20天的等待连接:
