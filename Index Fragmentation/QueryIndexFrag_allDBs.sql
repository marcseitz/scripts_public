-- Be careful - this could be a LONG Query! 

declare @cmd1 varchar(max)
SET @cmd1 = 'USE ? IF DB_NAME() NOT IN(''master'',''msdb'',''tempdb'',''model'') SELECT d.name as DatabaseName, OBJECT_NAME(i.OBJECT_ID) AS TableName,i.name AS IndexName,indexstats.avg_fragmentation_in_percent FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, ''DETAILED'') indexstats INNER JOIN sys.indexes i ON i.OBJECT_ID = indexstats.OBJECT_ID INNER JOIN sys.databases d ON d.database_id = indexstats.database_id AND i.index_id = indexstats.index_id ORDER BY avg_fragmentation_in_percent'
EXEC Sp_msforeachdb @command1=@cmd1