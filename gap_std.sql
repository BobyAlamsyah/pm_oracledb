spool gap.txt
set pages 500 lines 500
SELECT al.thrd "Thread", almax "Last Seq Received", lhmax "Last Seq Applied"
  FROM (  SELECT thread# thrd, MAX (sequence#) almax
            FROM v$archived_log
           WHERE resetlogs_change# = (  SELECT resetlogs_change# FROM v$database)
        GROUP BY thread#) al,
       (  SELECT thread# thrd, MAX (sequence#) lhmax
            FROM v$log_history
           WHERE resetlogs_change# = (  SELECT resetlogs_change# FROM v$database)
        GROUP BY thread#) lh
WHERE al.thrd = lh.thrd;




select process, status, sequence# from v$managed_standby;

select status , instance_name ,database_role, open_mode from v$database,v$instance;

spool off;