SELECT database_name, backup_size, backup_finish_date 
INTO #test1 FROM msdb..backupset
WHERE backup_finish_date >= '2011-03-12'

select SUM(backup_size)/1024/1024/1024 as test from #test1


drop table #test1