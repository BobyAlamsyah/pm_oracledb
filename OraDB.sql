SET LINES 160 PAGES 5000 TIMING ON TRIM ON ECHO ON
SET MARKUP HTML ON
SET MARKUP HTML ENTMAP OFF
COL TANGGAL new_value TGL
COL SPOOL_EXTENSION new_value suffix
SELECT TO_CHAR(SYSDATE,'YYYYMMDD')TANGGAL, '.html' SPOOL_EXTENSION FROM DUAL;
COL INSTANCE_NAME new_value INSNAME
SELECT INSTANCE_NAME||'_' INSTANCE_NAME FROM V$INSTANCE;
SPOOL OraDBInfoNTT_&&INSNAME&&TGL&&suffix
--Collect DB Info by NTT
REM Collect DB Info by NTT
ALTER SESSION SET NLS_DATE_FORMAT='DD-Mon-RR HH24:MI:SS';

--Document information
COL USER FOR A15
SELECT USER, 'OracleDB Info by NTT' SCRIPT, SYSDATE COLLECT_DATE FROM DUAL;

--Schema Size
set linesize 2000;
select OWNER,sum(bytes)/1024/1024/1000 "SIZE_IN_GB" from dba_segments group by owner order by owner;

--Resource limit
SET LINES 160 PAGES 5000 TIMING ON TRIM ON ECHO ON;
COL INST_ID FOR 9;
COL RESOURCE_NAME FOR A25;
COL CURRENT_UTILIZATION FOR 9;
COL MAX_UTILIZATION FOR 9;
COL INIT_ALLOC FOR A10;
COL LIMIT_VAL FOR A10;
SELECT /*+ PARALLEL(2)*/ RESOURCE_NAME, CURRENT_UTILIZATION CUR_UTIL, MAX_UTILIZATION MAX_UTIL, INITIAL_ALLOCATION INIT_ALLOC, LIMIT_VALUE LIMIT_VAL FROM GV$RESOURCE_LIMIT;

--Parameter information
--COL NAME FOR A40;
--COL TYPE FOR 9999;
--COL DISPLAY_VALUE FOR A110;
--SELECT NAME,TYPE,DISPLAY_VALUE FROM V$PARAMETER ORDER BY 1;
SHO PARAMETER;

--Invalid Objects
SET LINES 160 PAGES 5000 TIMING ON TRIM ON ECHO ON;
SELECT COUNT(1)INV_OBJ FROM DBA_OBJECTS WHERE STATUS='INVALID';
COL OBJ_NAME FOR A60;
SELECT /*+ PARALLEL(4)*/OBJECT_TYPE, OWNER||'.'||OBJECT_NAME OBJ_NAME FROM DBA_OBJECTS WHERE STATUS='INVALID' ORDER BY 2,1;

--Database information
SET LINES 160 PAGES 5000 TIMING ON TRIM ON ECHO ON;
COL HOST_NAME FOR A30;
COL DB_ROLE FOR A15;
COL OS FOR A30;
COL INSTANCE_NAME FOR A10;
COL DBNAME FOR A10;
COL LOG_MODE FOR A15;
COL OPEN_MODE FOR A15;
COL PLATFORM_NAME FOR A25;
COL FORCE_LOGGING FOR A3;
SELECT NAME,DB_UNIQUE_NAME,DBID,CREATED,LOG_MODE,OPEN_MODE,DATABASE_ROLE,PLATFORM_NAME,FORCE_LOGGING FROM V$DATABASE;
SELECT INSTANCE_NUMBER,INSTANCE_NAME,STATUS,HOST_NAME,STARTUP_TIME,VERSION FROM GV$INSTANCE ORDER BY 1;

--Database version
SELECT BANNER FROM V$VERSION;

--Component Version and Status
set linesize 3000;
select comp_id,comp_name,version,status from dba_registry;

--Database patches
SELECT * FROM REGISTRY$HISTORY;

--Database patch registry
col action_time for a28;
col action for a8;
col version for a8;
col comments for a30;
col status for a10;
set line 999 pages 999;
select patch_id, status, Action, Action_time from dba_registry_sqlpatch
order by action_time;

--E-Business Suite version
SELECT RELEASE_NAME EBS_VERSION FROM APPS.FND_PRODUCT_GROUPS;

