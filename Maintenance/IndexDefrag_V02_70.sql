-- ------------------------------------------------------------------------------------------------------------------
--
-- This is a "Tool" to analyse Index-Fragmentation and run, depending on the gathered fragmentation Details, 
--   eigther a Index Defrag or a Index ReBuild. The way a ReBuild will be done is controllable over the setting
--   of the @ReBuildOption calling parameter.
--
-- This script creates a Stored Procedure with name "sp_DefragIndexes" in the Master-DB which can be used
--   in any User Database context, to let it run against it, or against any other Database or against ALL Databases.
-- 
-- This Stored Procedure will run under SQL Server 2005 and later (including SQL Server 2012).
-- 
-- CREATED BY:        Franz Robeller
-- CREATE DATE:       09.11.2005
-- LAST MODIFY DATE:  11.06.2012
-- VERSION:           02.70
--
-- ------------------------------------------------------------------------------------------------------------------

use master
go

SET ANSI_NULLS ON;
GO
SET ANSI_WARNINGS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO


if  (select OBJECTPROPERTY ( object_id(N'dbo.sp_DefragIndexes'), N'IsProcedure' )) IS NOT NULL
    drop procedure [dbo].[sp_DefragIndexes];
GO


create procedure [dbo].[sp_DefragIndexes]
                            (@MaxWorkTime                 int = 180,
                             @ToDoDatabaseList  nvarchar(128) = NULL,
                             @ToDoDatabaseId         smallint = NULL,
                             @ToDoObjectId                int = 0,
                             @ToDoIndexId                 int = NULL,
                             @ReBuildOption          smallint = 2,
                             @MaxDop                      int = NULL,
                             @LobCompaction               bit = NULL,
                             @PreferUsedIndexMode     tinyint = 2,
                             @AllowLogGrowth              bit = 1,
                             @Debug                  smallint = 0
                            )
AS
-- ------------------------------------------------------------------------------------------------------------------
--
-- Parameter  @MaxWorkTime:
--                  <value>  - any value >15 means: we don't Defrag or Rebuild indices longer that this value in minutes!
--                             However already started index Defrags or Rebuilds runs will not be stopped!
--
-- Parameter  @ToDoDatabaseList:
--                    NULL   - (default) ignore this parameter
--                  <value>  - run it for the Database IDs in this comma seperated list of database IDs!
--                             (The processing of the Databases will be in the order of the database IDs
--                              defined in this paramter, however the database defined over parameter @ToDoDatabaseId
--                              will always be processed first. System databases will only be processed if explicitly
--                              requested, not implicitly over wild cards.)
--
-- Parameter  @ToDoDatabaseId:
--                    NULL   - (default) run it for all User Databases
--                     0     - run it for the current Database context only
--                    >0     - run it for the Database with the DB_ID() equal the Value of this Parameter
--
-- Parameter  @ToDoObjectId:
--                    NULL   - run it for all User Databases Objects (eigther Tables or Indexed Views)
--                     0     - (default) run it for all User Databases Objects (same as NULL)
--                    >0     - run it for the User Databases Object with the OBJECT_ID() equal the Value of this Parameter
--
-- Parameter  @ToDoIndexId:
--                    NULL   - (default) run it for all Indices
--                    >=0    - run it for the index_id equal the Value of this Parameter
--
-- Parameter  @ReBuildOption:
--                    -1     - ReBuild runs always OFFLINE
--                     0     - ReBuild runs ONLINE if possible, otherwise the ReBuild will run OFFLINE
--                     1     - ReBuild runs ONLY ONLINE if possible, otherwise a REORGANZIZE will be
--                             done if the Logical Fragmentation is high enougth!
--                     2     - (default) A ReBuild of CLUSTERED Indices will NEVER be done,
--                             a ReBuild of NON-CLUSTERED Indices will be done ONLY if it is possible to do it ONLINE,
--                             otherwise a REORGANZIZE will be done if the Logical Fragmentation is high enougth!
--                     3     - A ReBuild will NEVER be done! Under no circumstances, always a REORGANZIZE
--                             will be done if the Logical Fragmentation is high enougth!
--
-- Parameter  @MaxDop  = xxx - This does set the used MAXDOP value for a index REBUILD command,
--                             the accepted limits of this values depend on the setting of the parameter @ReBuildOption
--                             and how many CPUs are used by SQL Server
--
-- Parameter  @LobCompaction - desides how the REORGANIZE Parameter 'LOB_COMPACTION' will be set (ONLY for SQL 2005 or later)
--                    NULL   - (default) means AUTO, let's the SP deside what to do, small BLOBs will 
--                             have LOB_COMPACTION = OFF, larger BLOBs will have LOB_COMPACTION = ON
--                     0     - if an index had a BLOB field, always use LOB_COMPACTION = OFF
--                     1     - if an index had a BLOB field, always use LOB_COMPACTION = ON
--
-- Parameter  @PreferUsedIndexMode - desides how used indices are prefered (ONLY for SQL 2005 and later and ONLY if SQL Server did run at least for 24 hours)
--                     0     - don't care if indices are used or not
--                     1     - prefer used indices, but if it is still time, maintain the other indices also
--                     2     - (default) maintain used indices only 
--
-- Parameter  @AllowLogGrowth:
--                     0     - do NOT grow the Transaction LOG files to run index maintainance commands 
--                             ==> In case the availlable space is not large enougth then do not run the command!
--                     1     - (default) consider to grow the Transaction LOG files to run index maintainance commands
--                             Worst case, the T-LOG files could grow to the upper limit configured in the T-LOG file settings!
--
-- Parameter  @Debug:
--                    <= 0   - Means in general to DO the Index Maintainance work - otherwise same meaning as positive values
--                    > 0    - Means in general NOT to DO the Index Maintainance job execution,
--                             helpful to get information about what WOULD be done!
--                    NULL   - DO the Index Maintainance - but no DebugInfo (identical to 0)
--                     0     - (default) DO THE INDEX MAINTAINANCE - but no additional information will be provided
--                     1     - additional DebugInfo! (returns also the SQL Statements)
--                     2     - additional DebugInfo! (returns also the helping temp. table and MASTER DB compat Level)
--                     3     - additional DebugInfo! (returns also the desition information for Rebuild Option)
--
-- ------------------------------------------------------------------------------------------------------------------
-- ------------------------------------------------------------------------------------------------------------------
-- 
-- Disclaimer : This is SAMPLE code and you use it on your own risk. 
--              It is the sole intention of this code to provide a proof of concept as a learning tool
--              for Microsoft Customers. Microsoft does not warranty or guarantee any portion
--              of this code and is NOT responsible for any affects it may have on any system it is executed on or 
--              environment it resides within.
--              Please use this code at your own discretion!
-- 
-- ===> Feedback to EMail: franzro@microsoft.com
-- 
-- ------------------------------------------------------------------------------------------------------------------
Declare @oldStatus int, @orgdbid smallint, @master_db_compat tinyint, @sql nvarchar(max);

create table #IndexInfo
    (Done int NULL,
     Action nvarchar(25) NULL,
     RebuiltOnline bit   NULL,
     DBId int NULL,
     compatibility_level int NULL,-- is_db_cdc_enabled tinyint null,
     ObjectName sysname  COLLATE Latin1_General_CS_AS NULL,
     ObjectId int,
     IndexName sysname  COLLATE Latin1_General_CS_AS NULL,
     IndexId int,
     SchemaName sysname  COLLATE Latin1_General_CS_AS NULL,
     SchemaId int null,
     AllocUnitTypeDesc nvarchar(60) null,
     has_blob_column bit,
     [blob_pages_percent_total_pages_used] float null,
     blob_pages bigint null,
     [allow_page_locks] bit NULL,
     [is_index_used_by_cdc] bit NULL,
     [is_primary_key_index] bit NULL,
     [PartitionNumber] int null, 
     [MaxPartitionNumber] int null,
     [Level] int null,
     [data_pages_class] int null,
     [rows_per_page] bigint null,
     [percent_total_pages_used] float null,
     [data_pages] bigint null,
     Pages bigint null,
     FragmentCount bigint null, FutureFragmentCount bigint null,
     AvgFragmentSizeInPages float null, FutureAvgFragmentSizeInPages float null,
     FragmentRatio float null, FutureFragmentRatio float null,
     LogicalFragmentation float null, ExtentFragmentation float null,
     [user_reads] [bigint] NULL,
     [last_user_read] [datetime] NULL,
     [user_updates] [bigint] NULL,
     [last_user_update] [datetime] NULL,
     [system_reads] [bigint] NULL,
     [last_system_read] [datetime] NULL,
     [system_updates] [bigint] NULL,
     [last_system_update] [datetime] NULL,
     fragmentation_calc_time_minutes float null,
	 defragmentation_time_minutes float null,
	 trancount int NULL,
     ScanDensity float null, BestCount bigint null,
     ActualCount bigint null, Extents bigint, ExtentSwitches bigint, Rows bigint null,
     MinimumRecordSize int null, MaximumRecordSize int null, AverageRecordSize float null,
     ForwardedRecords bigint null, AverageFreeBytes float, AveragePageDensity float null
    );
create clustered index CL_IDX on #IndexInfo (DBId, ObjectId, IndexId);

--------------------------------------------------------------------------------------------------------
-- find out the old NOCOUNT setting, we need it to be able to restore it at the end. During the run of this SP we switch it to ON!
if @@OPTIONS & 512 = 0
BEGIN
  select @oldStatus = @@OPTIONS & 512;
  set nocount on;
END;
--------------------------------------------------------------------------------------------------------

--akzeptable Limits:
declare @LimNumPages bigint, @LimNumBlobPages bigint, @LimPercentBlobPagesUsed float, /*@LimFragments int,*/ @LimFragmentRatio float,
        @LimFragSize float, @LimScanDensity float, @LimLogFragmentationReOrg float, @LimLogFragmentationRebuild float,
        @Max_IdxDefrag_ResearchTime float, @SqlEdt int, @OnlinePossible bit, @LimitedIndexMaxAge smallint, @CDCProblemExists bit;
