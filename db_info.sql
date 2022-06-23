spool resourcedb.txt

set lines 500 pages 500

select * from v$resource_limit;
select * from v$resource_limit where resource_name in ('processes','sessions');
SELECT * FROM GV$RESOURCE_LIMIT;

spool off;