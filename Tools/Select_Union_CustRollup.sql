SELECT dbo.LU_SIV_KrDarstellung.Parent

SELECT dbo.LU_SIV_KrDarstellung.Parent.DarstellungsArt_ID (Integer)

    SELECT Auspraegung_ID, Text, CASE Auspraegung_ID WHEN 1 THEN 2 WHEN 4 THEN 3 ELSE 0 END AS Sort, '' AS CustRollup
    FROM dbo.LU_SIV_SatzArt

UNION
    SELECT 500 AS Auspraegung_ID, 'Vorjahr_IST_TEUR' AS Expr1, 1 AS Sort,
        'IIF(membertostr([Dim_Zeit].[Geschaeftsjahr].currentmember) = "[Dim_Zeit].[Geschaeftsjahr].[All]", (parallelperiod([Dim_Zeit].[Kalenderjahr].[Jahr_ID],1),[Dim_Auspraegung].&[1]),
 (parallelperiod([Dim_Zeit].[Geschaeftsjahr].GJ_ID,1),[Dim_Auspraegung].&[1]))'
                        AS CustRollup
UNION
    SELECT 501 AS Auspraegung_ID, 'Vorjahr_IST_TEUR_YTD' AS Expr1, 4 AS Sort,
        'IIF([Dim_DarstellungsartHGB].[Parent].currentmember = "[Dim_DarstellungsartHGB].[Parent].&[0]",([Dim_DarstellungsartHGB].[Parent].&[9932999020],[Measures].[Brutto]),
 IIF([Dim_DarstellungsartHGB].[Parent].currentmember = "
 [Dim_DarstellungsartHGB].[Parent].&[1]"
 ,([Dim_DarstellungsartHGB].[Parent].&[3100000000],[Measures].[Brutto]),
 SUM(PERIODSTODATE(Dim_Zeit.Geschaeftsjahr.Gj_ID,parallelperiod([Dim_Zeit].[Geschaeftsjahr].GJ_ID,1)),([Dim_Auspraegung].&[1]))))'
                        AS CustRollup
UNION
    SELECT 502 AS Auspraegung_ID, 'IST_TEUR_YTD' AS Expr1, 5 AS Sort,
        'IIF([Dim_DarstellungsartHGB].[Parent].currentmember = "[Dim_DarstellungsartHGB].[Parent].&[0]",([Dim_DarstellungsartHGB].[Parent].&[9932999020],[Measures].[Brutto]),
 IIF([Dim_DarstellungsartHGB].[Parent].currentmember = "
 [Dim_DarstellungsartHGB].[Parent].&[1]"
 ,([Dim_DarstellungsartHGB].[Parent].&[3100000000],[Measures].[Brutto]),
 SUM(PERIODSTODATE(Dim_Zeit.Geschaeftsjahr.Gj_ID,[Dim_Zeit].[Geschaeftsjahr].currentmember),([Dim_Auspraegung].&[1]))))'
                        AS CustRollup
UNION
    SELECT 503 AS Auspraegung_ID, 'PLAN_TEUR_YTD' AS Expr1, 6 AS Sort,
        'IIF([Dim_DarstellungsartHGB].[Parent].currentmember = "[Dim_DarstellungsartHGB].[Parent].&[0]",([Dim_DarstellungsartHGB].[Parent].&[9932999020],[Measures].[Brutto]),
 IIF([Dim_DarstellungsartHGB].[Parent].currentmember = "
 [Dim_DarstellungsartHGB].[Parent].&[1]"
 ,([Dim_DarstellungsartHGB].[Parent].&[3100000000],[Measures].[Brutto]),
 SUM(PERIODSTODATE(Dim_Zeit.Geschaeftsjahr.Gj_ID,[Dim_Zeit].[Geschaeftsjahr].currentmember),([Dim_Auspraegung].&[4]))))'
                        AS CustRollup
