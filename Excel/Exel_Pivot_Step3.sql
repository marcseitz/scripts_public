
USE [test]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE OR ALTER PROCEDURE [dbo].[usp_create_pivot_table]
AS

Begin Transaction

declare @columns int
declare @counter int
declare @createtable varchar(500)
declare @altertable varchar (500)
declare @column_sql varchar(500)
declare @project varchar(200)
declare @year_name varchar (10)
declare @month_name varchar (10)
declare @field varchar(200)
declare @value varchar(200)
declare @sql varchar(500)
declare @item_id int
declare @update varchar (1500)
declare @user varchar(50)

-- dropping old Pivot-Table
drop table test.dbo.testtable_pivot

-- creating new Pivot-Table, getting Row-Values from Item-Table
SET @counter = 1
SELECT @columns = COUNT(*)
FROM test.dbo.testtable_item

SET @createtable = 'CREATE TABLE test.dbo.testtable_pivot ([SID] [int] IDENTITY(1,1) NOT NULL, [User] [varchar](50) NULL, [Project] [varchar] (50) NOT NULL,  [Year_Name] [varchar] (50) NOT NULL, [Month_Name] [varchar](50) NOT NULL)'
set @altertable = 'ALTER TABLE test.dbo.testtable_pivot ADD ['

exec (@createtable)

while @counter <= @columns 
Begin
    set @column_sql = (select Field
    from test.dbo.testtable_item
    where Item_id=@counter*100)
    set @sql = @altertable + @column_sql + '] [varchar] (50) NULL'
    exec(@sql)
    set @counter = @counter + 1
end

--filling Pivot-Table
--inserting all Projects with Year & Month, so we got something to select
insert into test.dbo.testtable_pivot
    (Project, Year_Name, Month_Name)
select distinct Project, Year_Name, Month_Name
from test.dbo.testtable_final

--Cursor for traversing the Final-Table
declare cur_update cursor for 
select project, year_name, month_name, field, value, [user]
from test.dbo.testtable_final
open cur_update

fetch next from cur_update into @project, @year_name, @month_name, @field, @value, @user
while @@FETCH_STATUS = 0 
        begin
    set @sql = 'update test.dbo.testtable_pivot set [User] = ''' +@user + ''' where test.dbo.testtable_pivot.project=''' +@project+ ''' and test.dbo.testtable_pivot.year_name= '''+@year_name+ ''' and test.dbo.testtable_pivot.month_name=' +@month_name
    exec(@sql)
    set @sql = 'update test.dbo.testtable_pivot set [' +@field+ '] = ''' +@value + ''' where test.dbo.testtable_pivot.project=''' +@project+ ''' and test.dbo.testtable_pivot.year_name= '''+@year_name+ ''' and test.dbo.testtable_pivot.month_name=' +@month_name
    exec(@sql)
    fetch next from cur_update into @project, @year_name, @month_name, @field, @value, @user
end
close cur_update
deallocate cur_update

/*
-- Error. Rollback & inform support
if @@ERROR > 0  
                Begin
                EXEC msdb.dbo.sp_send_dbmail
                        @profile_name = 'cgate mail',
                        @recipients = 'support@x.de',
                        @body = '',
                        @subject = 'Fehler'
                Rollback Transaction
                End
                */

-- Success, commit transaction          
Commit Transaction


