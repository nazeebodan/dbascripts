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
