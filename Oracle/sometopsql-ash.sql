-------------------------------------------------------------------------------
Top 10 queries from v$active_session_history
select * from (
	select
		 SQL_ID ,
		 sum(decode(session_state,'ON CPU',1,0)) as CPU,
		 sum(decode(session_state,'WAITING',1,0)) - sum(decode(session_state,'WAITING', decode(wait_class, 'User I/O',1,0),0)) as WAIT,
		 sum(decode(session_state,'WAITING', decode(wait_class, 'User I/O',1,0),0)) as IO,
		 sum(decode(session_state,'ON CPU',1,1)) as TOTAL
	from v$active_session_history
	where SQL_ID is not NULL
	group by sql_id
	order by sum(decode(session_state,'ON CPU',1,1))   desc
	)
where rownum <11

-------------------------------------------------------------------------------
Top 10 wait events from v$active_session_history:
select * from (
	select
		 WAIT_CLASS ,
		 EVENT,
		 count(sample_time) as EST_SECS_IN_WAIT
	from v$active_session_history
	where sample_time between sysdate - interval '1' hour and sysdate
	group by WAIT_CLASS,EVENT
	order by count(sample_time) desc
	)
where rownum <11

-------------------------------------------------------------------------------
Top 10 SQL Activity
SELECT trunc(sample_time,'MI'),
       sql_id,
       count(sql_id) as TOTAL
FROM v$active_session_history
WHERE sample_time between sysdate - interval '1' hour and sysdate
AND sql_id in (select sql_id from (
 select
     SQL_ID ,
     sum(decode(session_state,'WAITING',1,1))  as TOTAL_ACTIVITY
from v$active_session_history
WHERE sample_time between sysdate - interval '1' hour and sysdate
group by sql_id
order by sum(decode(session_state,'WAITING',1,1))   desc)
where rownum < 11)
group by trunc(sample_time,'MI'),sql_id 
order by trunc(sample_time,'MI') desc


-------------------------------------------------------------------------------
Average Active Sessions from v$active_session_history
select round((count(ash.sample_id) / ((CAST(end_time.sample_time AS DATE) - CAST(start_time.sample_time AS DATE))*24*60*60)),2) as AAS
from
	(select min(sample_time) sample_time 
	from  v$active_session_history ash 
	) start_time,
	(select max(sample_time) sample_time
	from  v$active_session_history 
	) end_time,
	v$active_session_history ash
where ash.sample_time between start_time.sample_time and end_time.sample_time
group by end_time.sample_time,start_time.sample_time;

select round((count(ash.sample_id) / ((CAST(end_time.sample_time AS DATE) - CAST(start_time.sample_time AS DATE))*24*60*60)),2) as AAS
from
	(select min(sample_time) sample_time 
	from  v$active_session_history ash 
	where sample_time between sysdate-1/24 and sysdate) start_time,
	(select max(sample_time) sample_time
	from  v$active_session_history 
	where sample_time between sysdate-1/24 and sysdate) end_time,
	v$active_session_history ash
where ash.sample_time between start_time.sample_time and end_time.sample_time
group by end_time.sample_time,start_time.sample_time;

-------------------------------------------------------------------------------
top 10 sessions from v$active_session_history
select * from (
select
     session_id,
	 session_serial#,
     program,
	 module,
	 action,
     sum(decode(session_state,'WAITING',0,1)) "CPU",
     sum(decode(session_state,'WAITING',1,0)) - sum(decode(session_state,'WAITING',decode(wait_class,'User I/O',1,0),0)) "WAITING" ,
     sum(decode(session_state,'WAITING',decode(wait_class,'User I/O',1,0),0)) "IO" ,
     sum(decode(session_state,'WAITING',1,1)) "TOTAL"
from v$active_session_history 
where session_type='FOREGROUND'
group by session_id,session_serial#,module,action,program
order by sum(decode(session_state,'WAITING',1,1)) desc)
where rownum <11

-------------------------------------------------------------------------------
/*找出短期内TOP SQL的sql_id和活动历史*/
select ash.SQL_ID,
       sum(decode(ash.session_state, 'ON CPU', 1, 0)) "CPU",
       sum(decode(ash.session_state, 'WAITING', 1, 0)) -
       sum(decode(ash.session_state,
                  'WAITING',
                  decode(en.wait_class, 'User I/O', 1, 0),
                  0)) "WAIT",
       sum(decode(ash.session_state,
                  'WAITING',
                  decode(en.wait_class, 'User I/O', 1, 0),
                  0)) "IO",
       sum(decode(ash.session_state, 'ON CPU', 1, 1)) "TOTAL"
  from v$active_session_history ash, v$event_name en
 where SQL_ID is not NULL
   and en.event# = ash.event#
 group by sql_id
 order by sum(decode(session_state, 'ON CPU', 1, 1)) desc;

SQL_ID               CPU       WAIT         IO      TOTAL
------------- ---------- ---------- ---------- ----------
a01hp0psv0rrh          0          2          7          9
24g90qj2b7ywk          0          5          1          6
2amsp6skc6tjv          0          0          5          5
46quk68k7akpa          0          3          1          4
2ufrf9vk4kcwj          0          0          3          3
1w8m6dwy66ttn          0          0          3          3
8uxr3scz9bmxd          0          0          3          3
6htq3p9j91y0s          0          0          3          3
cvn54b7yz0s8u          0          0          3          3
92f47aa2q2rmd          0          2          1          3

-------------------------------------------------------------------------------
/*找出变量ivl指定分钟内的TOP CPU SESSION*/
Select session_id, count(*)
  from v$active_session_history
 where session_state = 'ON CPU'
   and SAMPLE_TIME > sysdate -(&ivl/(24 * 60))
 group by session_id
 order by count(*) desc;
输入 ivl 的值:  10
原值    4:    and SAMPLE_TIME > sysdate -(&ivl/(24 * 60))
新值    4:    and SAMPLE_TIME > sysdate -(10/(24 * 60))

SESSION_ID   COUNT(*)
---------- ----------
       136          4

-------------------------------------------------------------------------------
/*找出变量ivl指定分钟内TOP WAITING SESSION*/
Select session_id, count(*)
  from v$active_session_history
 where session_state = 'WAITING'
   and SAMPLE_TIME > SYSDATE - (&ivl / (24 * 60))
 group by session_id
 order by count(*) desc;

输入 ivl 的值:  10
原值    4:    and SAMPLE_TIME > SYSDATE - (&ivl / (24 * 60))
新值    4:    and SAMPLE_TIME > SYSDATE - (10 / (24 * 60))

SESSION_ID   COUNT(*)
---------- ----------
         3         11
         
-------------------------------------------------------------------------------
/*找出短期内的TOP SESSION及活动历史*/
select ash.session_id,
       ash.session_serial#,
       ash.user_id,
       ash.program,
       sum(decode(ash.session_state, 'ON CPU', 1, 0)) "CPU",
       sum(decode(ash.session_state, 'WAITING', 1, 0)) -
       sum(decode(ash.session_state,
                  'WAITING',
                  decode(en.wait_class, 'User I/O', 1, 0),
                  0)) "WAITING",
       sum(decode(ash.session_state,
                  'WAITING',
                  decode(en.wait_class, 'User I/O', 1, 0),
                  0)) "IO",
       sum(decode(session_state, 'ON CPU', 1, 1)) "TOTAL"
  from v$active_session_history ash, v$event_name en
 where en.event# = ash.event#
 group by session_id, user_id, session_serial#, program
 order by sum(decode(session_state, 'ON CPU', 1, 1));
