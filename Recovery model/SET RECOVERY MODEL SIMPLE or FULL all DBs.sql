--http://neilblackburn.blogspot.com/2010/08/set-all-databases-to-simple-recovery.html

--ALTER DATABASE [DatabaseName] SET RECOVERY SIMPLE WITH NO_WAIT

USE master
-- Get all non-system databases that do not have simple recovery mode
DECLARE @databaseName NVARCHAR(128)
DECLARE userDatabases CURSOR
FOR
SELECT name FROM dbo.sysdatabases
WHERE dbid > 4 AND DATABASEPROPERTYEX([name], 'Recovery') <> 'SIMPLE';

OPEN userDatabases
-- Update databases to simple recovery mode
FETCH NEXT FROM userDatabases INTO @databaseName
WHILE (@@FETCH_STATUS = 0)
BEGIN
PRINT 'Updating database ' + @databaseName + ' to simple recovery mode.' 
EXEC('ALTER DATABASE [' + @databaseName + '] SET RECOVERY SIMPLE;')     
FETCH NEXT FROM userDatabases INTO @databaseName
END
CLOSE userDatabases
DEALLOCATE userDatabases 

------------------------------------------------------------------------

--ALTER DATABASE [DatabaseName] SET RECOVERY FULL WITH NO_WAIT

USE master
-- Get all non-system databases that do not have full recovery mode
DECLARE @databaseName NVARCHAR(128)
DECLARE userDatabases CURSOR
FOR
SELECT name FROM dbo.sysdatabases
WHERE dbid > 4;

OPEN userDatabases
-- Update databases to full recovery mode
FETCH NEXT FROM userDatabases INTO @databaseName
WHILE (@@FETCH_STATUS = 0)
BEGIN
PRINT 'Updating database ' + @databaseName + ' to full recovery mode.' 
EXEC('ALTER DATABASE [' + @databaseName + '] SET RECOVERY FULL;')     
FETCH NEXT FROM userDatabases INTO @databaseName
END
CLOSE userDatabases
DEALLOCATE userDatabases