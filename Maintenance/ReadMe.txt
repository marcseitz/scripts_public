

This is a "Tool" to analyse Index-Fragmentation and processes the defragmentation or rebuild, depending on the gathered 
fragmentation Details, eigther a Index Defrag (ReOrganize) or a Index ReBuild will be triggered. The way a ReBuild will be done
is controllable over the setting of the @ReBuildOption calling parameter. By default (value 2) it will be done in a way where 
cuncurrency is more importand than speed of the defrag/rebuild command. 
That means it is more easily useable in a 7*24 hour availlable system.

This script creates a Stored Procedure with name "sp_DefragIndexes" in the Master-DB which can be used
  in any User Database context, to let it run against it, or against any other Database or against ALL Databases.

ATTENTION, compared to the older version, I have changed the name of the SP as well as some parameternames and
the order of the parameters to make it more compliant with all of my maintainance Scripts.


-- ------------------------------------------------------------------------------------------------------------------
-- 
-- Sample Stored Procedure which runs under SQL Server 2005 and later (including SQL Server 2012).
-- 
-- I try to make this Stored Procedure availlable for all customers. If you find a Bug, or if you want to have
--   additional functionality or if you experience the need for different default settings, then pls. give Feedback.
--   If you are completly satisfied with this stored procedure, then Feedback is welcome, too.
-- 
-- 
-- ===> Feedback to EMail: franzro@microsoft.com
-- 
-- ------------------------------------------------------------------------------------------------------------------




DESCRIPTION OF THE PARAMETERS:
-- ------------------------------------------------------------------------------------------------------------------

 Parameter  @MaxWorkTime:
                  <value>  - any value >15 means: we don't Defrag or Rebuild indices longer that this value in minutes!
                             However already started index Defrags or Rebuilds runs will not be stopped!

 Parameter  @ToDoDatabaseList:
                    NULL   - (default) ignore this parameter
                  <value>  - run it for the Database IDs in this comma seperated list of database IDs!
                             (The processing of the Databases will be in the order of the database IDs
                              defined in this paramter, however the database defined over parameter @ToDoDatabaseId
                              will always be processed first. System databases will only be processed if explicitly
                              requested, not implicitly over wild cards.)

 Parameter  @ToDoDatabaseId:
                    NULL   - (default) run it for all User Databases
                     0     - run it for the current Database context only
                    >0     - run it for the Database with the DB_ID() equal the Value of this Parameter

 Parameter  @ToDoObjectId:
                    NULL   - run it for all User Databases Objects (eigther Tables or Indexed Views)
                     0     - (default) run it for all User Databases Objects (same as NULL)
                    >0     - run it for the User Databases Object with the OBJECT_ID() equal the Value of this Parameter

 Parameter  @ToDoIndexId:
                    NULL   - (default) run it for all Indices
                    >=0    - run it for the index_id equal the Value of this Parameter

 Parameter  @ReBuildOption:
                    -1     - ReBuild runs always OFFLINE
                     0     - ReBuild runs ONLINE if possible, otherwise the ReBuild will run OFFLINE
                     1     - ReBuild runs ONLY ONLINE if possible, otherwise a REORGANZIZE will be
                             done if the Logical Fragmentation is high enougth!
                     2     - (default) A ReBuild of CLUSTERED Indices will NEVER be done,
                             a ReBuild of NON-CLUSTERED Indices will be done ONLY if it is possible to do it ONLINE,
                             otherwise a REORGANZIZE will be done if the Logical Fragmentation is high enougth!
                     3     - A ReBuild will NEVER be done! Under no circumstances, always a REORGANZIZE
                             will be done if the Logical Fragmentation is high enougth!

 Parameter  @MaxDop  = xxx - This does set the used MAXDOP value for a index REBUILD command,
                             the accepted limits of this values depend on the setting of the parameter @ReBuildOption
                             and how many CPUs are used by SQL Server

 Parameter  @LobCompaction - desides how the REORGANIZE Parameter 'LOB_COMPACTION' will be set (ONLY for SQL 2005 or later)
                    NULL   - (default) means AUTO, let's the SP deside what to do, small BLOBs will 
                             have LOB_COMPACTION = OFF, larger BLOBs will have LOB_COMPACTION = ON
                     0     - if an index had a BLOB field, always use LOB_COMPACTION = OFF
                     1     - if an index had a BLOB field, always use LOB_COMPACTION = ON

 Parameter  @PreferUsedIndexMode - desides how used indices are prefered (ONLY for SQL 2005 and later and ONLY if SQL Server did run at least for 24 hours)
                     0     - don't care if indices are used or not
                     1     - prefer used indices, but if it is still time, maintain the other indices also
                     2     - (default) maintain used indices only 

 Parameter  @AllowLogGrowth:
                     0     - do NOT grow the Transaction LOG files to run index maintainance commands 
                             ==> In case the availlable space is not large enougth then do not run the command!
                     1     - (default) consider to grow the Transaction LOG files to run index maintainance commands
                             Worst case, the T-LOG files could grow to the upper limit configured in the T-LOG file settings!

 Parameter  @Debug:
                    <= 0   - Means in general to DO the Index Maintainance work - otherwise same meaning as positive values
                    > 0    - Means in general NOT to DO the Index Maintainance job execution,
                             helpful to get information about what WOULD be done!
                    NULL   - DO the Index Maintainance - but no DebugInfo (identical to 0)
                     0     - (default) DO THE INDEX MAINTAINANCE - but no additional information will be provided
                     1     - additional DebugInfo! (returns also the SQL Statements)
                     2     - additional DebugInfo! (returns also the helping temp. table and MASTER DB compat Level)
                     3     - additional DebugInfo! (returns also the desition information for Rebuild Option)

-- ------------------------------------------------------------------------------------------------------------------



Samples for the possible T-SQL command lines:
=============================================



exec sp_DefragIndexes    -- This will start the index defragmentation for all USER databases! This should be the prefered option!



exec sp_DefragIndexes @ToDoDatabaseId = 5             -- this will start the Index Maintainance for the Database with the ID of 5.



exec sp_DefragIndexes @ToDoDatabaseList = N'5, 6, 9'  -- this will start the Index Maintainance for the Database with the IDs of 5, 6 and 9.



exec sp_DefragIndexes @ToDoDatabaseId = 5, @Debug = 2 -- this will start the Index Maintainance Analysis for the Database with the ID of 5,
                                                      -- but will ONLY do the ANALYSIS returning the T-SQL commands an the fragmentation status table
