USE [GENERAL]
 GO

SET ANSI_NULLS ON
 GO

SET QUOTED_IDENTIFIER ON
 GO

-- this procedure uses an update table, must be named in Cursor declaration
-- The update table needs to have a src_table, a dest_table and an area.
-- The area is used for filtering the different tables

CREATE PROCEDURE [dbo].[usp_DWH_TRANSFER]
    @area_select varchar(50)
AS

declare @sql                    varchar(1000)
declare @src_table              varchar(255)
declare @dest_table             varchar(255)
declare @object_id              int;


-- Cursor declaration (müssen an akutelle DB/Table angepasst werden)
declare cur_area cursor for
 select srctable_name, desttable_name
from general.dwh.dwh_transfer_conf
where dept_area_name = @area_select
open cur_area

fetch next from cur_area into @src_table,@dest_table
while @@FETCH_STATUS = 0
 begin
    set @object_id = OBJECT_ID(@dest_table);
    --Source = Target
    If @dest_table != @src_table
         begin
        --table exists -> drop table
        IF @object_id IS NOT NULL
                 begin
            set @sql = 'drop table '+@dest_table
            exec (@sql)
        end

        --copy data from original table to General
        set @sql = 'select *, getdate() as dwh_tansfer_creation_date into '+@dest_table+' from '+@src_table
        exec (@sql)

    --send mail on error
    /*if @@ERROR > 0        
                 EXEC msdb.dbo.sp_send_dbmail
                         @profile_name = 'cgate mail',
                         @recipients = 'me@you.de',
                         @body = '',
                         @subject = 'Fehler'
                 */
    end
         
         ELSE
         begin
        print 'Quelle = Ziel'
    /*      EXEC msdb.dbo.sp_send_dbmail
                         @profile_name = 'cgate mail',
                         @recipients = 'me@you.de',
                         @body = 'Quelle gleich Ziel',
                         @subject = 'Fehler'
                 */
    end

    fetch next from cur_area into @src_table,@dest_table
end

-- Close & Deallocate Cursor
close cur_area
deallocate cur_area
 

GO
