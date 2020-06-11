
SELECT DISTINCT pvpr.ManagedEntityRowId as Srvname
into #tmp
from [DE-DACDBS912WP\SCOMDWH].[OperationsManagerDW].Perf.vPerfRaw pvpr 
inner join [DE-DACDBS912WP\SCOMDWH].[OperationsManagerDW].dbo.vManagedEntity vme on pvpr.ManagedEntityRowId = vme.ManagedEntityRowId 
inner join [DE-DACDBS912WP\SCOMDWH].[OperationsManagerDW].dbo.vPerformanceRuleInstance vpri on pvpr.PerformanceRuleInstanceRowId = vpri.PerformanceRuleInstanceRowId 
inner join [DE-DACDBS912WP\SCOMDWH].[OperationsManagerDW].dbo.vPerformanceRule vpr on vpr.RuleRowId = vpri.RuleRowId 
WHERE CounterName = 'RL18Compliance'

select * from (
select [Path], SampleValue, max(DateTime) as DateTime, ROW_NUMBER() OVER (PARTITION BY pvpr.ManagedEntityRowId ORDER BY DateTime DESC) AS rn
from [DE-DACDBS912WP\SCOMDWH].[OperationsManagerDW].Perf.vPerfRaw pvpr 

left join #tmp t on pvpr.ManagedEntityRowId = t.Srvname
left join [DE-DACDBS912WP\SCOMDWH].[OperationsManagerDW].dbo.vManagedEntity vme on pvpr.ManagedEntityRowId = vme.ManagedEntityRowId 
left join [DE-DACDBS912WP\SCOMDWH].[OperationsManagerDW].dbo.vPerformanceRuleInstance vpri on pvpr.PerformanceRuleInstanceRowId = vpri.PerformanceRuleInstanceRowId 
left join [DE-DACDBS912WP\SCOMDWH].[OperationsManagerDW].dbo.vPerformanceRule vpr on vpr.RuleRowId = vpri.RuleRowId 
WHERE CounterName = 'RL18Compliance'
GROUP BY Path, SampleValue, Srvname, pvpr.ManagedEntityRowId, DateTime
 ) q
 WHERE rn = 1

drop table #tmp