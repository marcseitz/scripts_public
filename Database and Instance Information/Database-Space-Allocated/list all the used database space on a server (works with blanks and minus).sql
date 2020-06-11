/*
http://www.sqlservercentral.com/Forums/Topic219378-5-1.aspx
list all the used database space on a server
*/

DECLARE @TempFiles TABLE (
[Name] [nvarchar](128) NULL,
[DatabaseID] [int] NULL,
[Type] [nvarchar](60) NULL,
[State] [nvarchar](60) NULL,
[SizeMB] [float] NULL,
[SizeUsedMB] [float] NULL,
[MaxSizeMB] [float] NULL,
[AutoGrowSize] [float] NULL,
[PercentGrowth] [bit] NULL,
[ReadOnly] [bit] NULL,
[FilesystemPath] [nvarchar](260) NULL)

INSERT INTO @TempFiles (
[Name],[DatabaseID],[Type],[State],[SizeMB],[SizeUsedMB]
,[MaxSizeMB],[AutoGrowSize],[PercentGrowth],[ReadOnly],[FilesystemPath])
EXEC sp_msforeachdb 'USE [?]; SELECT [name],
DB_ID() as [DatabaseID],
[type_desc] as [Type],
[state_desc] as [State],
[size]/128.00 as [SizeMB],
fileproperty([name],''SpaceUsed'')/128.00 as [SizeUsedMB],
CASE WHEN [max_size] = -1 then [max_size] ELSE [max_size]/128.00 END as [MaxSizeMB],
CASE WHEN [is_percent_growth] = 1 THEN [growth] ELSE [growth]/128.00 END as [AutoGrowSize],
[is_percent_growth] as [PercentGrowth],
CASE WHEN [is_media_read_only] = 1 OR [is_read_only] = 1 THEN 1 ELSE 0 END as [ReadOnly],
[physical_name] as [FilesystemPath]
FROM sys.database_files'

SELECT * FROM @TempFiles 