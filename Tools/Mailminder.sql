SELECT
    CS.skill_code AS Child_skill_code,
    CS.skill_name AS Child_skill_name,
    A.Value,
    B.StartDateTime,
    PS.skill_code AS Parent_skill_code,
    PS.skill_name AS Parent_skill_name
INTO #TEMP
FROM [yourserver].[dbo].[MultisitePeriodDistribution] AS A
    INNER JOIN [yourserver].[stage].[stg_skill] AS CS ON A.ChildSkill=CS.skill_code
    INNER JOIN [yourserver].[dbo].[MultisitePeriod] AS B ON A.Parent=B.Id
    INNER JOIN [yourserver].[dbo].[MultisiteDay] AS C ON B.Parent=C.Id AND C.Version=(SELECT MAX(Version)
        FROM [yourserver].[dbo].[MultisiteDay]
        WHERE C.Skill=Skill AND IsDeleted=0 AND MultisiteDayDate=C.MultisiteDayDate)
    INNER JOIN [yourserver].[stage].[stg_skill] AS PS ON C.Skill=PS.skill_code
    INNER JOIN [yourserver].[mart].[dim_scenario] AS SZ ON SZ.scenario_code=C.Scenario
WHERE C.IsDeleted=0 AND SZ.scenario_name='Standard'


SELECT *
INTO #DATE
FROM [yourserver].mart.dim_date
SELECT *
INTO #INTERVAL
FROM [yourserver].mart.dim_interval
SELECT *
INTO #ZONE
FROM [yourserver].mart.dim_time_zone
SELECT *
INTO #ZONEBRIDGE
FROM [yourserver].mart.bridge_time_zone



SELECT A.Value,
    LD.date_id,
    LD.date_date,
    LI.interval_id,
    LI.halfhour_name,
    D.date_date+CAST(I.interval_start AS TIME) AS utc_intervalstart,
    A.Child_skill_name,
    A.Child_skill_code,
    A.Parent_skill_code,
    A.Parent_skill_name
INTO #TEMP2
FROM #TEMP AS A
    INNER JOIN #DATE AS D ON D.date_date=CAST(A.StartDateTime AS DATE)
    INNER JOIN #INTERVAL AS I ON CAST(I.interval_start AS TIME)=CAST(A.StartDateTime AS TIME)
    INNER JOIN #ZONEBRIDGE AS TZB ON D.date_id=TZB.date_id AND I.interval_id=TZB.interval_id
    INNER JOIN #ZONE AS TZ ON TZB.time_zone_id=TZ.time_zone_id
    INNER JOIN #DATE AS LD ON LD.date_id=TZB.local_date_id
    INNER JOIN #INTERVAL AS LI ON LI.interval_id=TZB.local_interval_id
WHERE TZ.time_zone_code='W. Europe Standard Time'


*/


SELECT
    CS.skill_code AS Child_skill_code,
    CS.skill_name AS Child_skill_name,
    A.Value,
    B.StartDateTime,
    B.EndDateTime,
    PS.skill_code AS Parent_skill_code,
    PS.skill_name AS Parent_skill_name
INTO #TEMP
FROM [yourserver].[dbo].[MultisitePeriodDistribution] AS A
    INNER JOIN [yourserver].[stage].[stg_skill] AS CS ON A.ChildSkill=CS.skill_code
    INNER JOIN [yourserver].[dbo].[MultisitePeriod] AS B ON A.Parent=B.Id
    INNER JOIN [yourserver].[dbo].[MultisiteDay] AS C ON B.Parent=C.Id AND C.Version=(SELECT MAX(Version)
        FROM [yourserver].[dbo].[MultisiteDay]
        WHERE C.Skill=Skill AND IsDeleted=0 AND MultisiteDayDate=C.MultisiteDayDate)
    INNER JOIN [yourserver].[stage].[stg_skill] AS PS ON C.Skill=PS.skill_code
    INNER JOIN [yourserver].[mart].[dim_scenario] AS SZ ON SZ.scenario_code=C.Scenario
