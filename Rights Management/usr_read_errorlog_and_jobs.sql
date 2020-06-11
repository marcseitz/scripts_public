USE master
GO
GRANT  EXECUTE  ON [dbo].[xp_readerrorlog] TO [useraccount]
GO

USE msdb
GO
GRANT  EXECUTE  ON [dbo].[sp_add_job] TO [useraccount]
go
GRANT  EXECUTE  ON [dbo].[sp_add_jobschedule] TO [useraccount]
go
GRANT  EXECUTE  ON [dbo].[sp_add_jobserver] TO [useraccount]
go
GRANT  EXECUTE  ON [dbo].[sp_add_jobstep] TO [useraccount]
go
GRANT  EXECUTE  ON [dbo].[sp_addtask] TO [useraccount]
go
GRANT  EXECUTE  ON [dbo].[sp_delete_job] TO [useraccount]
go
GRANT  EXECUTE  ON [dbo].[sp_delete_jobschedule] TO [useraccount]
go
GRANT  EXECUTE  ON [dbo].[sp_delete_jobserver] TO [useraccount]
go
GRANT  EXECUTE  ON [dbo].[sp_delete_jobstep] TO [useraccount]
go
GRANT  EXECUTE  ON [dbo].[sp_droptask] TO [useraccount]
go
GRANT  EXECUTE  ON [dbo].[sp_post_msx_operation] TO [useraccount]
go
GRANT  EXECUTE  ON [dbo].[sp_purgehistory] TO [useraccount]
go
GRANT  EXECUTE  ON [dbo].[sp_reassigntask] TO [useraccount]
go
GRANT  EXECUTE  ON [dbo].[sp_start_job] TO [useraccount]
go
GRANT  EXECUTE  ON [dbo].[sp_stop_job] TO [useraccount]
go
GRANT  EXECUTE  ON [dbo].[sp_update_job] TO [useraccount]
go
GRANT  EXECUTE  ON [dbo].[sp_update_jobschedule] TO [useraccount]
go
GRANT  EXECUTE  ON [dbo].[sp_update_jobstep] TO [useraccount]
go
GRANT  EXECUTE  ON [dbo].[sp_updatetask] TO [useraccount]
go