--Memory information
SHO PARAMETER MEMORY;
SELECT * FROM V$MEMORY_TARGET_ADVICE ORDER BY 1;
SHO PARAMETER SGA;
SELECT * FROM V$SGA_TARGET_ADVICE ORDER BY 1;
SHO PARAMETER PGA;
SELECT * FROM V$PGA_TARGET_ADVICE ORDER BY 1;

--Redo log information
COL MEMBER FOR A80;
SELECT * FROM V$LOGFILE ORDER BY 1,3,4;
COL STATUS FOR A10;
SELECT GROUP#, THREAD#, SEQUENCE#, ROUND((BYTES/1024/1024),2)REDO_MB, MEMBERS, ARCHIVED, STATUS, FIRST_CHANGE# FROM V$LOG ORDER BY 1;

--Tablespace information
SET LINES 160 PAGES 5000 TIMING ON TRIM ON ECHO ON;
--MB version
SELECT /*+ PARALLEL(4)*/
  DDF.TABLESPACE_NAME, ROUND(DDF.BYTES/1024/1024,2)ALLOCATED_MB, ROUND((DDF.BYTES-DFS.BYTES)/1024/1024,2)USED_MB,
  ROUND(((DDF.BYTES-DFS.BYTES)/DDF.BYTES)*100,2)PERCENT_USED, ROUND(DFS.BYTES/1024/1024,2)FREE_MB, ROUND((1-((DDF.BYTES-DFS.BYTES)/DDF.BYTES))*100,2)PERCENT_FREE
FROM (SELECT TABLESPACE_NAME,SUM(BYTES) BYTES FROM DBA_DATA_FILES GROUP BY TABLESPACE_NAME) DDF
JOIN (SELECT TABLESPACE_NAME,SUM(BYTES) BYTES FROM DBA_FREE_SPACE GROUP BY TABLESPACE_NAME) DFS ON DDF.TABLESPACE_NAME=DFS.TABLESPACE_NAME ORDER BY 4 DESC;
--GB version
COL USED_GB FOR 999999.99;
COL PERCENT_USED FOR 999.99;
COL FREE_GB FOR 999999.99;
COL PERCENT_FREE FOR 999.99;
SELECT /*+ PARALLEL(8)*/
  DDF.TABLESPACE_NAME, ROUND(DDF.BYTES/1024/1024/1024,2)ALLOCATED_GB, ROUND((DDF.BYTES-DFS.BYTES)/1024/1024/1024,2)USED_GB,
  ROUND(((DDF.BYTES-DFS.BYTES)/DDF.BYTES)*100,2)PERCENT_USED, ROUND(DFS.BYTES/1024/1024/1024,2)FREE_GB, ROUND((1-((DDF.BYTES-DFS.BYTES)/DDF.BYTES))*100,2)PERCENT_FREE
FROM (SELECT TABLESPACE_NAME,SUM(BYTES) BYTES FROM DBA_DATA_FILES GROUP BY TABLESPACE_NAME) DDF
JOIN (SELECT TABLESPACE_NAME,SUM(BYTES) BYTES FROM DBA_FREE_SPACE GROUP BY TABLESPACE_NAME) DFS ON DDF.TABLESPACE_NAME=DFS.TABLESPACE_NAME ORDER BY 4 DESC;

----Datafile utilization
--SET LINES 160 PAGES 5000 TIMING ON TRIM ON ECHO ON;
--COL TABLESPACE_NAME FOR A20;
--COL FILE_NAME FOR A55;
--SELECT /*+ PARALLEL(8)*/
--  FILE_NAME,D.TABLESPACE_NAME,ROUND(D.BYTES/1024/1024/1024,2)SIZE_GB,SUM(NVL(ROUND(E.BYTES/1024/1024/1024,2),0))USED_GB,
--  ROUND(SUM(NVL(E.BYTES,0)) / (D.BYTES), 4) * 100 AS PERCENT_USED,
--  ROUND((D.BYTES-NVL(SUM(E.BYTES),0))/1024/1024/1024,2)FREE_GB
--FROM DBA_EXTENTS E, DBA_DATA_FILES D
--WHERE D.FILE_ID = E.FILE_ID (+)
--GROUP BY FILE_NAME, D.TABLESPACE_NAME, D.FILE_ID, D.BYTES, STATUS
--ORDER BY D.TABLESPACE_NAME, D.FILE_ID;

