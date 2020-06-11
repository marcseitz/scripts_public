USE SysOp
DECLARE @today datetime;
DECLARE @daytime int;
DECLARE @nighttime int;
SET @today = getdate()

CREATE TABLE #impsteps(
	[RecId] [char](32) NOT NULL,
	[ChangeNumber] [decimal](10, 0) NULL,
	[OwnerTeam] [varchar](50) NULL,
	[Status] [varchar](40) NULL,
	[ResolvedDateTime] datetime)
	
INSERT INTO #impsteps
select RecId, ChangeNumber, OwnerTeam, Status, ResolvedDateTime  from FRONTRANGE.ITSM.dbo.TaskChangePlan where
Status = 'Completed' AND
OwnerTeam like 'SysOp%' AND 
datediff(d,ResolvedDateTime,GETDATE()) = 4


select * from #impsteps WHERE convert(char(8), ResolvedDateTime, 108) BETWEEN '08:00:00.000' AND '18:00:00.000'

select * from #impsteps WHERE convert(char(8), ResolvedDateTime, 108) NOT BETWEEN '08:00:00.000' AND '18:00:00.00'

drop table #impsteps