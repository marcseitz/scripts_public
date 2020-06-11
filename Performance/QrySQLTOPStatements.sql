DECLARE @startdate datetime
SET @startdate = DateAdd(d, -2, getdate())
SELECT 
     distinct ora.[monitored_object_display_name] INTO #srvnames
          FROM [DE-DACMGT997WP].[msdb].[dbo].[sysmanagement_shared_registered_servers_internal] mgt
               JOIN [spotlight_monitored_objects] ora on mgt.server_name  LIKE ora.[monitored_object_display_name]+'%'
               JOIN [DE-DACMGT997WP].[msdb].[dbo].[sysmanagement_shared_server_groups_internal] grp on mgt.server_group_id = grp.server_group_id
                   where ora.technology_id = 2 AND grp.parent_id = 9
    
select
sp.timecollected, so.monitored_object_display_name,
max(case when sn.statistic_name = 'totalworkertime' then sp.raw_value end) as 'totalworkertime',
max(case when sn.statistic_name = 'executioncount' then sp.raw_value end) as 'executioncount',
max(case when sn.statistic_name = 'totallogicalreads' then sp.raw_value end) as 'totallogicalreads',
max(case when sn.statistic_name = 'totallogicalwrites' then sp.raw_value end) as 'totallogicalwrites',
max(case when sn.statistic_name = 'totalelapsedtime' then sp.raw_value end) as 'totalelapsedtime',
max(case when sn.statistic_name = 'sqltext' then sp.raw_value end) as 'sqltext'
INTO #tmp_qry
from
spotlight_perfdata sp
left join spotlight_stat_classes sc on sp.statistic_class_id = sc.statistic_class_id
left join spotlight_stat_names sn on sp.statistic_name_id = sn.statistic_name_id
left join spotlight_monitored_objects so on sp.monitored_object_id = so.monitored_object_id
where
sc.statistic_class_name = 'dmexecquerystatstop'
	AND sp.timecollected BETWEEN @startdate and GETDATE()
group by
sp.timecollected, sp.statistic_key_id, so.monitored_object_display_name
order by
sp.timecollected, so.monitored_object_display_name

/*

select a.timecollected
, a.monitored_object_display_name
, a.totalworkertime
, a.executioncount
, a.totalelapsedtime
, a.totallogicalreads
, a.totallogicalwrites
, a.sqltext from #tmp_qry a
INNER JOIN(
select ROW_NUMBER() OVER (ORDER BY tl.monitored_object_display_name) as RowNumber
,tl.timecollected
, tl.monitored_object_display_name
, tl.totalworkertime
, tl.executioncount
, tl.totalelapsedtime
, tl.totallogicalreads
, tl.totallogicalwrites
, tl.sqltext
 from #tmp_qry tl
JOIN #srvnames srv on srv.monitored_object_display_name = tl.monitored_object_display_name
) tl on a.monitored_object_display_name = tl.monitored_object_display_name
where tl.RowNumber < 5
*/


 
--where x.a < 5 

select tl.timecollected, tl.monitored_object_display_name, tl.totalworkertime, tl.executioncount, tl.totalelapsedtime, tl.totallogicalreads, tl.totallogicalwrites, tl.sqltext from #tmp_qry tl
JOIN #srvnames srv on srv.monitored_object_display_name = tl.monitored_object_display_name
where totalworkertime > 0 
GROUP by tl.monitored_object_display_name, timecollected, tl.totalworkertime, tl.totallogicalwrites, tl.totallogicalreads, tl.executioncount, totalelapsedtime, tl.sqltext
order by totalworkertime DESC

drop table #tmp_qry
drop table #srvnames

