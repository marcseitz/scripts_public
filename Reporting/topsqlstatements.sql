
SELECT 
     distinct ora.[monitored_object_display_name] INTO #srvnames
          FROM [DE-DACMGT997WP].[msdb].[dbo].[sysmanagement_shared_registered_servers_internal] mgt
               JOIN [spotlight_monitored_objects] ora on mgt.server_name  LIKE ora.[monitored_object_display_name]+'%'
               JOIN [DE-DACMGT997WP].[msdb].[dbo].[sysmanagement_shared_server_groups_internal] grp on mgt.server_group_id = grp.server_group_id
                   where ora.technology_id = 2 AND grp.parent_id = 9
    
DECLARE @startdate datetime
SET @startdate = DateAdd(d, -7, getdate())

CREATE TABLE #tmp_ent_summary (servername nvarchar(256),passservername nvarchar(256), serverid int, timecollected datetime, stat_name nvarchar(128), raw_value sql_variant)
INSERT INTO #tmp_ent_summary
SELECT 
	sm.monitored_object_display_name
                ,sm.monitored_object_name
,a.monitored_object_id	
,a.timecollected
	,sn.statistic_name
	,a.raw_value
FROM
	spotlight_perfdata a (nolock)
	INNER JOIN spotlight_monitored_objects sm (nolock)
		ON a.monitored_object_id = sm.monitored_object_id
	INNER JOIN spotlight_technologies st (nolock)
		ON sm.technology_id = st.technology_id
	INNER JOIN spotlight_stat_classes sc (nolock)
		ON a.statistic_class_id = sc.statistic_class_id
	INNER JOIN spotlight_stat_names sn (nolock)
		ON a.statistic_name_id = sn.statistic_name_id
WHERE
	st.technology_name = 'database/sqlserver'
	AND ((sc.statistic_class_name = 'dmexecquerystatstop' AND sn.statistic_name = 'executioncount')
			OR	(sc.statistic_class_name = 'dmexecquerystatstop' AND sn.statistic_name = 'totallogicalreads' )
			OR	(sc.statistic_class_name = 'dmexecquerystatstop' AND sn.statistic_name = 'lastlogicalreads')
			OR (sc.statistic_class_name = 'dmexecquerystatstop' AND sn.statistic_name = 'totalworkertime')
			OR (sc.statistic_class_name = 'dmexecquerystatstop' AND sn.statistic_name = 'lastworkertime')
			OR (sc.statistic_class_name = 'dmexecquerystatstop' AND sn.statistic_name = 'totalelapsedtime')
			OR (sc.statistic_class_name = 'dmexecquerystatstop' AND sn.statistic_name = 'lastelapsedtime')
			OR (sc.statistic_class_name = 'dmexecquerystatstop' AND sn.statistic_name = 'lastexecutiontime')
			OR (sc.statistic_class_name = 'dmexecquerystatstop' AND sn.statistic_name = 'sqltext')
			)
	AND a.timecollected BETWEEN @startdate and GETDATE()
ORDER BY sm.monitored_object_display_name ASC, a.timecollected DESC



CREATE TABLE #tmp_case_table (servername nvarchar(256),passservername nvarchar(256), serverid int,  timecollected datetime, executioncount bigint, totallogicalreads bigint, lastlogicalreads bigint
, totalworkertime bigint, lastworkertime bigint, totalelapsedtime bigint, lastelapsedtime bigint, lastexecutiontime datetime, sqltext char(255))

INSERT INTO #tmp_case_table
SELECT
			servername
                                                ,passservername
                                                ,serverid
			,timecollected	
			,'executioncount' = case stat_name
				WHEN 'executioncount' THEN cast(raw_value as bigint)
				ELSE null
			END
			,'totallogicalreads' = case stat_name
				WHEN 'totallogicalreads' THEN cast(raw_value as bigint)
				ELSE null
			END
			,'lastlogicalreads' = case stat_name
				WHEN 'lastlogicalreads' THEN cast(raw_value as bigint)
				ELSE null
			END
			,'totalworkertime' = case stat_name
				WHEN 'totalworkertime' THEN cast(raw_value as bigint)
				ELSE null
			END
			,'lastworkertime' = case stat_name
				WHEN 'lastworkertime' THEN cast(raw_value as bigint)
				ELSE null
			END
			,'totalelapsedtime' = case stat_name
				WHEN 'totalelapsedtime' THEN cast(raw_value as bigint)
				ELSE null
			END
				,'lastelapsedtime' = case stat_name
				WHEN 'lastelapsedtime' THEN cast(raw_value as bigint)
				ELSE null
					END
				,'lastexecutiontime' = case stat_name
				WHEN 'lastexecutiontime' THEN cast(raw_value as date)
				ELSE null
			END
			,'sqltext' = case stat_name
				WHEN 'sqltext' THEN cast(raw_value as char(255))
				ELSE null
			END
		FROM
			#tmp_ent_summary
		GROUP BY 
			servername
                                               ,passservername
                                               ,serverid
			, timecollected
			, stat_name
			, raw_value

SELECT
*
FROM
	#tmp_case_table
JOIN #srvnames srv on srv.monitored_object_display_name = servername
GROUP BY servername, timecollected, passservername, serverid, executioncount, 
totallogicalreads, totalelapsedtime, totalworkertime, lastelapsedtime, lastexecutiontime,
lastlogicalreads, lastworkertime, sqltext, monitored_object_display_name


--DROP TABLE #tmp_ent_summary
--DROP TABLE #tmp_case_table
--DROP TABLE #srvnames

select * from #tmp_case_table
select * from #srvnames
select * from #tmp_ent_summary