--Datafiles and tempfiles information
SET LINES 160 PAGES 5000 TIMING ON TRIM ON ECHO ON;
COL TABLESPACE_NAME FOR A20;
COL FILE_ID FOR 9999;
COL FILE_NAME FOR A55;
COL AUTOEXTENSIBLE FOR A3;
COL OL FOR A10;
COL ENABLED FOR A15;
COL STATUS FOR A10;
SELECT /*+ PARALLEL(4)*/ * FROM (
  SELECT /*+ PARALLEL(4)*/ TABLESPACE_NAME,FILE_ID,FILE_NAME,ROUND(VD.BYTES/1024/1024/1024,2)SIZE_GB,ROUND(MAXBYTES/1024/1024/1024,2)MAX_GB,AUTOEXTENSIBLE,DDF.STATUS,ONLINE_STATUS OL,VD.ENABLED
  FROM DBA_DATA_FILES DDF JOIN V$DATAFILE VD ON VD.NAME=DDF.FILE_NAME ORDER BY 1,2)
UNION ALL
SELECT * FROM (
  SELECT /*+ PARALLEL(4)*/ TABLESPACE_NAME,FILE_ID,FILE_NAME,ROUND(VT.BYTES/1024/1024/1024,2)SIZE_GB,ROUND(MAXBYTES/1024/1024/1024,2)MAX_GB,AUTOEXTENSIBLE,'',DTF.STATUS OL,VT.ENABLED
  FROM DBA_TEMP_FILES DTF JOIN V$TEMPFILE VT ON VT.NAME=DTF.FILE_NAME ORDER BY 1,2);

--ASM information
COL PATH FOR A55;
COL NAME FOR A20;
SELECT MOUNT_STATUS,HEADER_STATUS,STATE,ROUND(TOTAL_MB/1024,2)TOTAL_GB,ROUND(FREE_MB/1024,2)FREE_GB,NAME,PATH FROM V$ASM_DISK ORDER BY NAME;
SELECT NAME,TYPE,ROUND(TOTAL_MB/1024,2)TOTAL_GB,ROUND(FREE_MB/1024,2)FREE_GB,ROUND(USABLE_FILE_MB/1024,2)USABLE_FILE_GB,STATE,SECTOR_SIZE,BLOCK_SIZE FROM V$ASM_DISKGROUP ORDER BY NAME;
COL ASMDISK FOR A15;
COL DISKGROUP FOR A10;
SELECT DG.NAME DISKGROUP,DG.TYPE,D.NAME ASMDISK,D.PATH,ROUND(D.TOTAL_MB/1024,2)TOTAL_GB,ROUND(D.FREE_MB/1024,2)FREE_GB,D.VOTING_FILE,DG.SECTOR_SIZE,DG.BLOCK_SIZE FROM V$ASM_DISKGROUP DG JOIN V$ASM_DISK D ON DG.GROUP_NUMBER=D.GROUP_NUMBER ORDER BY 3;

--ASM volume
COL VOLUME_NAME FOR A10;
COL USAGE FOR A10;
COL MOUNTPATH FOR A35;
COL VOLUME_DEVICE FOR A30;
SELECT GROUP_NUMBER,VOLUME_NAME,ROUND(SIZE_MB/1024,2)SIZE_GB,VOLUME_NUMBER,REDUNDANCY,STATE,FILE_NUMBER,USAGE,VOLUME_DEVICE,MOUNTPATH FROM V$ASM_VOLUME;

--Database size
SELECT /*+ PARALLEL(4)*/ROUND((SUM(BYTES))/1024/1024/1024, 2)DBSIZE_GB,ROUND((SUM(BYTES))/1024/1024/1024/1024, 2)DBSIZE_TB FROM DBA_DATA_FILES;

