DECLARE @today datetime;

SET @today = getdate()

SELECT OwnerTeam, count(IncidentNumber) as AnzahlTickets_Waiting, IncidentNumber , @today from FRONTRANGE.ITSM.dbo.Task 
where Status = 'Waiting'
AND OwnerTeam like '%SysOp Infra%'
AND TaskType = 'Assignment'
GROUP BY  OwnerTeam, IncidentNumber