select @LimNumPages     = 1024,            -- Don't touch Tables, in MIXED EXTENTS (1 Extent = 8 Pages - if we have more than 8 Pages in a Table or indexed View, then we get a dedicated Extent!)
                                           --   BUT the tables, we touch, should have at least 1024 pages (128 Extents)
       @LimNumBlobPages = 10240,           -- Don't do LOB_COMPACTION if the BLOB Heap has less than this amount of data pages!
       @LimPercentBlobPagesUsed = 80.0,    -- Don't do LOB_COMPACTION if the BLOB's used_pages/total_pages in percent is obove this limit"
       @LimFragmentRatio = 13.0,           -- EXTENT FRAGMENTATION (SQL 2005): if we have to many Fragments (>13% of the Ration of Fragments/Pages) ...
       @LimFragSize = 31.0,                -- EXTENT FRAGMENTATION (SQL 2005): <(4*8 = 32)-1 - ... or if they don't have at least 4 Extents in a Fragment, important for 256 KB Read activity - (EXTENT FRAGEMENTIERUNG (SQL 2005) ==> Index ReBuild (for SQL 2005)
       @LimLogFragmentationReOrg = 20.0,   -- PAGE FRAGEMENTIERUNG: recomended > 20.0% - Indices with large PAGE FRAGEMENTATION ==> Index Defrag/ReOrganize (for SQL 2000 and later)
       @LimLogFragmentationRebuild = 30.0, -- PAGE FRAGEMENTIERUNG: recomended > 30.0% - Indices with large PAGE FRAGEMENTATION, a lot of Index fragments or if we can not REORG an index ==> Index ReBuild (for SQL 2005 and later)
       @Max_IdxDefrag_ResearchTime = 5.0,  -- FOR SQL 2005 only: this is the maximum amount of time (in percent) of the total @MaxWorkTime
                                           -- here, running maximum 5% of the total defrag time for the fragmentation research
       @SqlEdt = convert(int, SERVERPROPERTY (N'EngineEdition')),  -- 3 = Enterprise (This is returned for Datacenter, Enterprise, Enterprise Evaluation, and Developer.)
       @LimitedIndexMaxAge = 168;          -- This is a value in hours, for SQL 2005 and later, this drives for LimitedByIndexUseage to Indices which are used in the last XXX hours.

--------------------------------------------------------------------------------------------------------
IF (   (@SqlEdt = 3)  -- 3 = Enterprise (This is returned for Datacenter, Enterprise, Enterprise Evaluation, and Developer.)
   )
    select @OnlinePossible = 1;
else
    select @OnlinePossible = 0;
--------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------
-- Which Database do we need to optimize, if not given??
-- OK, this ugly code works also with SQL Server 2000 which is still supported in this version
select @orgdbid = @ToDoDatabaseId;
if @ToDoDatabaseId = 0
    select @ToDoDatabaseId = db_id(); -- means THIS DB, NULL means ALL DBs