--Total database size
SELECT /*+ PARALLEL(4)*/ 'Datafiles' "COMPONENTS", ROUND((SUM(BYTES))/1024/1024/1024, 2)DATAFILES_GB FROM DBA_DATA_FILES UNION ALL
SELECT /*+ PARALLEL(4)*/ 'Tempfiles' "COMPONENTS", ROUND((SUM(BYTES))/1024/1024/1024, 2)TEMPFILES_GB FROM DBA_TEMP_FILES UNION ALL
SELECT /*+ PARALLEL(4)*/ 'Redo Logs' "COMPONENTS", ROUND((SUM(BYTES))/1024/1024/1024, 2)REDO_GB FROM V$LOG UNION ALL
SELECT /*+ PARALLEL(4)*/ 'Stby Logs' "COMPONENTS", ROUND((SUM(BYTES))/1024/1024/1024, 2)REDO_GB FROM V$STANDBY_LOG UNION ALL
SELECT 'TOTAL' "COMPONENT", SUM(DATAFILES_GB)TOTAL_GB FROM(
SELECT /*+ PARALLEL(4)*/ 'Datafiles' "COMPONENTS", ROUND((SUM(BYTES))/1024/1024/1024, 2)DATAFILES_GB FROM DBA_DATA_FILES UNION ALL
SELECT /*+ PARALLEL(4)*/ 'Tempfiles' "COMPONENTS", ROUND((SUM(BYTES))/1024/1024/1024, 2)TEMPFILES_GB FROM DBA_TEMP_FILES UNION ALL
SELECT /*+ PARALLEL(4)*/ 'Redo Logs' "COMPONENTS", ROUND((SUM(BYTES))/1024/1024/1024, 2)REDO_GB FROM V$LOG UNION ALL
SELECT /*+ PARALLEL(4)*/ 'Stby Logs' "COMPONENTS", ROUND((SUM(BYTES))/1024/1024/1024, 2)REDO_GB FROM V$STANDBY_LOG);

--Analyzed table
COL OWNER FOR A25;
SELECT OWNER, SUM(DECODE(NVL(NUM_ROWS,9999), 9999,0,1)) ANALYZED, SUM(DECODE(NVL(NUM_ROWS,9999), 9999,1,0)) NOT_ANALYZED,COUNT(TABLE_NAME) TOTAL FROM DBA_TABLES GROUP BY OWNER ORDER BY 1;

--Buffer hit ratio
SELECT SUM(DECODE(NAME, 'consistent gets',VALUE, 0)) Consistent_Gets, SUM(DECODE(NAME, 'db block gets',VALUE, 0)) DB_Blk_Gets, SUM(DECODE(NAME, 'physical reads',VALUE, 0))Physical_Reads,
ROUND(
  (SUM(DECODE(NAME, 'consistent gets',value, 0)) + SUM(DECODE(NAME, 'db block gets',value, 0)) - SUM(DECODE(NAME, 'physical reads',value, 0))) /
  (SUM(DECODE(NAME, 'consistent gets',value, 0)) + SUM(DECODE(NAME, 'db block gets',value, 0))) * 100,2
) HIT_RATIO FROM V$SYSSTAT;

--Library cache hit ratio
SELECT SUM(PINS) Executions, SUM(PINHITS) Execution_Hits, ROUND((SUM(PINHITS) / SUM(PINS)) * 100,3) Hit_Ratio, SUM(RELOADS) Misses, ROUND((SUM(PINS) / (SUM(PINS) + sum(RELOADS))) * 100,3) Hit_Ratio FROM V$LIBRARYCACHE;

--Data dictionary hit ratio
SELECT SUM(GETS) Gets, SUM(GETMISSES) Cache_Misses, ROUND((1 - (SUM(GETMISSES) / sum(GETS))) * 100,2) Hit_Ratio FROM V$ROWCACHE;

--User's tablespace
SET LINES 160 PAGES 5000 TIMING ON;
COL USERNAME FOR A25;
COL ACCOUNT_STATUS FOR A20;
SELECT USERNAME, PROFILE ,ACCOUNT_STATUS, DEFAULT_TABLESPACE, TEMPORARY_TABLESPACE TEMP_TBS FROM DBA_USERS ORDER BY 1;

--DBA profiles resources
set linesize 2000;
select profile,resource_name,resource_type,limit from dba_profiles;

--Tablespace detail
set pagesize 10000 linesize 300 tab off
 