WHERE C.IsDeleted=0 AND SZ.scenario_name='Standard'


CREATE INDEX Test ON #TEMP (StartDateTime, EndDateTime)


SELECT *
INTO #DATE
FROM [yourserver].mart.dim_date
WHERE date_date >= DATEADD(WEEK, 0, SkyNet.dbo.fn_mondaylast(DATEADD(DAY, 5, GETDATE()))) AND date_date < DATEADD(WEEK, 54, SkyNet.dbo.fn_mondaylast(DATEADD(DAY, 5, GETDATE())))
SELECT *
INTO #INTERVAL
FROM [yourserver].mart.dim_interval
SELECT *
INTO #ZONE
FROM [yourserver].mart.dim_time_zone
SELECT *
INTO #ZONEBRIDGE
FROM [yourserver].mart.bridge_time_zone


CREATE INDEX Test ON #DATE (date_date, date_id)
CREATE INDEX Test ON #INTERVAL (interval_start, interval_end, interval_id)
CREATE INDEX Test ON #ZONE (time_zone_id, time_zone_code)
CREATE INDEX Test ON #ZONEBRIDGE (date_id, interval_id, time_zone_id)


SELECT A.Value,
    LD.date_id,
    LD.date_date,
    LI.interval_id,
    LI.halfhour_name,
    D.date_date+CAST(I.interval_start AS TIME) AS utc_intervalstart,
    A.Child_skill_name,
    A.Child_skill_code,
    A.Parent_skill_code,
    A.Parent_skill_name
