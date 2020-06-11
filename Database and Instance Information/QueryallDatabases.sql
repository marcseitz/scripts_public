-- Beispiel Abfrage auf alle Datenbanken in einer Instanz. Query wird auf die master Datenbank ausgeführt. In dieser Query
-- werden die Systemdatenbanken (not in master, msdb...) nicht abgefragt. Die Query gibt den Namen der jeweiligen Datenbank aus und 
-- fragt eine Spalte in einer bestimmten Tabelle ab


declare @cmd1 varchar(500)
declare @cmd2 varchar(500)

SET @cmd1 = 'USE ? IF DB_NAME() NOT IN(''master'',''msdb'',''tempdb'',''model'') PRINT DB_NAME()'
SET @cmd2 = 'USE ? IF DB_NAME() NOT IN(''master'',''msdb'',''tempdb'',''model'') select description from Printer'
EXEC Sp_msforeachdb @command1=@cmd1, @command2=@cmd2
