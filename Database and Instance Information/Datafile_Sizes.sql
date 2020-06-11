SELECT 
	DB_NAME(database_id) AS DBName, 
	CASE type_desc
		WHEN 'ROWS' THEN 'Data File'
		WHEN 'LOG' THEN 'Log File'
	END AS file_type,
	RIGHT(physical_name,CHARINDEX('\',REVERSE(physical_name))-1) AS FileName,
	physical_name,
	REPLACE(CAST((size*8) / (1024.) AS DECIMAL(9,2)),'.',',') AS DBSize_Mbs,
	CASE 
		--Fixed size with no growth
		WHEN growth = 0 THEN 'No Growth Allowed'
		WHEN is_percent_growth = 1 and growth > 0 THEN CAST(growth AS VARCHAR(10)) + ' %'
		WHEN is_percent_growth = 0 and growth > 0 THEN CAST(CAST((growth * 8.) / (1024.) AS INT) AS VARCHAR(10)) + ' Mbs'
	ELSE CAST(growth AS VARCHAR(10))
	END AS growth
FROM sys.master_files