INTO #TEMP2
FROM #TEMP AS A
    INNER JOIN (#DATE AS D CROSS JOIN #INTERVAL AS I) ON D.date_date+I.interval_start >= A.StartDateTime AND D.date_date+I.interval_end <= A.EndDateTime
    INNER JOIN #ZONEBRIDGE AS TZB ON D.date_id=TZB.date_id AND I.interval_id=TZB.interval_id
    INNER JOIN #ZONE AS TZ ON TZB.time_zone_id=TZ.time_zone_id
    INNER JOIN #DATE AS LD ON LD.date_id=TZB.local_date_id
    INNER JOIN #INTERVAL AS LI ON LI.interval_id=TZB.local_interval_id
WHERE TZ.time_zone_code='W. Europe Standard Time'


CREATE INDEX Test ON #TEMP2 (Parent_skill_code, Child_skill_code)


SELECT *
INTO #SKILL
FROM [yourserver].mart.dim_skill
CREATE INDEX Test ON #SKILL (skill_code)



SELECT A.Value,
    A.date_id,
    A.date_date,
    A.interval_id,
    A.halfhour_name,
    A.utc_intervalstart,
    PS.skill_id AS Parent_skill_id,
    A.Parent_skill_name,
    CS.skill_id AS Child_skill_id,
    A.Child_skill_name
INTO #TEMP3
FROM #TEMP2 AS A
    INNER JOIN #SKILL AS PS ON PS.[skill_code]=Parent_skill_code
    INNER JOIN #SKILL AS CS ON CS.[skill_code]=Child_skill_code


SELECT *
INTO #FORECAST
FROM [yourserver].mart.fact_forecast_workload


TRUNCATE TABLE Workforce.dbo.Company_Call_Forecast
INSERT INTO Workforce.dbo.Company_Call_Forecast
    (utc_intervalstart, date_id, mininterval_id, date_date, halfhour_name,
    Child_skill_id, Child_skill_name, Company_forecasted_calls,
    Parent_skill_id, Parent_skill_name, Total_forecasted_calls)
SELECT
    MIN(B.utc_intervalstart) AS utc_intervalstart,
    B.date_id,
    MIN(B.interval_id),
    B.date_date,
    B.halfhour_name,
    B.Child_skill_id,
    B.Child_skill_name,
    SUM(A.forecasted_calls*B.Value) AS Company_forecasted_calls,
    B.Parent_skill_id,
    B.Parent_skill_name,
    SUM(A.forecasted_calls) AS Total_forecasted_calls
FROM #FORECAST AS A INNER JOIN
    #TEMP3 AS B ON A.skill_id=B.Parent_skill_id
WHERE B.utc_intervalstart=A.start_time
GROUP BY
B.date_id,
B.date_date,
B.halfhour_name,
B.Child_skill_id,
B.Child_skill_name,
B.Parent_skill_id,
B.Parent_skill_name



CREATE TABLE WFM_TEMP_FORECASTEXPORT
(
    workload_name NVARCHAR(100),
    date_date DATE,
    "07:00-07:30" FLOAT,
    "07:30-08:00" FLOAT,
    "08:00-08:30" FLOAT,
    "08:30-09:00" FLOAT,
    "09:00-09:30" FLOAT,
    "09:30-10:00" FLOAT,
    "10:00-10:30" FLOAT,
    "10:30-11:00" FLOAT,
    "11:00-11:30" FLOAT,
    "11:30-12:00" FLOAT,
    "12:00-12:30" FLOAT,
    "12:30-13:00" FLOAT,
    "13:00-13:30" FLOAT,
    "13:30-14:00" FLOAT,
    "14:00-14:30" FLOAT,
    "14:30-15:00" FLOAT,
    "15:00-15:30" FLOAT,
    "15:30-16:00" FLOAT,
    "16:00-16:30" FLOAT,
    "16:30-17:00" FLOAT,
    "17:00-17:30" FLOAT,
    "17:30-18:00" FLOAT,
    "18:00-18:30" FLOAT,
    "18:30-19:00" FLOAT,
    "19:00-19:30" FLOAT,
    "19:30-20:00" FLOAT,
    "20:00-20:30" FLOAT,
    "20:30-21:00" FLOAT,
    "21:00-21:30" FLOAT,
    "21:30-22:00" FLOAT,
    "22:00-22:30" FLOAT,
    "22:30-23:00" FLOAT,
    PRIMARY KEY (workload_name, date_date)
)



SELECT Child_skill_name, thisdate
INTO #TEMP2
FROM SegmentReportingLive.dbo.view_timetables
CROSS JOIN Workforce.dbo.Company_Call_Forecast
WHERE thisdate >= DATEADD(WEEK, 1, SkyNet.dbo.fn_mondaylast(DATEADD(DAY, 5, GETDATE()))) AND thisdate < DATEADD(WEEK, 53, SkyNet.dbo.fn_mondaylast(DATEADD(DAY, 5, GETDATE()))) AND thisdate <= (SELECT MAX(date_date)
    FROM Workforce.dbo.Company_Call_Forecast)
GROUP BY Child_skill_name, thisdate
ORDER BY Child_skill_name, thisdate


DECLARE @Query VARCHAR(MAX)
SET @Query = 'SELECT A.Child_skill_name AS workload_name, A.thisdate'
SELECT @Query = @Query + ', SUM(CASE halfhour_name WHEN ''' + halfhour_name + ''' THEN Company_forecasted_calls ELSE 0 END) AS [' + halfhour_name + ']'
FROM (SELECT DISTINCT TOP 1440
        halfhour_name
    FROM Workforce.dbo.Company_Call_Forecast
    WHERE mininterval_id BETWEEN 28 AND 90
    ORDER BY halfhour_name) AS V
INSERT INTO Auswertung_CIC.dbo.WFM_TEMP_FORECASTEXPORT
EXEC(@Query + ' FROM #TEMP2 AS A LEFT JOIN Workforce.dbo.Company_Call_Forecast AS B ON A.thisdate=B.date_date AND A.Child_skill_name=B.Child_skill_name GROUP BY A.thisdate, A.Child_skill_name ORDER BY A.Child_skill_name, A.thisdate')




