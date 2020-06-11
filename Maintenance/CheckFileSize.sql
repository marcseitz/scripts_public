SELECT r.ItemID
	   , r.Path
	   , r.Name
	   , r.ParentID
	   , CASE r.Type
			WHEN 1	THEN 'Folder'
			WHEN 2	THEN 'SSRS Report'
			WHEN 3	THEN 'Branding Content'
			WHEN 5	THEN 'Data Source'
			WHEN 8	THEN 'KPI Dataset'
			WHEN 11	THEN 'KPI Card'
			WHEN 13	THEN 'PBIX Report'
		END AS ContentType

	   --,r.Property
	   , r.Description
	   , r.Hidden  -- 0 or 1
	   --,r.CreatedByID
	   , c.UserName AS CreatedBy
	   , r.CreationDate
	   , m.UserName AS ModifiedBy
	   , r.ModifiedDate
	   --,r.MimeType --only useful for things like images etc.
	   --,r.SnapshotLimit
	   --,r.Parameter -- xml can be used to figure out params on SSRS reports
	   --,r.PolicyID
	   --,r.PolicyRoot
	   --,r.ExecutionFlag
	   --,r.ExecutionTime
	   --,r.SubType
	   --,r.ComponentID
	   , r.ContentSize
FROM dbo.Catalog r
    LEFT OUTER JOIN dbo.Users c
    ON r.CreatedByID = c.UserID
    LEFT OUTER JOIN dbo.Users m
    ON r.ModifiedByID = m.UserID
WHERE	LEFT(PATH,37) <> '/68f0607b-9378-4bbb-9e70-4da3d7d66838' -- ignore branding items
    AND LEFT(PATH,14) <> '/Users Folders'
-- ignore user folders
ORDER BY r.PATH;