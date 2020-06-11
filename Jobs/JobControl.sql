CREATE PROCEDURE [dbo].[PROC_SQLJOBS_ENABLE_DISABLE]
    (@enableFlag int)
AS
/** ***** Version *****
* $Revision:$
* $Date: $ 
* $Author $
* $Archive:$
*
* Sample use: exec PROC_SQLJOBS_ENABLE_DISABLE 0
* Comments : This stored procedure disables or enables all the listed jobs in the sp at once
* @enableFlag = 0 Disable jobs
* @enableFlag = 1 Enable jobs
*/


If @enableFlag = 0 --disable jobs
BEGIN
    exec msdb..sp_update_job @job_name = 'Update_job1, @enabled = 0
exec msdb..sp_update_job @job_name = 'Update_job2
    ', @enabled = 0
END 


If @enableFlag = 1 --enable jobs
BEGIN
exec msdb..sp_update_job @job_name = 'Update_job1, @enabled = 1
    exec msdb..sp_update_job @job_name = 'Update_job2', @enabled = 1
END


GO