col tablespace_name format A30              heading "Tablespace";
col ts_type         format A13              heading "TS Type";
col segments        format 999999           heading "Segments";
col files           format 9999;
col allocated_mb    format 9,999,990.000    heading "Allocated Size|(Mb)";
col used_mb         format 9,999,990.000    heading "Used Space|(Mb)";
col Free_mb         format 999,990.000      heading "Free Space|(Mb)";
col used_pct        format 999              heading "Used|%";
col max_ext_mb      format 99,999,990.000   heading "Max Size|(Mb)";
col max_free_mb     format 9,999,990.000    heading "Max Free|(Mb)";
col max_used_pct    format 999              heading "Max Used|(%)";
 
BREAK ON REPORT
COMPUTE SUM LABEL "TOTAL SUM ==========>" AVG LABEL "AVERAGE   ==========>" OF segments files allocated_mb used_mb Free_MB max_ext_mb ON REPORT;
 
WITH df AS (SELECT tablespace_name, SUM(bytes) bytes, COUNT(*) cnt, DECODE(SUM(DECODE(autoextensible,'NO',0,1)), 0, 'NO', 'YES') autoext, sum(DECODE(maxbytes,0,bytes,maxbytes)) maxbytes FROM dba_data_files GROUP BY tablespace_name), 
     tf AS (SELECT tablespace_name, SUM(bytes) bytes, COUNT(*) cnt, DECODE(SUM(DECODE(autoextensible,'NO',0,1)), 0, 'NO', 'YES') autoext, sum(DECODE(maxbytes,0,bytes,maxbytes)) maxbytes FROM dba_temp_files GROUP BY tablespace_name), 
     tm AS (SELECT tablespace_name, used_percent FROM dba_tablespace_usage_metrics),
     ts AS (SELECT tablespace_name, COUNT(*) segcnt FROM dba_segments GROUP BY tablespace_name)
SELECT d.tablespace_name, 
       d.status,
       DECODE(d.contents,'PERMANENT',DECODE(d.extent_management,'LOCAL','LM','DM'),'TEMPORARY','TEMP',d.contents)||'-'||DECODE(d.allocation_type,'UNIFORM','UNI','SYS')||'-'||decode(d.segment_space_management,'AUTO','ASSM','MSSM') ts_type,
       a.cnt files,  
       NVL(s.segcnt,0) segments,
       ROUND(NVL(a.bytes / 1024 / 1024, 0), 3) Allocated_MB, 
       ROUND(NVL(a.bytes - NVL(f.bytes, 0), 0)/1024/1024,3) Used_MB, 
       ROUND(NVL(f.bytes, 0) / 1024 / 1024, 3) Free_MB, 
       ROUND(NVL((a.bytes - NVL(f.bytes, 0)) / a.bytes * 100, 0), 2) Used_pct, 
       ROUND(a.maxbytes / 1024 / 1024, 3)  max_ext_mb,
       ROUND(NVL(m.used_percent,0), 2) Max_used_pct
  FROM dba_tablespaces d, df a, tm m, ts s, (SELECT tablespace_name, SUM(bytes) bytes FROM dba_free_space GROUP BY tablespace_name) f 
 WHERE d.tablespace_name = a.tablespace_name(+) 
   AND d.tablespace_name = f.tablespace_name(+) 
   AND d.tablespace_name = m.tablespace_name(+) 
   AND d.tablespace_name = s.tablespace_name(+)
   AND NOT d.contents = 'UNDO'
   AND NOT ( d.extent_management = 'LOCAL' AND d.contents = 'TEMPORARY' ) 
UNION ALL
-- TEMP TS
SELECT d.tablespace_name, 
       d.status, 
       DECODE(d.contents,'PERMANENT',DECODE(d.extent_management,'LOCAL','LM','DM'),'TEMPORARY','TEMP',d.contents)||'-'||DECODE(d.allocation_type,'UNIFORM','UNI','SYS')||'-'||decode(d.segment_space_management,'AUTO','ASSM','MSSM') ts_type, 
       a.cnt, 
       0,
       ROUND(NVL(a.bytes / 1024 / 1024, 0), 3) Allocated_MB, 
       ROUND(NVL(t.ub*d.block_size, 0)/1024/1024, 3) Used_MB, 
       ROUND((NVL(a.bytes ,0)/1024/1024 - NVL((t.ub*d.block_size), 0)/1024/1024), 3) Free_MB,
       ROUND(NVL((t.ub*d.block_size) / a.bytes * 100, 0), 2) Used_pct,
       ROUND(a.maxbytes / 1024 / 1024, 3)  max_size_mb, 
       ROUND(NVL(m.used_percent,0), 2) Max_used_pct
  FROM dba_tablespaces d, tf a, tm m, (SELECT ss.tablespace_name , sum(ss.used_blocks) ub FROM gv$sort_segment ss GROUP BY ss.tablespace_name) t 
 WHERE d.tablespace_name = a.tablespace_name(+) 
   AND d.tablespace_name = t.tablespace_name(+) 
   AND d.tablespace_name = m.tablespace_name(+) 
   AND d.extent_management = 'LOCAL'
   AND d.contents = 'TEMPORARY'  
