USE [ReportServerViews]
GO

/****** Object:  View [MON].[Catalog]    Script Date: 1/9/2019 1:31:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [MON].[Catalog]
AS

WITH rootCTE AS
(
SELECT ParentID, ItemID, ItemID as [root],ModifiedByID, ModifiedDate
FROM ReportServer.dbo.[Catalog]
WHERE PolicyRoot = 1 

UNION ALL 

SELECT c.ParentID, c.ItemID, p.root, c.ModifiedByID , c.ModifiedDate
FROM rootCTE AS p
	INNER JOIN ReportServer.dbo.[Catalog] as c ON p.ItemID = c.ParentID	AND c.PolicyRoot = 0
)

SELECT 
	ParentID
	, ItemID
	, Name
	, [Path]
	, [Type]
	, sub.ContentSizeInMB
	, ConnectionType = CASE
							WHEN sub.HasDirectQuery = 'True' THEN 'Direct Query'
							WHEN sub.HasDirectQuery = 'False' THEN 'Import Mode'
							WHEN sub.HasDirectQuery IS NULL THEN 'Connect with DataSource'
							ELSE ''
						END 
	, RowLevelSecurity = CASE
							WHEN sub.HasDirectQuery = 'True' THEN 'integrated'
							WHEN sub.HasDirectQuery = 'False' THEN 'not sure'
							WHEN sub.HasDirectQuery IS NULL THEN 'integrated'
							ELSE ''
						END 
	, sub.SecurityRootID
	, sub.SecurityRootName
	, sub.SecurityRootPath
	, ModifiedBy = sub.UserName
	, sub.ModifiedDate

FROM (
SELECT TOP 50
	cte.ParentID
	, cte.ItemID
	, cat.[Name]
	, cat.[Path]
	, [Type] = CASE
					 WHEN cat.[Type] = '2' THEN 'Report'
					 WHEN cat.[Type] = '13' THEN 'PBIX'
					END
	, [ContentSizeInMB] = CAST(cat.ContentSize / (1024.0 *1024.0) AS DECIMAL(9,4))
	, HasDirectQuery = CAST(CAST(cat.Property AS NVARCHAR(MAX)) AS XML).value(N'(/Properties/HasDirectQuery)[1]','nvarchar(10)')
	, cte.root AS SecurityRootID
	, par.Name as SecurityRootName
	, par.Path as SecurityRootPath
	, usr.UserName
	, cat.ModifiedDate
FROM rootCTE cte
	INNER JOIN ReportServer.dbo.[Catalog] cat ON cte.ItemID = cat.ItemID
	LEFT JOIN ReportServer.dbo.[Catalog] par ON cte.root = par.ItemID
	LEFT JOIN ReportServer.dbo.[Users] usr ON cte.ModifiedByID = usr.UserID
WHERE cat.[Type] in (2,13)
ORDER BY cat.ContentSize desc) sub



GO


