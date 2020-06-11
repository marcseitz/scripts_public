
USE [test]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER PROCEDURE [dbo].[usp_EXCEL_DATA_UPDATE]
AS


Begin Transaction

delete test.dbo.testtable_final
from (SELECT Max(addDate) as addDate, Project, Year_Name, Month_Name
    FROM test.dbo.testtable
    GROUP BY Project, Year_Name, Month_Name
                ) M1 inner join

    test.dbo.testtable_final M2
    on M1.Project=M2.Project and M1.Year_Name=M2.Year_Name and M1.Month_Name=M2.Month_Name

--insert new data
insert into test.dbo.testtable_final
    (Item_ID, [USER], Project, Year_Name, Month_Name, Source_Table, Typ, Field, Value, addDate)
(Select M2.Item_ID, M2.[User], M2.Project, M2.Year_Name, M2.Month_Name, M2.Source_Table, M2.Typ, M2.Field, M2.Value, M2.addDate
from
    (SELECT Max(addDate) as addDate, Project, Year_Name, Month_Name
    FROM test.dbo.testtable
    GROUP BY Project, Year_Name, Month_Name
                ) M1
    inner join test.dbo.testtable M2
    on  M1.Project=M2.Project and m1.Year_Name=m2.Year_Name and M1.Month_Name=M2.Month_Name and m1.AddDate=m2.AddDate
   )

-- deleting transfer table, activate if needed    
-- truncate table @trans_table

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