UNION ALL
-- UNDO TS
SELECT d.tablespace_name, 
       d.status, 
       DECODE(d.contents,'PERMANENT',DECODE(d.extent_management,'LOCAL','LM','DM'),'TEMPORARY','TEMP',d.contents)||'-'||DECODE(d.allocation_type,'UNIFORM','UNI','SYS')||'-'||decode(d.segment_space_management,'AUTO','ASSM','MSSM') ts_type, 
       a.cnt, 
       NVL(s.segcnt,0) segments,
       ROUND(NVL(a.bytes / 1024 / 1024, 0), 3) Allocated_MB, 
       ROUND(NVL(u.bytes, 0) / 1024 / 1024, 3) Used_MB, 
       ROUND(NVL(a.bytes - NVL(u.bytes, 0), 0)/1024/1024, 3) Free_MB,
       ROUND(NVL(u.bytes / a.bytes * 100, 0), 2) Used_pct, 
       ROUND(a.maxbytes / 1024 / 1024, 3)  max_size_mb,
       ROUND(NVL(m.used_percent,0), 2) Max_used_pct
FROM dba_tablespaces d, df a, tm m, ts s, (SELECT tablespace_name, SUM(bytes) bytes FROM dba_undo_extents where status in ('ACTIVE','UNEXPIRED') GROUP BY tablespace_name) u 
WHERE d.tablespace_name = a.tablespace_name(+) 
AND d.tablespace_name = u.tablespace_name(+) 
AND d.tablespace_name = m.tablespace_name(+) 
AND d.tablespace_name = s.tablespace_name(+)
AND d.contents = 'UNDO'
ORDER BY 11 desc;


--Redo log history
COL "00" FOR A4;
COL "01" FOR A4;
COL "02" FOR A4;
COL "03" FOR A4;
COL "04" FOR A4;
COL "05" FOR A4;
COL "06" FOR A4;
COL "07" FOR A4;
COL "08" FOR A4;
COL "09" FOR A4;
COL "10" FOR A4;
COL "11" FOR A4;
COL "12" FOR A4;
COL "13" FOR A4;
COL "14" FOR A4;
COL "15" FOR A4;
COL "16" FOR A4;
COL "17" FOR A4;
COL "18" FOR A4;
COL "19" FOR A4;
COL "20" FOR A4;
COL "21" FOR A4;
COL "22" FOR A4;
COL "23" FOR A4;
--SELECT SUBSTR(TO_CHAR(FIRST_TIME,'DY, YYYY/MM/DD'),1,15) DAY,
SELECT TO_DATE(SUBSTR(TO_CHAR(FIRST_TIME,'DD-Mon-YYYY'),1,15),'DD-Mon-YYYY') DAY,
decode(sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'00',1,0)),0,'-',sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'00',1,0))) AS "00",
decode(sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'01',1,0)),0,'-',sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'01',1,0))) AS "01",
decode(sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'02',1,0)),0,'-',sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'02',1,0))) AS "02",
decode(sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'03',1,0)),0,'-',sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'03',1,0))) AS "03",
decode(sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'04',1,0)),0,'-',sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'04',1,0))) AS "04",
decode(sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'05',1,0)),0,'-',sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'05',1,0))) AS "05",
decode(sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'06',1,0)),0,'-',sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'06',1,0))) AS "06",
decode(sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'07',1,0)),0,'-',sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'07',1,0))) AS "07",
decode(sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'08',1,0)),0,'-',sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'08',1,0))) AS "08",
decode(sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'09',1,0)),0,'-',sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'09',1,0))) AS "09",
decode(sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'10',1,0)),0,'-',sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'10',1,0))) AS "10",
decode(sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'11',1,0)),0,'-',sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'11',1,0))) AS "11",
decode(sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'12',1,0)),0,'-',sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'12',1,0))) AS "12",
decode(sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'13',1,0)),0,'-',sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'13',1,0))) AS "13",
decode(sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'14',1,0)),0,'-',sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'14',1,0))) AS "14",
decode(sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'15',1,0)),0,'-',sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'15',1,0))) AS "15",
decode(sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'16',1,0)),0,'-',sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'16',1,0))) AS "16",
decode(sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'17',1,0)),0,'-',sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'17',1,0))) AS "17",
decode(sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'18',1,0)),0,'-',sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'18',1,0))) AS "18",
decode(sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'19',1,0)),0,'-',sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'19',1,0))) AS "19",
decode(sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'20',1,0)),0,'-',sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'20',1,0))) AS "20",
decode(sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'21',1,0)),0,'-',sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'21',1,0))) AS "21",
decode(sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'22',1,0)),0,'-',sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'22',1,0))) AS "22",
decode(sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'23',1,0)),0,'-',sum(decode(substr(to_char(FIRST_TIME,'HH24'),1,2),'23',1,0))) AS "23"
FROM V$LOG_HISTORY /*GROUP BY SUBSTR(TO_CHAR(FIRST_TIME,'DY, YYYY/MM/DD'),1,15)*/ GROUP BY TO_DATE(SUBSTR(TO_CHAR(FIRST_TIME,'DD-Mon-YYYY'),1,15),'DD-Mon-YYYY') ORDER BY 1 DESC;

