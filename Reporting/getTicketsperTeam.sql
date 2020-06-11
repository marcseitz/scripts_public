DECLARE @today datetime;
DECLARE @daybeforeyesterday datetime;

SET @today = getdate()
SET @daybeforeyesterday = DateAdd("d", -6, getdate())

CREATE TABLE #accepted
(OwnerTeam nvarchar(100),
AnzahlTickets int)

CREATE TABLE #waiting
(OwnerTeam nvarchar(100),
AnzahlTickets int)

CREATE TABLE #completed
(OwnerTeam nvarchar(100),
AnzahlTickets int)


INSERT INTO #accepted SELECT OwnerTeam, count(DISTINCT IncidentNumber) as AnzahlTickets_Accepted from FRONTRANGE.ITSM.dbo.Task 
where Status = 'Accepted'
AND OwnerTeam like '%SysOp%'
AND TaskType = 'Assignment'
GROUP BY  OwnerTeam


INSERT INTO #waiting SELECT OwnerTeam, count(DISTINCT IncidentNumber) as AnzahlTickets_Waiting from FRONTRANGE.ITSM.dbo.Task 
where Status = 'Waiting'
AND OwnerTeam like '%SysOp%'
AND TaskType = 'Assignment'
GROUP BY  OwnerTeam

INSERT INTO #completed
select OwnerTeam, count(OwnerTeam) as AnzahlTickets_Completed from FRONTRANGE.ITSM.dbo.Task 
where Status = 'Completed'
AND OwnerTeam like 'SysOp%'
AND TaskType = 'Assignment'
AND ResolvedDateTime >= @daybeforeyesterday
GROUP BY OwnerTeam

select t1.owner as OwnerTeam_accepted, t2.AnzahlTickets as AnzahlTickets_accepted , t3.AnzahlTickets as AnzahlTickets_waiting, t4.AnzahlTickets as AnzahlTickets_completed  from SysOp.dbo.owner as t1
LEFT OUTER JOIN #waiting as t3 on t1.owner = t3.OwnerTeam
LEFT OUTER JOIN #completed as t4 on t1.owner = t4.OwnerTeam
LEFT OUTER JOIN #accepted as t2 on t1.owner = t2.OwnerTeam

drop table #accepted
drop table #completed
drop table #waiting