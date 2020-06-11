
SELECT database_name, backup_size, compressed_backup_size, backup_finish_date 
INTO #test FROM msdb..backupset
WHERE backup_finish_date >= '2011-03-08'

select SUM(compressed_backup_size)/1024/1024/1024 as CompressedBackupSize from #test

drop table #test