--RMAN backup jobs
SELECT R.COMMAND_ID, R.START_TIME, R.TIME_TAKEN_DISPLAY, R.INPUT_TYPE, R.STATUS, R.OUTPUT_DEVICE_TYPE, R.INPUT_BYTES_DISPLAY, R.OUTPUT_BYTES_DISPLAY, R.OUTPUT_BYTES_PER_SEC_DISPLAY
FROM (SELECT COMMAND_ID, START_TIME, TIME_TAKEN_DISPLAY, STATUS, INPUT_TYPE, OUTPUT_DEVICE_TYPE, INPUT_BYTES_DISPLAY, OUTPUT_BYTES_DISPLAY, OUTPUT_BYTES_PER_SEC_DISPLAY FROM V$RMAN_BACKUP_JOB_DETAILS ORDER BY START_TIME DESC) R WHERE ROWNUM < 32;

--DBA Jobs
set linesize 2000;
select job,log_user,last_date,this_date,next_date,broken,failures,what from dba_jobs;

--Check block corruption
SELECT * FROM V$DATABASE_BLOCK_CORRUPTION;

--Snap id for highest dbtime
SET LINES 160 PAGES 5000 TIMING ON;
COL BEGIN_INTERVAL_TIME FOR A30;
COL END_INTERVAL_TIME FOR A30;
SELECT /*+ PARALLEL(8)*/ * FROM (
  SELECT A.SNAP_ID ASNAPID, C.SNAP_ID CSNAPID, BEGIN_INTERVAL_TIME, END_INTERVAL_TIME, ROUND(TO_NUMBER((C.VALUE-A.VALUE)/1000000/60), 2) DBTIME
  FROM DBA_HIST_SYS_TIME_MODEL A, DBA_HIST_SNAPSHOT B, DBA_HIST_SYS_TIME_MODEL C WHERE A.SNAP_ID=B.SNAP_ID
  AND C.SNAP_ID=A.SNAP_ID+1 AND A.STAT_NAME=C.STAT_NAME AND UPPER(A.STAT_NAME) LIKE '%DB TIME%'
  AND B.BEGIN_INTERVAL_TIME > SYSDATE-14 AND B.END_INTERVAL_TIME <= SYSDATE
  ORDER BY TO_NUMBER((C.VALUE-A.VALUE)/1000000/60) DESC
) WHERE ROWNUM=1/*Checking dbtime for AWR, version 1.2*/;
SPOOL OFF;
SET MARKUP HTML OFF ENTMAP ON;
