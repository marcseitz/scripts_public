BEGIN TRANSACTION
DECLARE @JobID BINARY(16)
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF (SELECT COUNT(*)
FROM msdb.dbo.syscategories
WHERE name = N'[Uncategorized (Local)]') < 1
   EXECUTE msdb.dbo.sp_add_category @name = N'[Uncategorized (Local)]'

-- Delete the job with the same name (if it exists)
SELECT @JobID = job_id
FROM msdb.dbo.sysjobs
WHERE (name = N'Process')
IF (@JobID IS NOT NULL)    
   BEGIN
    -- Check if the job is a multi-server job  
    IF (EXISTS (SELECT *
    FROM msdb.dbo.sysjobservers
    WHERE   (job_id = @JobID) AND (server_id <> 0)))
   BEGIN
        -- There is, so abort the script
        RAISERROR (N'Unable to import job ''Process'' since there is already a multi-server job with this name.', 16, 1)
        GOTO QuitWithRollback
    END
   ELSE
     -- Delete the [local] job
     EXECUTE msdb.dbo.sp_delete_job @job_name = N'Process'
    SELECT @JobID = NULL
END

BEGIN

    -- Add the job
    EXECUTE @ReturnCode = msdb.dbo.sp_add_job @job_id = @JobID OUTPUT , @job_name = N'Process', @owner_login_name = N'owner', @description = N'Keine Beschreibung verfügbar.', @category_name = N'[Uncategorized (Local)]', @enabled = 1, @notify_level_email = 0, @notify_level_page = 0, @notify_level_netsend = 0, @notify_level_eventlog = 2, @delete_level= 0
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

    -- Add the job steps
    EXECUTE @ReturnCode = msdb.dbo.sp_add_jobstep @job_id = @JobID, @step_id = 1, @step_name = N'sp_job_monitor_job_start', @command = N'EXEC dbo.sp_job_monitor_job_start [JOBID]', @database_name = N'msdb', @server = N'', @database_user_name = N'', @subsystem = N'TSQL', @cmdexec_success_code = 0, @flags = 0, @retry_attempts = 0, @retry_interval = 0, @output_file_name = N'', @on_success_step_id = 0, @on_success_action = 3, @on_fail_step_id = 0, @on_fail_action = 3
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXECUTE @ReturnCode = msdb.dbo.sp_add_jobstep @job_id = @JobID, @step_id = 2, @step_name = N'Step2', @command = N'dtsrun /E /s server /n Step2', @database_name = N'', @server = N'', @database_user_name = N'', @subsystem = N'CmdExec', @cmdexec_success_code = 0, @flags = 0, @retry_attempts = 0, @retry_interval = 1, @output_file_name = N'', @on_success_step_id = 0, @on_success_action = 3, @on_fail_step_id = 11, @on_fail_action = 4
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXECUTE @ReturnCode = msdb.dbo.sp_add_jobstep @job_id = @JobID, @step_id = 3, @step_name = N'Step3', @command = N'dtsrun /E /s server /n Step3', @database_name = N'', @server = N'', @database_user_name = N'', @subsystem = N'CmdExec', @cmdexec_success_code = 0, @flags = 0, @retry_attempts = 0, @retry_interval = 1, @output_file_name = N'', @on_success_step_id = 0, @on_success_action = 3, @on_fail_step_id = 11, @on_fail_action = 4
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXECUTE @ReturnCode = msdb.dbo.sp_add_jobstep @job_id = @JobID, @step_id = 4, @step_name = N'Step4', @command = N'dtsrun /E /s server /n Step4', @database_name = N'', @server = N'', @database_user_name = N'', @subsystem = N'CmdExec', @cmdexec_success_code = 0, @flags = 0, @retry_attempts = 0, @retry_interval = 1, @output_file_name = N'', @on_success_step_id = 0, @on_success_action = 3, @on_fail_step_id = 11, @on_fail_action = 4
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXECUTE @ReturnCode = msdb.dbo.sp_add_jobstep @job_id = @JobID, @step_id = 5, @step_name = N'Step5', @command = N'dtsrun /E /s server /n Step5', @database_name = N'', @server = N'', @database_user_name = N'', @subsystem = N'CmdExec', @cmdexec_success_code = 0, @flags = 0, @retry_attempts = 0, @retry_interval = 1, @output_file_name = N'', @on_success_step_id = 0, @on_success_action = 3, @on_fail_step_id = 11, @on_fail_action = 4
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXECUTE @ReturnCode = msdb.dbo.sp_add_jobstep @job_id = @JobID, @step_id = 6, @step_name = N'Step6', @command = N'dtsrun /E /s server /n Step6', @database_name = N'', @server = N'', @database_user_name = N'', @subsystem = N'CmdExec', @cmdexec_success_code = 0, @flags = 0, @retry_attempts = 0, @retry_interval = 1, @output_file_name = N'', @on_success_step_id = 0, @on_success_action = 3, @on_fail_step_id = 11, @on_fail_action = 4
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXECUTE @ReturnCode = msdb.dbo.sp_add_jobstep @job_id = @JobID, @step_id = 7, @step_name = N'Step7', @command = N'dtsrun /E /s server /n Step7', @database_name = N'', @server = N'', @database_user_name = N'', @subsystem = N'CmdExec', @cmdexec_success_code = 0, @flags = 0, @retry_attempts = 0, @retry_interval = 1, @output_file_name = N'', @on_success_step_id = 0, @on_success_action = 3, @on_fail_step_id = 11, @on_fail_action = 4
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXECUTE @ReturnCode = msdb.dbo.sp_add_jobstep @job_id = @JobID, @step_id = 8, @step_name = N'Step8', @command = N'dtsrun /E /s server /n Step8', @database_name = N'', @server = N'', @database_user_name = N'', @subsystem = N'CmdExec', @cmdexec_success_code = 0, @flags = 0, @retry_attempts = 0, @retry_interval = 1, @output_file_name = N'', @on_success_step_id = 0, @on_success_action = 3, @on_fail_step_id = 11, @on_fail_action = 4
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXECUTE @ReturnCode = msdb.dbo.sp_add_jobstep @job_id = @JobID, @step_id = 9, @step_name = N'Step9', @command = N'dtsrun /E /s server /n Step9', @database_name = N'', @server = N'', @database_user_name = N'', @subsystem = N'CmdExec', @cmdexec_success_code = 0, @flags = 0, @retry_attempts = 0, @retry_interval = 1, @output_file_name = N'', @on_success_step_id = 0, @on_success_action = 3, @on_fail_step_id = 11, @on_fail_action = 4
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXECUTE @ReturnCode = msdb.dbo.sp_add_jobstep @job_id = @JobID, @step_id = 10, @step_name = N'SUCCESS Mail', @command = N'EXEC sp_SYS_EMAIL_VERSAND
 @from           = ''me@you.de'',
 @from_name      = ''SQL Server'',
 @replyto        = ''me@you.de'',
 @to             = ''you@me.de'',
 @subject        = ''SUCCESS: Process - succeeded'',
 @message        = '''',
 @server         = ''server''
 ', @database_name = N'server', @server = N'', @database_user_name = N'', @subsystem = N'TSQL', @cmdexec_success_code = 0, @flags = 0, @retry_attempts = 0, @retry_interval = 1, @output_file_name = N'', @on_success_step_id = 0, @on_success_action = 1, @on_fail_step_id = 0, @on_fail_action = 2
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXECUTE @ReturnCode = msdb.dbo.sp_add_jobstep @job_id = @JobID, @step_id = 11, @step_name = N'ERROR Mail', @command = N'EXEC sp_SYS_EMAIL_VERSAND
 @from           = ''me@you.de'',
 @from_name      = ''SQL Server'',
 @replyto        = ''me@you.de'',
 @to             = ''you@me.de'',
 @subject        = ''ERROR: Process - failed'',
 @message        = '''',
 @server         = ''server''
 ', @database_name = N'server', @server = N'', @database_user_name = N'', @subsystem = N'TSQL', @cmdexec_success_code = 0, @flags = 0, @retry_attempts = 0, @retry_interval = 1, @output_file_name = N'', @on_success_step_id = 0, @on_success_action = 2, @on_fail_step_id = 0, @on_fail_action = 2
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXECUTE @ReturnCode = msdb.dbo.sp_update_job @job_id = @JobID, @start_step_id = 1

    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

    -- Add the Target Servers
    EXECUTE @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @JobID, @server_name = N'(local)'
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END
COMMIT TRANSACTION
GOTO   EndSave
QuitWithRollback:
IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