-- Which Databases do we need to optimize, if not given?? - Here you can specify a range of DB_IDs
-- first get the numbers from the @ToDoDatabaseList
--    a string, separated by commas
CREATE TABLE #ToDbList (ord int, database_id smallint, is_auto_update_stats_on bit, [compatibility_level] tinyint, [schema_retieval_error] int, [err_statement] smallint, [Reason] nvarchar(1000) );
declare @I int, @ch NCHAR(1), @NumStr NVARCHAR(35), @NumSmInt smallint;
IF (@ToDoDatabaseList IS NOT NULL)
  BEGIN
    select @I=1, @NumStr = N'';
    -- go through the @ToDoDatabaseList character by character
    WHILE (@I <= LEN(@ToDoDatabaseList))
      BEGIN
        SELECT @ch = SUBSTRING(@ToDoDatabaseList, @I, 1);
        -- replace other common list seperators with a comma
        IF @ch in (N';', N' ', N':')
          select @ch = N','; -- replace delimiter (whitespaces) with the well known ',' (comma) seperator
        IF @ch IN (N'0', N'1', N'2', N'3', N'4', N'5', N'6', N'7', N'8', N'9', N',') -- ignore all other characters!
          BEGIN
            IF (@ch <> N',')
                select @NumStr = @NumStr + @ch;  -- build up the string which represents a number
            IF (@ch = N',' OR @I = LEN(@ToDoDatabaseList))
              BEGIN
                IF LEN(@NumStr) > 0  -- avoid to get a 0 in case of an empty string
                  BEGIN
                    -- now we got the number and we need to convert it to an SMALLINT
                    select @NumSmInt = CONVERT(smallint, @NumStr);
                    --  and stick it into the list table
                    -- but make sure, that we do not get duplicates
                    IF    (NOT EXISTS (select database_id from #ToDbList where database_id = @NumSmInt))
                        INSERT #ToDbList (ord, database_id, is_auto_update_stats_on, [compatibility_level])
                          -- make sure: first,  that the @ToDoDatabaseId entry is the first in the order
                          --            second, we only should get entries where the DB_ID does really exist
                          --            third,  preserve the order, this is done implicitly by usint @I as order column content
                          select @I, @NumSmInt, is_auto_update_stats_on, [compatibility_level]
                            from sys.databases WITH (NOLOCK)
                              where   database_id = @NumSmInt
                                and   [is_read_only]  = 0            -- only touch databases which are not "read only"
                                and   [is_in_standby] = 0            -- only touch databases which are not in standby
                                and   [user_access]   = 0            -- do not touch DBs which are in SINGLE_USER mode
                                and   [state]         = 0            -- only touch DBs which are ONLINE (databases which are NOT RESTORING, NOT RECOVERING, NOT RECOVERY_PENDING, NOT SUSPECT, NOT in EMERGENCY mode AND NOT OFFLINE)
                                and   [source_database_id] is null   -- no DATABASE SNAPSHOTS
                                AND (    (@ToDoDatabaseId IS NULL)   -- ADD it when the @ToDoDatabaseId is NULL then we add everything and do not care about prefering DBs commin in over @ToDoDatabaseId
                                      OR (@NumSmInt <> @ToDoDatabaseId)       -- OR we have a regular User DB not requested over @ToDoDatabaseId, is requested over @ToDoDatabaseId we do not add it here, becuase we want to process this DB first
                                      OR (     (@NumSmInt = @ToDoDatabaseId)  -- OR we have requested the DB over @ToDoDatabaseId (eighter explicitly or imlicitly)
                                           AND ((is_distributor = 1) OR (@NumSmInt in (1,2,3,4)))  -- and it is a system db or distribution db
                                           AND (@orgdbid <> @ToDoDatabaseId))   -- and db not explicitly requested over @ToDoDatabaseId (but implicitly over the value 0)
                                         );                                     -- in that case we would not add the DB later on! So we do it here, 
                                                                                -- otherwise we would miss it! If not, we let add the DB later on, so that it will 
                                                                                -- be handled FIRST, if s.o. requests a DB over @ToDoDatabaseId explicitly, then we process it first
                                                                                -- in ALL OTHER CASES, we preserve the order of the DB_IDs mentioned in the string and add it here!
                  END;
                select @NumStr = N'';
              END;
          END;
        SELECT @I = @I + 1;
      END;
  END;
--------------------------------------------------------------------------------------------------------
-- second the old stuff without @ToDoDatabaseList support
--   - and ensure that this is the first DBs to be handled! If we do not have it already
insert #ToDbList (ord, database_id, is_auto_update_stats_on, [compatibility_level])
  select distinct CASE WHEN @ToDoDatabaseId IS NULL THEN 32767 ELSE -1 END,
         database_id, is_auto_update_stats_on, compatibility_level
   from master.sys.databases WITH (NOLOCK)
    where   [is_read_only]  = 0            -- only touch databases which are not "read only"
      and   [is_in_standby] = 0            -- only touch databases which are not in standby
      and   [user_access]   = 0            -- don't touch DBs which are in SINGLE_USER mode
      and   [state]         = 0            -- only touch DBs which are ONLINE (databases which are NOT RESTORING, NOT RECOVERING, NOT RECOVERY_PENDING, NOT SUSPECT, NOT in EMERGENCY mode AND NOT OFFLINE)
      and   [source_database_id] is null   -- no DATABASE SNAPSHOTS
      and (    (    ([database_id] not in (1,2,3,4))   -- no Systemdatabases, only when explicitly requested]
                AND (is_distributor = 0)   -- and no distribution database
               )
            OR (([database_id] = ISNULL(@ToDoDatabaseId, [database_id])) AND (@orgdbid IS NOT NULL) AND (@orgdbid <> 0)) -- or explicitly requested
          )
      and   ISNULL(@ToDoDatabaseId, database_id) = database_id
      and   database_id not in (select database_id from #ToDbList);
----------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------
-- Which User Databases Objects (eigther Tables or Indexed Views) do we need to optimize??
if (@ToDoObjectId < 0) OR (@ToDoObjectId IS NULL)
    select @ToDoObjectId = 0; -- means all User Databases Objects
--------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------
-- Which Index with which index_id do we need to optimize
if @ToDoIndexId < 0
    select @ToDoIndexId = NULL; -- means all Indices
--------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------
-- Makes the max. Index Maintainance "Running Time" setting sence, minimum is this value!!
if ISNULL(@MaxWorkTime, 0) < 15
    select @MaxWorkTime = 15;

-- Check all other parameters, too!
if ((ISNULL(@Debug, 99) <= -4) OR (ISNULL(@Debug, 99) >= 4))
    select @Debug = 0;
if (ISNULL(@ReBuildOption, -1) not in (-1, 0, 1, 2, 3))
    select @ReBuildOption = 2;
--------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------
-- Find out which SQL Version we have?
declare @sqlver nvarchar(50), @sqltmpver nvarchar(50), @SQL_Major_Version smallint, @SQL_Minor_Version smallint, @SQL_Build_Number smallint;
select @sqlver = convert(nvarchar(50),serverproperty(N'ProductVersion'));
select @SQL_Major_Version = convert(smallint, substring(@sqlver , 1, charindex(N'.', @sqlver, 0)-1));
declare @NumCPUs int, @sql_start_time datetime;
select @sqltmpver = substring(@sqlver , charindex(N'.', @sqlver, 0)+1, LEN(@sqlver));
select @SQL_Minor_Version = convert(smallint, substring(@sqltmpver , 1, CASE WHEN charindex(N'.', @sqltmpver, 0) = 0
                                                                             THEN len(@sqltmpver)
                                                                             ELSE charindex(N'.', @sqltmpver, 0)-1 END
                                                       ));
select @sqltmpver = substring(@sqltmpver , charindex(N'.', @sqltmpver, 0)+1, LEN(@sqltmpver));
select @SQL_Build_Number = convert(smallint, substring(@sqltmpver , 1, CASE WHEN charindex(N'.', @sqltmpver, 0) = 0
                                                                            THEN len(@sqltmpver)
                                                                            ELSE charindex(N'.', @sqltmpver, 0)-1 END
                                                      ));
--------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------
--                      !!! SQL 2000 is no longer supported !!!
IF (@SQL_Major_Version <= 8)
  RAISERROR (N'!!! SQL 2000 is no longer supported !!!', 16, 1);
--------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------
-- Find out if we have the CDC problem?
IF (@SQL_Major_Version >= 10)
  IF (    ((@SQL_Major_Version = 10) AND (@SQL_Minor_Version =  0) AND (@SQL_Build_Number >= 2757))  -- this is fixed in SQL 2008    SP1 CU6!
       OR ((@SQL_Major_Version = 10) AND (@SQL_Minor_Version = 50) AND (@SQL_Build_Number >= 1702))  -- this is fixed in SQL 2008 R2 RTM CU1!
	   OR ((@SQL_Major_Version = 10) AND (@SQL_Minor_Version > 50))  -- we simply assume that this is also in all later versions fixed before SQL 11!
       OR (@SQL_Major_Version  > 10)  -- this is fixed in SQL 11 (tested with build 1103 - CTP1)
     )
    select @CDCProblemExists = 0; -- In this versions the CDC problem is fixed!
  ELSE
    select @CDCProblemExists = 1; -- For ALL older SQL 2008 and SQL 2008 R2 versions we do have the CDC Problem!
ELSE
  select @CDCProblemExists   = 0; -- For SQL 2000 and SQL 2005 we don't have CDC, so we also have no problem with it!
--------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------
    --checking @maxdop
    exec sp_executesql N'select @NumCPUs = MAX(scheduler_id)+1 from sys.dm_os_schedulers WITH(NOLOCK) where status = N''VISIBLE ONLINE''', N'@NumCPUs int OUTPUT', @NumCPUs OUTPUT;
    IF (@ReBuildOption <= 0)
      BEGIN
        -- if the parameter @ReBuildOption is smaller or equal 0 then the user does not care about concurrency, then we can use all CPUs
        -- default would be to use all CPUs
        IF (ISNULL(@MaxDop, 65536) > @NumCPUs)     -- make sure we do not use more CPUs than we have
          select @MaxDop = @NumCPUs;
        IF (ISNULL(@MaxDop, 65536) < 1)            -- make sure we use at least one CPU
          select @MaxDop = 1;
      END
    ELSE
      BEGIN
        -- otherwise concurrency is much more importand than speed
        -- default would be to use 4 CPUs or half of the availlable CPUs
        IF (ISNULL(@MaxDop, 65536) > 4)            -- make sure we do not use more than 4 CPUs
          select @MaxDop = 4;
        IF (ISNULL(@MaxDop, 65536) > (@NumCPUs/2)) -- make sure we do not use more than half of the CPUs
          select @MaxDop = @NumCPUs/2;
        IF (ISNULL(@MaxDop, 65536) < 1)            -- make sure we use at least one CPU
          select @MaxDop = 1;
      END;

    -- Check valid range for @PreferUsedIndexMode
    -- Make sure that the @PreferUsedIndexMode setting is in the valid range and is not NULL
    IF ((@PreferUsedIndexMode IS NULL) OR (@PreferUsedIndexMode < 0) OR (@PreferUsedIndexMode > 2))
      select @PreferUsedIndexMode = 2;  --default setting is 2 so we set it to this value
    -- Make sure that the @PreferUsedIndexMode setting is ONLY set, if the server did run at least 24 hours
    exec sp_executesql N'select @sql_start_time = login_time from sys.dm_exec_sessions WITH(NOLOCK) where session_id = 1;', N'@sql_start_time datetime OUTPUT', @sql_start_time OUTPUT;
    IF @PreferUsedIndexMode <> 0
      BEGIN
        IF (@sql_start_time >= dateadd(hh, -24, getdate()))  -- 24 hours should have run SQL server
          select @PreferUsedIndexMode = 1; -- set to 1 if SQL Server does not run long enougth
      END;
--------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------
IF ((@Debug > 2) OR (@Debug < -2))
  select @SQL_Major_Version AS SQL_Major_Version, @SQL_Minor_Version AS SQL_Minor_Version, @SQL_Build_Number AS SQL_Build_Number, @sqlver AS SQL_Version, @CDCProblemExists AS CDCProblemExists,
         @NumCPUs as NumCPUs, CASE WHEN @sql_start_time >= dateadd(hh, -24, getdate()) THEN 0 ELSE 1 END as SQL_Runs_Over_24h, @sql_start_time as SQL_Server_Start_DateTime;
ELSE IF ((@Debug > 1) OR (@Debug < -1))
  select @SQL_Major_Version AS SQL_Major_Version, @NumCPUs as NumCPUs, CASE WHEN @sql_start_time >= dateadd(hh, -24, getdate()) THEN 0 ELSE 1 END as SQL_Runs_Over_24h;
--------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------
-- now we need to collect fragmentation information, together with some Meta Data from each database and each table
DECLARE @c_dbid int, @c_compatibility_level tinyint, @Existing_MaxIndexHandle bigint;
DECLARE @severity smallint, @state smallint, @err_num int, @err_msg nvarchar (1000);

declare cIdxDBCur cursor for
  select database_id, [compatibility_level]
    from #ToDbList order by ord
    
open cIdxDBCur;
if @@error = 0
BEGIN
  ---------------------------------------------------------------------------
  -- BEGIN of collecting Meta Data
  fetch next from cIdxDBCur into @c_dbid, @c_compatibility_level;
  while @@fetch_status <> -1
    BEGIN
      select @severity = 0, @state = 0, @err_num = 0, @err_msg = NULL;

      IF (@@fetch_Status = 0)
        BEGIN
          ---------------------------------------------------------------------------
          -- get SQL object information!
          select @sql = N'select sps.database_id, '+convert(nvarchar(13),@c_compatibility_level)+N' AS compatibility_level,
  st.name AS ObjectName,sps.object_id,sps.name AS IndexName,sps.index_id,
  sch.name AS SchemaName,st.schema_id,partition_number,sp.MaxPartitionNumber,ISNULL(sbc.has_blob_column, 0) AS has_blob_column,
  sps.allow_page_locks,sps.data_pages,sps.rows_per_page,sps.type_desc,sps.is_primary_key_index,sps.percent_total_pages_used
from'+
N' (select '+convert(nvarchar(13),@c_dbid)+N' as database_id,s.object_id,s.index_id,s.IndexName as name,s.partition_number,s.data_space_id,s.rows,s.type,s.data_pages,
  CASE WHEN ISNULL(s.data_pages, 0) = 0 THEN 0 ELSE ISNULL(s.rows, 0) END/COALESCE(CASE WHEN s.data_pages = 0 THEN NULL ELSE s.data_pages END,1) AS rows_per_page,
  s.is_hypothetical,s.is_disabled,s.allow_page_locks,s.type_desc,s.is_primary_key_index,s.percent_total_pages_used
 from
 (select si.name as IndexName,p.object_id,p.index_id,p.partition_number,au.data_space_id,p.rows,au.type,COALESCE(CASE WHEN au.data_pages = 0 THEN NULL ELSE au.data_pages END, CASE WHEN au.used_pages = 0 THEN NULL ELSE au.used_pages END,au.total_pages) as data_pages,
   si.is_hypothetical,si.is_disabled,si.allow_page_locks,au.type_desc,si.is_primary_key as is_primary_key_index, ((1.0 * ISNULL(CASE WHEN au.used_pages = 0 THEN NULL ELSE au.used_pages END, 1))/ISNULL(CASE WHEN au.total_pages = 0 THEN NULL ELSE au.total_pages END, 1)) as percent_total_pages_used
  from ['+db_name(@c_dbid)+N'].sys.allocation_units as au with (NOLOCK)
   join ['+db_name(@c_dbid)+N'].sys.partitions as p with (NOLOCK) on au.container_id = CASE WHEN au.type in (1,3) THEN p.hobt_id WHEN au.type = 2 THEN p.partition_id END and au.type <> 0
   join ['+db_name(@c_dbid)+N'].sys.indexes as si with (NOLOCK) on si.object_id = p.object_id and si.index_id = p.index_id AND (si.index_id'+
   CASE WHEN @ToDoIndexId IS NOT NULL THEN N' = '+CONVERT(nvarchar(35), @ToDoIndexId) ELSE N' <> 0' END+N')'+
   N' and si.type in (0, 1, 2)
 ) as s ';
select @sql = @sql + 
N'
) AS sps
join (
 SELECT object_id,schema_id,name,is_ms_shipped' + 
  CASE WHEN @SQL_Major_Version >= 10 THEN N',is_tracked_by_cdc' ELSE N',0 AS is_tracked_by_cdc' END + N'
  FROM ['+db_name(@c_dbid)+N'].sys.tables WITH(NOLOCK)
 UNION ALL SELECT object_id,schema_id,name,is_ms_shipped' + 
  CASE WHEN @SQL_Major_Version >= 10 THEN N',is_tracked_by_cdc' ELSE N',0 AS is_tracked_by_cdc' END + N'
  FROM ['+db_name(@c_dbid)+N'].sys.views WITH(NOLOCK)
 )  AS st on (sps.object_id = st.object_id)'+
CASE WHEN ISNULL(@ToDoObjectId, 0) <> 0 THEN N' AND (st.object_id = '+CONVERT(nvarchar(35), @ToDoObjectId)+N')' ELSE N'' END+N'
join ['+db_name(@c_dbid)+N'].sys.schemas AS sch WITH(NOLOCK) on (sch.schema_id = st.schema_id)
join (select spi.object_id, spi.index_id, max(spi.partition_number) AS MaxPartitionNumber from ['+db_name(@c_dbid)+N'].sys.partitions AS spi WITH(NOLOCK) group by spi.object_id, spi.index_id ) AS sp
 on sp.object_id = sps.object_id and sp.index_id = sps.index_id
left outer join
 (';
select @sql = @sql +  
N'select object_id,index_id,has_blob_column from
  (select sc.object_id,sic.index_id AS index_id,1 AS has_blob_column
  from ['+db_name(@c_dbid)+N'].sys.columns AS sc WITH(NOLOCK) join ['+db_name(@c_dbid)+N'].sys.index_columns AS sic WITH(NOLOCK)
   on sic.object_id = sc.object_id and sic.column_id = sc.column_id
   where (sc.[system_type_id] IN (34, 35, 99, 241) OR (sc.[system_type_id] IN (165 , 167, 231, 240) AND sc.max_length = -1 ) )
  UNION ALL select sc.object_id,NULL AS index_id,1 AS has_blob_column
  from ['+db_name(@c_dbid)+N'].sys.columns AS sc WITH(NOLOCK)
   where (sc.[system_type_id] IN (34, 35, 99, 241) OR ( sc.[system_type_id] IN (165 , 167, 231, 240) AND sc.max_length = -1 ) )
  ) AS SOC
  group by object_id,index_id,has_blob_column
 ) AS sbc
 on sbc.object_id = sps.object_id and ISNULL(sbc.index_id, CASE sps.index_id WHEN 1 THEN 1 WHEN 0 THEN 0 END) = sps.index_id
where sps.is_hypothetical = 0'+  -- do not touch HYPOTHETICAL indices
N' and sps.is_disabled = 0'+     -- do not touch DISABLED indices
N'
 order by sps.object_id, sps.index_id;';
          BEGIN TRY
            insert #IndexInfo (DBId, compatibility_level, ObjectName, ObjectId, IndexName, IndexId,
                               SchemaName, SchemaId, PartitionNumber, MaxPartitionNumber, has_blob_column,
                               [allow_page_locks], [data_pages], [rows_per_page], AllocUnitTypeDesc, [is_primary_key_index],
                               [percent_total_pages_used]
                              )
              exec (@sql);
              select @err_num = @@error;
          END TRY
          BEGIN CATCH
            -- Error message into the SQL Server Errorlog
            select @severity = Error_Severity(), @state = Error_State(), @err_num = Error_Number(), @err_msg  = Error_Message();
          END CATCH
          UPDATE #ToDbList set [schema_retieval_error] = @err_num,
                               [Reason]        = @err_msg,
                               [err_statement] = CASE WHEN @err_num <> 0 THEN 1 ELSE 0 END
            WHERE database_id = @c_dbid;
          ---------------------------------------------------------------------------
               
          ---------------------------------------------------------------------------
          -- Get information about which INDEX is used in for CDC (change data capture)
          IF (@SQL_Major_Version >= 10)
            BEGIN
              -- ONLY FOR SQL Server 2008 and later!
              -- first lets look into the Database Info where is_cdc_enabled is set
              select @sql = N'DECLARE @is_cdc_enabled tinyint;
                SELECT @is_cdc_enabled = db.is_cdc_enabled
                  FROM master.sys.databases as db WITH(NOLOCK)
                    WHERE db.database_id = '+convert(nvarchar(35), @c_dbid)+N';
                IF (ISNULL(@is_cdc_enabled, 0) <> 0)
                  BEGIN
                    CREATE TABLE #testcdc
                    (source_schema  sysname COLLATE Latin1_General_CS_AS NULL, source_table sysname COLLATE Latin1_General_CS_AS NULL, 
                    capture_instance sysname COLLATE Latin1_General_CS_AS NULL, object_id int,
                    source_object_id int, start_lsn binary(10), end_lsn binary(10), supports_net_changes bit, has_drop_pending bit,
                    role_name sysname COLLATE Latin1_General_CS_AS null, index_name sysname COLLATE Latin1_General_CS_AS null, 
                    filegroup_name sysname COLLATE Latin1_General_CS_AS null, create_date datetime, index_column_list nvarchar(max) COLLATE Latin1_General_CS_AS null,
                    captured_column_list nvarchar(max) COLLATE Latin1_General_CS_AS null
                    );
                    INSERT #testcdc
                      EXEC ['+db_name(@c_dbid)+N'].sys.sp_cdc_help_change_data_capture;
                    UPDATE #IndexInfo
                        SET [is_index_used_by_cdc] = 1
                      FROM #testcdc AS tc WITH(NOLOCK)
                        WHERE #IndexInfo.DBId      = '+convert(nvarchar(35), @c_dbid)+N'
                          AND #IndexInfo.ObjectId  = tc.source_object_id
                          AND #IndexInfo.IndexName = tc.index_name            COLLATE Latin1_General_CS_AS
                          AND #IndexInfo.AllocUnitTypeDesc = N''IN_ROW_DATA'' COLLATE Latin1_General_CS_AS
                          AND #IndexInfo.is_index_used_by_cdc is null;
                    DROP TABLE #testcdc;
                  END;';
              BEGIN TRY
                exec (@sql);
              END TRY
              BEGIN CATCH
				-- Error message into the SQL Server Errorlog
				select @severity = Error_Severity(), @state = Error_State(), @err_num = Error_Number(), @err_msg  = Error_Message();
			    UPDATE #ToDbList set [schema_retieval_error] = @err_num,
                                     [Reason]        = @err_msg,
                                     [err_statement] = 2
                  WHERE database_id = @c_dbid;
              END CATCH
            END;
              
          -- second lets mark all remaining records of this database
          select @sql = N'
                UPDATE #IndexInfo
                    SET [is_index_used_by_cdc] = 0
                  WHERE DBId = '+convert(nvarchar(35), @c_dbid)+N'
                    AND is_index_used_by_cdc is null;';
          BEGIN TRY
            exec (@sql);
          END TRY
          BEGIN CATCH
			-- Error message into the SQL Server Errorlog
			select @severity = Error_Severity(), @state = Error_State(), @err_num = Error_Number(), @err_msg  = Error_Message();
		    UPDATE #ToDbList set [schema_retieval_error] = @err_num,
                                 [Reason]        = @err_msg,
                                 [err_statement] = 3
              WHERE database_id = @c_dbid;
          END CATCH
          -- END of - information gathering about which INDEX is used in for CDC
          ---------------------------------------------------------------------------
              
          ---------------------------------------------------------------------------
        END; -- end of IF ((@@fetch_Status = 0) AND (IsNULL(@ToDoDatabaseId, @c_dbid) = @c_dbid))
      fetch next from cIdxDBCur into @c_dbid, @c_compatibility_level;
    END;
  close cIdxDBCur;
END;
deallocate cIdxDBCur;
--------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------
-- calculate the data_pages_class
--------------------------------------------------------------------------------------------------------
update #IndexInfo
  set data_pages_class = CASE WHEN                                 data_pages <=            128*1024 THEN  0
                              WHEN data_pages >       128*1024 AND data_pages <=         1*1024*1024 THEN  1
                              WHEN data_pages >    1*1024*1024 AND data_pages <=         2*1024*1024 THEN  2
                              WHEN data_pages >    2*1024*1024 AND data_pages <=         4*1024*1024 THEN  3
                              WHEN data_pages >    4*1024*1024 AND data_pages <=        16*1024*1024 THEN  4
                              WHEN data_pages >   16*1024*1024 AND data_pages <=        32*1024*1024 THEN  5
                              WHEN data_pages >   32*1024*1024 AND data_pages <=        64*1024*1024 THEN  6
                              WHEN data_pages >   64*1024*1024 AND data_pages <=       512*1024*1024 THEN  7
                              WHEN data_pages >  512*1024*1024 AND data_pages <=  4 * 1024*1024*1024 THEN  8
                              ELSE 10
                         END
    WHERE AllocUnitTypeDesc = N'IN_ROW_DATA';
--------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------
-- add information about the index useage
--------------------------------------------------------------------------------------------------------
IF (@PreferUsedIndexMode <> 0)   -- ignore if @PreferUsedIndexMode is set to 0
  BEGIN
    select @sql = N'update #IndexInfo
      set [user_reads]         = us.user_seeks + us.user_scans + us.user_lookups,
          [last_user_read]     = COALESCE (us.last_user_lookup, us.last_user_seek, us.last_user_scan),
          [user_updates]       = us.user_updates,
          [last_user_update]   = us.last_user_update,
          [system_reads]       = us.system_seeks + us.system_scans + us.system_lookups,
          [last_system_read]   = COALESCE (us.last_system_lookup, us.last_system_seek, us.last_system_scan),
          [system_updates]     = us.system_updates,
          [last_system_update] = us.last_system_update
      FROM sys.dm_db_index_usage_stats as us WITH(NOLOCK)
        WHERE #IndexInfo.[DBId]     = us.[database_id]
          AND #IndexInfo.[ObjectId] = us.[object_id]
          AND #IndexInfo.[IndexId]  = us.[index_id]
          AND #IndexInfo.[AllocUnitTypeDesc] = N''IN_ROW_DATA''
          AND #IndexInfo.data_pages >= '+convert(nvarchar(13), ISNULL(@LimNumPages, 32))+N';';
    exec (@sql);
  END;
--------------------------------------------------------------------------------------------------------

          
--------------------------------------------------------------------------------------------------------
-- updating the blob_pages count and blob_pages_percent_total_pages_used count
--------------------------------------------------------------------------------------------------------
  UPDATE #IndexInfo
    SET blob_pages = i2.data_pages,
        blob_pages_percent_total_pages_used = i2.percent_total_pages_used
    from #IndexInfo
      join #IndexInfo as i2
         on #IndexInfo.DBId            = i2.DBId
        and #IndexInfo.ObjectId        = i2.ObjectId
        and #IndexInfo.IndexId         = i2.IndexId
        and #IndexInfo.PartitionNumber = i2.PartitionNumber
        and #IndexInfo.AllocUnitTypeDesc =  N'IN_ROW_DATA' COLLATE Latin1_General_CS_AS
        and #IndexInfo.has_blob_column   =  1
        AND #IndexInfo.data_pages       >= ISNULL(@LimNumPages, 32)
        and i2.AllocUnitTypeDesc         =  N'LOB_DATA'    COLLATE Latin1_General_CS_AS
--------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------
--- AGAIN - Research Loop - we loop until we find something to defrag
--------------------------------------------------------------------------------------------------------
DECLARE @DBId int, @ObjectID int, @IndexID int, @PartitionID int, @again int, @start datetime,
        @Tlast datetime, @diff_minutes int, @time_over int, @Tstart datetime, @Tcount int, @PreferInnerIndexMode int, @ret_rowcount int;

-- remember when we started to Index Maintainance, importand for time based end of the index Defrags/Rebuilds!
SELECT @again = 1, @start = getdate(), @diff_minutes = 0, @time_over = 0, @PreferInnerIndexMode = @PreferUsedIndexMode;


WHILE ((@again <> 0) AND (@time_over = 0)) -- Research Loop
  BEGIN
    --------------------------------------------------------------------------------------------------------
    -- Now, we need to fill up the fragmentation information
    declare cIdxInfoCur cursor for
      select DBId, ObjectId, IndexId, PartitionNumber
            from #IndexInfo
              where ISNULL(data_pages, 0) > (ISNULL(@LimNumPages, 32) / 2)  -- this information is purly from meta data and migth be incorrect! But still, we want to have at least a minimum on pages used to evaluate DMF (sys.dm_db_index_physical_stats) 
                AND AllocUnitTypeDesc = N'IN_ROW_DATA' COLLATE Latin1_General_CS_AS  -- only for get data for real indices, no LOBs and no ROW Overflow structures
                AND Pages IS NULL  -- this data is set by using the DMF (sys.dm_db_index_physical_stats) so, having this set to NULL indicates that we have not yet got this information, it makes sure we do not fetch this information twice!
                AND Done is null   --(ISNULL(Done, 0) = 0)                -- don't re-process indexes
                AND (    (@PreferInnerIndexMode = 0)   -- ignore if @PreferUsedIndexMode is set to 0
                      OR (     (ISNULL([user_reads], 0) > 0) 
                           AND (ISNULL([last_user_read], 0) >= (dateadd(hh, -@LimitedIndexMaxAge, getdate())))) --limit index maintainance to indices unsed within the last "@LimitedIndexMaxAge" hours
                    )
            order by CASE WHEN @PreferUsedIndexMode <> 0 THEN convert(bit, ISNULL(user_reads, 0)) ELSE 0 END DESC,
                     [data_pages] ASC, PartitionNumber ASC;

    select @Tstart = GETDATE(), @Tcount = 0;
    open cIdxInfoCur;

    IF @@error = 0
    BEGIN
      fetch next from cIdxInfoCur into @DBId, @ObjectID, @IndexID, @PartitionID;

      -- we need to end the loop in case we don't find any records with NULL in the Pages column
      IF (@@fetch_status = -1)
        BEGIN
          -- if we still have time and if @PreferUsedIndexMode is set to 1, run an additional loop to maintain also unused indices, otherwise, we just stop
          IF (@PreferInnerIndexMode = 1)
            select @PreferInnerIndexMode = 0;
          ELSE
            select @again = 0;

          IF ((@Debug > 2) OR (@Debug < -2))
            print CHAR(13) + CHAR(10) + N'NO more records found!';              
        END;
        
      WHILE ((@@fetch_status <> -1) AND (@again <> 0))
        BEGIN
          IF (     (@@fetch_Status = 0)             -- if we did fetch something
               and ((1.0 * DATEDIFF(MI, @Tstart, getdate())) <= ((1.0 * @MaxWorkTime) * ((1.0 * @Max_IdxDefrag_ResearchTime) / 100.0)))  --if the evaluation time, for getting index defragmetation information, is not yet over
               and (@Tcount < (@MaxWorkTime * 2))   -- usually we do not defrag more than 2 Indices per Minute, so stop the index fragmentation evaluation if we have found enougth indices
                                                    -- if we now get to less information, then we will get additional information in the next loop run
             )
            BEGIN
              ---------------------------------------------------------------------------
              select @Tlast = getdate();
              
              select @sql = N'
                set lock_timeout 300
                update #IndexInfo 
                  set Level = index_level, Pages = page_count,
                      Rows = record_count, MinimumRecordSize = min_record_size_in_bytes,
                      MaximumRecordSize = max_record_size_in_bytes, AverageRecordSize = avg_record_size_in_bytes,
                      ForwardedRecords = forwarded_record_count,
                      LogicalFragmentation = avg_fragmentation_in_percent,
                      ExtentFragmentation =  CASE WHEN sps.index_id = 0 THEN avg_fragmentation_in_percent ELSE NULL END,
                      FragmentCount = fragment_count, 
                      AvgFragmentSizeInPages = avg_fragment_size_in_pages,
                      FragmentRatio = CASE WHEN ISNULL(page_count, 0) >= 8 THEN (convert(decimal(38,12), (100.0 * CASE WHEN ISNULL(fragment_count, 0.0) IN (0, 1) THEN 0.0 ELSE fragment_count END))/page_count) ELSE 100.0 END
                from sys.dm_db_index_physical_stats ('+convert(nvarchar(13),@DBId)+N', '+convert(nvarchar(13),@ObjectID)+N', '+convert(nvarchar(13),@IndexID)+N', '+convert(nvarchar(13),@PartitionID)+N', N''LIMITED'') AS sps
                  where ISNULL(sps.index_level, 0) = 0     -- we only care about the leaf level of fragmentation information
                    and sps.database_id = #IndexInfo.DBId
                    and sps.object_id   = #IndexInfo.ObjectId
                    and sps.index_id    = #IndexInfo.IndexId
                    and sps.partition_number = #IndexInfo.PartitionNumber
                    and sps.alloc_unit_type_desc = #IndexInfo.AllocUnitTypeDesc COLLATE Latin1_General_CS_AS;';
              BEGIN TRY
                exec (@sql);
              
                SELECT @ret_rowcount = @@ROWCOUNT;
              
                select @Tcount = @Tcount + @ret_rowcount;
                  
                -- on success                      
                UPDATE #IndexInfo
                    SET fragmentation_calc_time_minutes = (1.0 * datediff(s, @Tlast, getdate())) / 60.0
                  where DBId            = @DBId
                    and ObjectId        = @ObjectID
                    and IndexId         = @IndexID
                    and PartitionNumber = @PartitionID;
              END TRY
              BEGIN CATCH
                -- on error
                IF (XACT_STATE() = -1)
                   ROLLBACK TRAN;
                select @err_num = Error_Number();
                UPDATE #IndexInfo
                    SET Done = -@err_num,
                        fragmentation_calc_time_minutes = (1.0 * datediff(s, @Tlast, getdate())) / 60.0
                  where DBId            = @DBId
                    and ObjectId        = @ObjectID
                    and IndexId         = @IndexID
                    and PartitionNumber = @PartitionID;
              END CATCH
              -------------------------------------------------------------------------
            END; -- end of IF (@@fetch_Status = 0)
          fetch next from cIdxInfoCur into @DBId, @ObjectID, @IndexID, @PartitionID;
        END;
        
      close cIdxInfoCur;
    END;
    deallocate cIdxInfoCur;
    --------------------------------------------------------------------------------------------------------

    --------------------------------------------------------------------------------------------------------
    IF ((@Debug > 2) OR (@Debug < -2))
      print CHAR(13) + CHAR(10) + N'Evaluated fragmentation infomation of '+convert(nvarchar(25), @Tcount)+N' indices';
    --------------------------------------------------------------------------------------------------------

    --------------------------------------------------------------------------------------------------------
    -- Doing it in two steps makes the Algorithm more clear, otherwise we would need to combine a lot of fields we have already calculated
    -- Predict the future FragmentCount as it would be after a REORGANIZE, now we get it based on a 'What If'-Analisys of what can be expected, at best, after a REORGANIZE
    UPDATE #IndexInfo SET FutureFragmentCount =  CASE WHEN AvgFragmentSizeInPages IS NULL THEN NULL ELSE round(ISNULL(Pages, 0) / (round(convert(decimal(38,12), ISNULL((AvgFragmentSizeInPages/8.0), 0.0))+0.499999999999, 0 ) * 8.0)+0.499999999999, 0) END
      WHERE Pages IS NOT NULL AND (ISNULL(Pages, 0) >=  @LimNumPages)
        AND ISNULL(AvgFragmentSizeInPages , 0.0) > 0.0
        AND FutureFragmentCount IS NULL
        AND AllocUnitTypeDesc = N'IN_ROW_DATA' COLLATE Latin1_General_CS_AS;  -- only IN_ROW_DATA means, NO "BLOB Chains" and NO "Column Overflow Chains"... - this is especially for SQL 2005 important!

    -- Predict the future FragmentRatio as it would be after a REORGANIZE, now we get it based on a 'What If'-Analisys of what can be expected, at best, after a REORGANIZE
    UPDATE #IndexInfo SET FutureFragmentRatio = CASE WHEN ISNULL(Pages, 0) >= 8 THEN (convert(decimal(38,12), (100.0 * CASE WHEN ISNULL(FutureFragmentCount, 0.0) IN (0, 1) THEN 0.0 ELSE FutureFragmentCount END))/Pages) ELSE 100.0 END,
                          FutureAvgFragmentSizeInPages = CASE WHEN ISNULL(Pages, 0) >= 8 AND ISNULL(FutureFragmentCount, 0) > 0 THEN convert(decimal(38,12), Pages) / FutureFragmentCount ELSE Pages END
      WHERE Pages IS NOT NULL AND (ISNULL(Pages, 0) >=  @LimNumPages)
        AND FutureFragmentCount IS NOT NULL
        AND (    FutureFragmentRatio IS NULL
              OR FutureAvgFragmentSizeInPages IS NULL
            )
        AND AllocUnitTypeDesc = N'IN_ROW_DATA' COLLATE Latin1_General_CS_AS;  -- only IN_ROW_DATA means, NO "BLOB Chains" and NO "Column Overflow Chains"... - this is especially for SQL 2005 important!
    --------------------------------------------------------------------------------------------------------
        
    -- update statistics which should help for data retrieveal
    update statistics #IndexInfo;

    -- END of collectiong Data
    --------------------------------------------------------------------------------------------------------


    --------------------------------------------------------------------------------------------------------
    --
    -- now, we optimize fragmented indices .....
    --
    --------------------------------------------------------------------------------------------------------
    declare @SchemaName sysname, @TabName sysname, @Ownername sysname, @IndexName sysname,
            @ScanDensity float, @LogicalFragmentation float,
            @MaxPartitionID int, @AllocUnitTypeDesc nvarchar(60), @msg nvarchar(2048),
            @FragmentCount bigint, @FragmentSize float, @has_blob_column bit,
            @is_index_used_by_cdc bit, @is_primary_key_index bit,
            @FragmentRatio float, @FutureFragmentRatio float, @allow_page_locks bit, @FutureFragmentSize float,
            @Done int, @frag_calc_time float, @defrag_time float, @blob_pages_percent_total_pages_used float, @blob_pages bigint;
    declare @DoBuildIndexOnLine bit, @DoRebuildDueFragmentation bit, @WillDo nvarchar(120), 
            @sql2 nvarchar(max), @log_free_pages bigint, @log_availlable_pages bigint, @index_pages bigint, @fragmentation_calc_time_minutes float;

    DECLARE T2 CURSOR FOR
      SELECT ii.SchemaName, ii.ObjectName, ii.IndexName, ii.ScanDensity, ii.LogicalFragmentation,
             ii.PartitionNumber, ii.MaxPartitionNumber, ii.DBId, ii.AllocUnitTypeDesc,
             ii.FragmentCount, ii.AvgFragmentSizeInPages, ii.compatibility_level, ii.IndexId, ISNULL(ii.has_blob_column, 0),
             ii.FragmentRatio, ii.FutureFragmentRatio, ii.[allow_page_locks], ii.FutureAvgFragmentSizeInPages, ii.Done,
             ii.[is_primary_key_index], ii.[is_index_used_by_cdc], ii.blob_pages, ii.[blob_pages_percent_total_pages_used],
             ii.[data_pages]
        from #IndexInfo AS ii 
          where (ii.IndexId >= 1) AND (ii.Pages IS NOT NULL)                      -- NO HEAPs and no un-researched Entries (remember, unresearched could be based on research time limit!)
            AND ((ii.FutureFragmentCount IS NOT NULL) OR (@SQL_Major_Version <= 8))
            AND (ii.Done is null)                                                 -- NULL means it was not yet considerd, mask for not re-process or re-evaluate entries
            AND (ISNULL(ii.Pages, 0) >=  @LimNumPages)                            -- Touch only Indices this amount of pages
            AND (    (@PreferInnerIndexMode = 0)   -- ignore if @PreferUsedIndexMode is set to 0
                  OR (     (ISNULL(ii.[user_reads], 0) > 0) 
                       AND (ISNULL(ii.[last_user_read], 0) >= (dateadd(hh, -@LimitedIndexMaxAge, getdate())))) --limit index maintainance to indices unsed within the last "@LimitedIndexMaxAge" hours
                )
            AND ((
                      (ISNULL(LogicalFragmentation, 0.0) >= @LimLogFragmentationReOrg)   -- Only Indices with large logical PAGE FRAGMENTATION, for the Index Defrag is the logical fragmentation important! ==> triggers Index Defrag (with SQL 2000 and SQL 2005)
                   OR (ISNULL(LogicalFragmentation, 0.0) >= @LimLogFragmentationRebuild) -- Only Indices with large logical PAGE FRAGMENTATION, for the Index Defrag is the logical fragmentation important! ==> triggers Index Defrag (with SQL 2000 and SQL 2005)
                 )
                 AND (AllocUnitTypeDesc = N'IN_ROW_DATA' COLLATE Latin1_General_CS_AS)  -- only IN_ROW_DATA means, NO "BLOB Chains" and NO "Column Overflow Chains"... - this is especially for SQL 2005 and later important!
                 AND (    ( ISNULL(is_index_used_by_cdc, 0) = 0) -- check if the index is part of the CDC, if so we can NOT do ANY the Index maintenance (neigther REBUILD not REORGANIZE will work without disabling CDC!!)
                       OR (@CDCProblemExists = 0)             -- OR we have a fixed version, then we can do index maintainance on CDC used indices!
                     ) 
                )
          order by CASE WHEN @PreferUsedIndexMode <> 0 THEN convert(bit, ISNULL(user_reads, 0)) ELSE 0 END DESC,
                   round(LogicalFragmentation / 4.0, 0) DESC,  -- this is the "LogicalFragmentationClass"
                   [data_pages_class] ASC, -- defrag the very big partitions/tables at the end! (Remember that it is possible that the time is to short to run them, so we start with the other indices first, for/in each LogicalFragmentationClass.)
                   ObjectId, IndexId, PartitionNumber ASC -- start with the worst, good in case we need to stop processing due to @MaxWorkTime parameter setting
      FOR UPDATE OF Done, defragmentation_time_minutes, Action, RebuiltOnline, trancount;

    open T2;
    fetch next from T2
      INTO @SchemaName, @TabName, @IndexName, @ScanDensity, @LogicalFragmentation,
           @PartitionID, @MaxPartitionID, @DBId, @AllocUnitTypeDesc,
           @FragmentCount, @FragmentSize, @c_compatibility_level, @IndexID, @has_blob_column, --enhanced for SQL 2005
           @FragmentRatio, @FutureFragmentRatio, @allow_page_locks, @FutureFragmentSize, @Done,
           @is_primary_key_index, @is_index_used_by_cdc, --enhanced for SQL 2008
           @blob_pages, @blob_pages_percent_total_pages_used, @index_pages;
    ---------------------------------------------------------------------------


    ---------------------------------------------------------------------------
    -- lets find out how long we are already doing Index Maintainance
    select @diff_minutes = datediff(mi, @start, getdate());
    
    IF (ISNULL(@diff_minutes, 0) > @MaxWorkTime)
      BEGIN
        select @time_over = 1;
        IF ((@Debug > 2) OR (@Debug < -2))
          print CHAR(13) + CHAR(10) + N'Time over!';              
      END;
    ---------------------------------------------------------------------------


    ---------------------------------------------------------------------------------
    WHILE ((@@fetch_status <> -1) AND (@time_over = 0))
    BEGIN
      IF (@@FETCH_STATUS = 0)
      BEGIN
        select @DoRebuildDueFragmentation = 0;
        -- we seperated this check - so that below large IF-Statement is more readable and the result gets preserved, this will be needed for future enhancements
        IF (    (    (    (ISNULL(@FragmentRatio, 0) > @LimFragmentRatio)            -- (SQL >= 2005) INDEX REBUILD, if we have too many Fragments
                      AND (ISNULL(@FutureFragmentRatio, 0) > @LimFragmentRatio)      -- and if after a ReOrganize we would still have too many Fragments... --however if this value should be NULL, for any reason, then we don't care about it
                      AND (round(ISNULL(@FutureFragmentRatio, 0)/4.0, 0) <> round(ISNULL(@FragmentRatio, 0)/4.0, 0))  -- and if something will change good enougth...
                     ) 
             OR (   (ISNULL(@FragmentSize, @LimFragSize) < @LimFragSize)       -- (SQL >= 2005) ... or too small Fragments (EXTENT FRAGEMENTIERUNG - SQL 2005) ==> triggers Index Rebuild (with SQL 2005)
                     AND (ISNULL(@FutureFragmentSize, @LimFragSize) < @LimFragSize) -- ... and when this is even after a REORGANIZE not good enougth
                    )
                )
           )
          BEGIN  
            select @DoRebuildDueFragmentation = 1;
          END;

        select @sql = N'', @WillDo = N'Nothing',
          @msg = N', Option ('+ convert(nvarchar(13), @ReBuildOption) +
                 CASE WHEN @PreferUsedIndexMode IS NULL THEN N'' ELSE N', ' + CONVERT(nvarchar(13), ISNULL(@PreferUsedIndexMode, 0)) END +
                 CASE WHEN @sql_start_time IS NULL THEN N'' ELSE N', ' + CASE WHEN @sql_start_time >= dateadd(hh, -24, getdate()) THEN N'0' ELSE N'1' END END +
                 N'), [' + db_name(@DBId) + N'].[' + @SchemaName + N'].['+ @TabName + N']' +
                 CASE WHEN ISNULL(@MaxPartitionID, 0) > 1 THEN N' Partition: ' + convert(nvarchar(35), ISNULL(@PartitionID, 1)) + N' (of '+ convert(nvarchar(35), ISNULL(@MaxPartitionID, 1)) + N')' ELSE N'' END +
                 N' Index: [' + @IndexName + N']' +
                 N' - log. Fragmentation (Limit >'+convert(nvarchar(35), 
                                                           CASE WHEN @DoRebuildDueFragmentation = 1
                                                                THEN @LimLogFragmentationRebuild 
                                                                ELSE @LimLogFragmentationReOrg 
                                                           END)+N'): ' + convert(nvarchar(35), @LogicalFragmentation) +
              CASE WHEN @FragmentRatio IS NULL THEN N'' ELSE N' - (FragmentRatio (Limit >'+convert(nvarchar(35), @LimFragmentRatio)+N'): ' + convert(nvarchar(35), ISNULL(@FragmentRatio, 1.0)) + N' ' END +
              CASE WHEN @FutureFragmentRatio IS NULL THEN N'' ELSE N' AND FutureFragmentRatio (Limit >'+convert(nvarchar(35), @LimFragmentRatio)+N'): ' + convert(nvarchar(35), ISNULL(@FutureFragmentRatio, 1.0)) + N')' END +
              CASE WHEN @FragmentSize IS NULL THEN N'' ELSE N' - (AvgFragmentSizeInPages (Limit <'+convert(nvarchar(35), @LimFragSize)+N'): ' + ISNULL(convert(nvarchar(35), @FragmentSize), N'NULL') + N')' END +
              CASE WHEN @FutureFragmentSize IS NULL THEN N'' ELSE N' AND FutureFragmentSize (Limit <'+convert(nvarchar(35), @LimFragSize)+N'): ' + convert(nvarchar(35), ISNULL(@FutureFragmentSize, 1.0)) + N')' END +
              CASE WHEN @blob_pages IS NULL THEN N'' ELSE N' - LOB pages (Limit < '+convert(nvarchar(35), @LimNumBlobPages)+N'): ' + convert(nvarchar(35), @blob_pages) END + N';';
                
        ---------------------------------------------------------------------------------
        -- check if we should build the index OnLine!
        ---------------------------------------------------------------------------------
        IF (    (@OnlinePossible = 1)   -- NON-Enterprise SQL 2005 Editions can not do a OnLine Index ReBuild
            AND (@MaxPartitionID <= 1)  -- partitioned tables can not be ReBuild OnLine
            AND (    (@has_blob_column <> 1) -- can not create Indexes with BLOB columns OnLine fpr 
			      OR ((@SQL_Major_Version  = 11) AND (@SQL_Minor_Version = 0) AND (@SQL_Build_Number >= 1317))  -- this is fixed in SQL 11 CTP 2.5
			      OR ((@SQL_Major_Version  = 11) AND (@SQL_Minor_Version > 0))  -- we simply assume that this is also in all later minor versions fixed!
			      OR (@SQL_Major_Version   > 11)   -- we simply assume that this is also in all later major versions fixed!
                )
            AND (@ReBuildOption >= 0)  -- User decided to do ReBuilds always OFFLINE ( if @ReBuildOption = -1)
           )
            select @DoBuildIndexOnLine = 1;
        ELSE
            select @DoBuildIndexOnLine = 0;
          
        ---------------------------------------------------------------------------------
        -- build the SQL Statement
        ---------------------------------------------------------------------------------
        IF ((   (    ( @DoRebuildDueFragmentation = 1)  -- INDEX REBUILD, if we have too many Fragments
                 AND (@LogicalFragmentation >= @LimLogFragmentationRebuild)
            )
             OR (
                     (ISNULL(@allow_page_locks, 1) = 0)
                 AND (ISNULL(@LogicalFragmentation, 0.0) >= @LimLogFragmentationReOrg)
                )
            )
            -- check the ReBuildOption, we should only do it if we "want to do an Rebuild"
            AND (    (@ReBuildOption <= 0)
                  OR (    (@DoBuildIndexOnLine = 1)
                      AND ((@ReBuildOption < 2) OR (@IndexID <> 1)) -- People might want Clustered Indices to get Reorganzied instead of ReBuild OnLine - background: Even when using WITH (ONLINE=ON), then during the final phase, for clustered indices, a SCH-M Lock is helt for a short periode of time!
                      AND (@ReBuildOption < 3)    -- User decided to do never a Rebuild, always do a ReOrganize if the logical fragmentation is high enougth
                     )
                )
           )
          BEGIN
              select @WillDo = N'ReBuild',
                     @sql = N'ALTER INDEX ['+@IndexName+N'] ON ['+db_name(@DBId)+N'].['+@SchemaName+N'].['+@TabName+N'] REBUILD'+ CASE WHEN @MaxPartitionID > 1
                                                                                                                                       THEN N' PARTITION = '+convert(nvarchar(35), @PartitionID) ELSE N'' END +
                                                                                                                                   N' WITH (MAXDOP = '+CONVERT(nvarchar(35), @MaxDop) +
                                                                                                                                   CASE WHEN @DoBuildIndexOnLine = 1 THEN N', ONLINE = ON' ELSE N'' END + N');';
          END;
        ELSE
          BEGIN
            IF (    (ISNULL(@LogicalFragmentation, 0.0) >= @LimLogFragmentationReOrg)
                AND 
                    (ISNULL(@allow_page_locks, 1) = 1) -- IF this is set to 0 then we CAN NOT REORGANZIE the Index, so the only option we could do is a REBUILD
               )
              select @WillDo = N'ReOrganzize',
                     @sql = N'ALTER INDEX ['+@IndexName+N'] ON ['+db_name(@DBId)+N'].['+@SchemaName+N'].['+@TabName+N'] REORGANIZE'+
                            CASE WHEN @MaxPartitionID > 1 THEN N' PARTITION = '+convert(nvarchar(35), @PartitionID) ELSE N'' END +
                            CASE WHEN @has_blob_column = 1
                                 THEN N' WITH (LOB_COMPACTION = ' +
                                      CASE WHEN @LobCompaction = 0 THEN N'OFF'
                                           WHEN @LobCompaction = 1 THEN N'ON'
                                           ELSE CASE WHEN ISNULL(@blob_pages, 0) < @LimNumBlobPages                   -- don't compact LOBs 1.:    if we have to less pages (if it is to small!)
                                                          OR @blob_pages_percent_total_pages_used >= (@LimPercentBlobPagesUsed / 100.0)  -- 2.: OR if we have not much unused space in the allocated space
                                                     THEN N'OFF'
                                                     ELSE N'ON' END
                                           END + N');'
                                 ELSE N';' END;
          END;  -- end of ELSE
        ---------------------------------------------------------------------------------

        ---------------------------------------------------------------------------------
        --- check if enougth LOG space is availlable
        ---------------------------------------------------------------------------------
        select @sql2 = CASE WHEN @SQL_Major_Version <= 8 THEN N'create table #tran_log_space_usage' ELSE N'declare @tran_log_space_usage TABLE' END + N' (database_name sysname, '+
        -- check for SQL 2012 build 2100 (RTM) - for the SQL 2012 RTM Version, they changed the ResultSet back to what we have in older SQL versions, in older SQL 2012 releases we needed this additional column - so we leave it in!
        CASE WHEN (@SQL_Major_Version = 11 AND @SQL_Minor_Version = 0 AND @SQL_Build_Number < 2099)
		     THEN N'Principal_Filegroup_Name sysname, ' ELSE N'' 
	    END + N'log_size_mb float, log_space_used_percent float,  status int); 
        insert into ' + CASE WHEN @SQL_Major_Version <= 8 THEN N'#tran_log_space_usage' ELSE N'@tran_log_space_usage' END + N' 
            exec(N''DBCC SQLPERF ( LOGSPACE ) WITH NO_INFOMSGS''); 
        select @log_free_pages = convert(bigint, ((log_size_mb * (1 - ISNULL(log_space_used_percent/100, 0)) * 1024) / 8)),
               @log_availlable_pages = convert(bigint, ((log_size_mb * (1 - ISNULL(log_space_used_percent/100, 0)) * 1024) / 8)) + ((sf.max_size - sf.current_size) * sf.is_autogrowth_on)
            from ' + CASE WHEN @SQL_Major_Version <= 8 THEN N'#tran_log_space_usage' ELSE N'@tran_log_space_usage' END + N' as tl
            left outer join
	            (select ' + CASE WHEN @SQL_Major_Version <= 8 
                           THEN convert(nvarchar(35), @DBId) + N' AS database_id'
                           ELSE N'database_id' END +N',
				    SUM(CASE WHEN size < 0 THEN 268435456 ELSE size END) as current_size,
				    SUM(CASE WHEN growth = 0 THEN size ELSE CASE WHEN ' + CASE WHEN @SQL_Major_Version <= 8 THEN N'maxsize' ELSE N'max_size' END + N' < 0 THEN 268435456 ELSE ' + CASE WHEN @SQL_Major_Version <= 8 THEN N'maxsize' ELSE N'max_size' END + N' END END) as max_size,
				    CASE WHEN SUM(CASE WHEN growth <> 0 THEN 1 ELSE 0 END) <> 0 THEN 1 ELSE 0 END as is_autogrowth_on
		            from ' + CASE WHEN @SQL_Major_Version <= 8 
                           THEN N'[' + db_name(@DBId) + N'].dbo.sysfiles WITH (NOLOCK)
                                where groupid = 0
			        group by groupid'
                           ELSE N'sys.master_files WITH (NOLOCK)
			        where type = 1
			            and state = 0
			        group by database_id' END + N'
	            ) as sf
            ON DB_ID(tl.database_name) = sf.database_id
            WHERE DB_ID(tl.database_name) = '+convert(nvarchar(35), @DBId)+N';';
        exec sp_executesql @sql2, N'@log_free_pages bigint OUTPUT, @log_availlable_pages bigint OUTPUT', @log_free_pages = @log_free_pages OUTPUT, @log_availlable_pages = @log_availlable_pages OUTPUT;
        ---------------------------------------------------------------------------------
        --- END OF - check if enougth LOG space is availlable
        ---------------------------------------------------------------------------------

        ---------------------------------------------------------------------------------
        IF ((@Debug > 2) OR (@Debug < -2))
          BEGIN
            select  @WillDo as [Action which will be done], @ReBuildOption AS ReBuildOption, @DoRebuildDueFragmentation AS DoRebuildDueFragmentation,
                    @LogicalFragmentation as LogicalFragmentation,
                    @OnlinePossible AS OnlinePossibleBySqlEdition,
					CASE WHEN @IndexID = 1 THEN 1 ELSE 0 END as IsClusteredIndex,
                    @is_primary_key_index as [is_primary_key_index], 
					CASE WHEN @MaxPartitionID > 1 THEN 1 else 0 END as IsIndexPartitioned,
					@is_index_used_by_cdc as [is_index_used_by_cdc], 
					ISNULL(@allow_page_locks, 1) as AllowPageLocks,
					@has_blob_column AS IndexHasBlobColumn, 
					@blob_pages AS [Blob Pages],
                    @DoBuildIndexOnLine AS DoBuildIndexOnLine,
                    @MaxDop as [MAXDOP for Rebuild],
                    @AllowLogGrowth AS AllowLogGrowth, @index_pages AS IndexPages, CASE WHEN @AllowLogGrowth <> 0 THEN @log_availlable_pages ELSE @log_free_pages END as AvaillableLogPages,
                    @PreferUsedIndexMode as PreferUsedIndexMode, @PreferInnerIndexMode as PreferInnerIndexMode;
          END;
        ---------------------------------------------------------------------------------

        ---------------------------------------------------------------------------------
        --- IF NOT enougth LOG space is availlable THEN do nothing
        IF (@index_pages * 2) <= CASE WHEN @AllowLogGrowth <> 0 THEN @log_availlable_pages ELSE @log_free_pages END
        BEGIN
        ---------------------------------------------------------------------------------
          IF (len(@sql) > 0)
            BEGIN
              -- remember build start time
              select @Tlast = getdate();

              --some debug output needs to be created
              IF (@Debug <> 0)
                BEGIN
                  select @sql AS [Index Maintainance SQL Statement];
                END;
                
              -- make sure the looping algorithm works, even if we do not execute anything                  
              IF (@Debug > 0)
                BEGIN
                  UPDATE #IndexInfo set Done = 1, defragmentation_time_minutes = ((1.0 * datediff(s, @Tlast, getdate())) / 60.0),
                                        Action = @WillDo, RebuiltOnline = CASE WHEN @WillDo = N'ReBuild' COLLATE Latin1_General_CS_AS AND @DoBuildIndexOnLine = 1 THEN 1 ELSE 0 END,
										trancount = @@TRANCOUNT
                    WHERE CURRENT of T2;
                END;

               -- NOW, we need to execute the sql statements! Here begins the real work...
              IF (@Debug <= 0)
                BEGIN
                  BEGIN TRY
                  BEGIN TRAN
                    -- Just execute the sql statement!
                    EXEC (@sql);
                    
                    -- Message into the SQL Server Errorlog
                    -- Success message into the SQL Server Errorlog
                    UPDATE #IndexInfo set Done = 1, defragmentation_time_minutes = ((1.0 * datediff(s, @Tlast, getdate())) / 60.0),
                                          Action = @WillDo, RebuiltOnline = CASE WHEN @WillDo = N'ReBuild' COLLATE Latin1_General_CS_AS AND @DoBuildIndexOnLine = 1 THEN 1 ELSE 0 END,
										  trancount = @@TRANCOUNT
                      WHERE CURRENT of T2;
                    SELECT @WillDo = CONVERT(nvarchar(35), convert(decimal(18,2), (1.0 * datediff(s, @Tlast, getdate())) / 60.0)) + N' min. with '''+@WillDo;
                    RAISERROR (N'sp_IndexDefrag: %s''%s', 0, 1, @WillDo, @msg) WITH LOG;
                  COMMIT TRAN
                  END TRY
                  BEGIN CATCH
                    -- Error message into the SQL Server Errorlog
                    IF (XACT_STATE() = -1)
                        ROLLBACK TRAN;
                    ELSE IF (XACT_STATE() = 1)
                        COMMIT TRAN;
                    select @severity = Error_Severity(), @state = Error_State(), @err_num = Error_Number();
                    UPDATE #IndexInfo set Done = -@err_num, Action = @WillDo, RebuiltOnline = CASE WHEN @WillDo = N'ReBuild' COLLATE Latin1_General_CS_AS AND @DoBuildIndexOnLine = 1 THEN 1 ELSE 0 END
                      WHERE CURRENT of T2;
                    RAISERROR (N'org. ERROR: %i raised in sp_IndexDefrag Statement: ''%s''',
                                 0,1,
                                 @err_num, 
                                 @sql) WITH LOG;
                  END CATCH

                  ---------------------------------------------------------------------------
				  IF (@@TRANCOUNT > 0)
					BEGIN
					  COMMIT TRAN;
					END;
                  ---------------------------------------------------------------------------

                  ---------------------------------------------------------------------------
                  -- lets find out how long we are already doing Index Maintainance
                  select @diff_minutes = datediff(mi, @start, getdate());
    
                  IF (ISNULL(@diff_minutes, 0) > @MaxWorkTime)
                    BEGIN
                      select @time_over = 1;
                      IF ((@Debug > 2) OR (@Debug < -2))
                        print CHAR(13) + CHAR(10) + N'Time over!';              
                    END;
                  ---------------------------------------------------------------------------

                END; -- end of - IF (@DEBUG <= 0)
            END -- end of - IF LEN(@SQL) > 0
            ELSE
              BEGIN
                -- Nothing was done, we mark the record properly (NULL means it was not considerd, 0 means it was considered but not processed and 1 means it was processed
                UPDATE #IndexInfo set Done = 0, Action = @WillDo, RebuiltOnline = CASE WHEN @WillDo = N'ReBuild' COLLATE Latin1_General_CS_AS AND @DoBuildIndexOnLine = 1 THEN 1 ELSE 0 END
                  WHERE CURRENT of T2;
              END; -- end of ELSE branch of - IF LEN(@SQL) > 0
        ---------------------------------------------------------------------------------
        END /* END OF - IF (@index_pages * 2) <= CASE WHEN @AllowLogGrowth <> 0 THEN @log_free_pages ELSE @log_availlable_pages END */
        ELSE
          BEGIN
            -- Not enougth LogSpace availlable, we mark the record properly (NULL means it was not considerd, 0 means it was considered but not processed and 1 means it was processed
            UPDATE #IndexInfo set Done = -53001,  -- ERROR not enougth LOG Space availlable
                                  defragmentation_time_minutes = (1.0 * datediff(s, @Tlast, getdate())) / 60.0,
                                  Action = @WillDo, RebuiltOnline = CASE WHEN @WillDo = N'ReBuild' COLLATE Latin1_General_CS_AS AND @DoBuildIndexOnLine = 1 THEN 1 ELSE 0 END
              WHERE CURRENT of T2;

            IF (@Debug <= 0)
              BEGIN
                --  JUST LOG IT so that people will know, in case we did really execute the commands
                RAISERROR (N'ERROR: 53001 (NOT enougth LOG space availlable) to run sp_IndexDefrag Statement: ''%s''',
                           16,1,--@severity, @state,
                           @sql) WITH LOG;
              END;
          END; -- end of ELSE branch of - IF (@index_pages * 2) <= CASE WHEN @AllowLogGrowth <> 0 THEN @log_free_pages ELSE @log_availlable_pages END
        ---------------------------------------------------------------------------------
      END;

      fetch next from T2
        INTO @SchemaName, @TabName, @IndexName, @ScanDensity, @LogicalFragmentation,
             @PartitionID, @MaxPartitionID, @DBId, @AllocUnitTypeDesc,
             @FragmentCount, @FragmentSize, @c_compatibility_level, @IndexID, @has_blob_column,
             @FragmentRatio, @FutureFragmentRatio, @allow_page_locks, @FutureFragmentSize, @Done,
             @is_primary_key_index, @is_index_used_by_cdc,
             @blob_pages, @blob_pages_percent_total_pages_used, @index_pages;
             
    END;  -- END of WHILE Loop
  
    close T2;
    deallocate T2;
    --------------------------------------------------------------------------------------------------------
  END;  -- END of Research Loop - WHILE Loop
---------------------------------------------------------------------------------
--------- END OF RESEARCH MORE
---------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------
IF ((@Debug > 2) OR (@Debug < -2))
  select * from #ToDbList order by ord;  
--------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------
IF ((@Debug > 1) OR (@Debug < -1))
  BEGIN
    select *
           , CASE WHEN @PreferUsedIndexMode <> 0 THEN convert(bit, ISNULL(user_reads, 0)) ELSE 0 END as IsIndexUsed
           , round(LogicalFragmentation / 4.0, 0) AS LogicalFragmentationClass
        from #IndexInfo
      where AllocUnitTypeDesc = N'IN_ROW_DATA' COLLATE Latin1_General_CS_AS
        and ISNULL(Pages, 0) >= @LimNumPages
        and
          (   (FutureFragmentCount IS NOT NULL)
             OR ((@SQL_Major_Version <= 8) AND (IndexId <> 0))  -- do not filter if we have SQL 2000, then "FutureFragmentCount" will be NULL per design
             OR ((@SQL_Major_Version >  8) AND (@PreferUsedIndexMode <> 2)) --do not filter if @PreferUsedIndexMode was set to 2, then we might not have the fragmentation evaluated and "FutureFragmentCount" will be NULL per design
          )
        order by CASE WHEN @PreferUsedIndexMode <> 0 THEN convert(bit, ISNULL(user_reads, 0)) ELSE 0 END DESC,
                 round(LogicalFragmentation / 4.0, 0) DESC,
                 [data_pages_class] ASC, -- defrag the very big partitions/tables at the end! (Remember that it is possible that the time is to short to run them, so we start with the other indices first, for/in each LogicalFragmentationClass.)
                 ObjectId, IndexId, PartitionNumber ASC -- start with the worst, good in case we need to stop processing due to @MaxWorkTime parameter setting
  END;
--------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------
--restore the old NOCOUNT Status
if @oldStatus = 0
  set nocount off;
--------------------------------------------------------------------------------------------------------

return 0;
GO

GRANT EXECUTE ON [dbo].[sp_DefragIndexes] TO [public]
GO
