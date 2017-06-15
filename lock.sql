------------------------------------------------------------------------
--检查出现行锁的会话，等待时间和阻塞者
SELECT A.SID,
       B.SPID,
       A.SQL_ID,
       A.BLOCKING_SESSION,
       A.STATE,
       A.SECONDS_IN_WAIT
  FROM V$SESSION A, V$PROCESS B
 WHERE A.PADDR = B.ADDR
   AND A.EVENT = 'enq: TX - row lock contention'
 ORDER BY A.SECONDS_IN_WAIT

------------------------------------------------------------------------
--查询锁表的sid和serial#
SELECT L.SESSION_ID SID,
       S.SERIAL#,
       L.LOCKED_MODE,
       L.ORACLE_USERNAME,
       S.USER#,
       L.OS_USER_NAME,
       S.MACHINE,
       S.TERMINAL,
       A.SQL_TEXT,
       A.ACTION
  FROM V$SQLAREA A, V$SESSION S, V$LOCKED_OBJECT L
 WHERE L.SESSION_ID = S.SID
   AND S.PREV_SQL_ADDR = A.ADDRESS
 ORDER BY SID, S.SERIAL#;

------------------------------------------------------------------------
--查看被锁的对象 
SELECT P.SPID,
       A.SERIAL#,
       C.OBJECT_NAME,
       B.SESSION_ID,
       B.ORACLE_USERNAME,
       B.OS_USER_NAME
  FROM V$PROCESS P, V$SESSION A, V$LOCKED_OBJECT B, ALL_OBJECTS C
 WHERE P.ADDR = A.PADDR
   AND A.PROCESS = B.PROCESS
   AND C.OBJECT_ID = B.OBJECT_ID;


------------------------------------------------------------------------
--查看引起锁表的sql 
SELECT A.USERNAME,
       A.MACHINE,
       A.PROGRAM,
       A.SID,
       A.SERIAL#,
       A.STATUS,
       C.PIECE,
       C.SQL_TEXT
  FROM V$SESSION A, V$SQLTEXT C
 WHERE A.SID IN (SELECT DISTINCT T2.SID
                   FROM V$LOCKED_OBJECT T1, V$SESSION T2
                  WHERE T1.SESSION_ID = T2.SID)
   AND A.SQL_ADDRESS = C.ADDRESS(+)
 ORDER BY C.PIECE;
