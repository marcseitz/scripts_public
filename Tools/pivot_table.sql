--pivot table
DECLARE @max_nbr_cols int,
 @counter int,
 @sql varchar(2000)

CREATE TABLE #tmp_data_hold
(
    counter int identity(1, 1) NOT NULL,
    field1 char(1) NULL
)

INSERT INTO #tmp_data_hold
SELECT *
FROM YourTable

SELECT @max_nbr_cols = COUNT(*)
FROM YourTable

SET @counter = 1
SET @sql = 'CREATE TABLE #tmp_pivot_table ('
WHILE @counter <= @max_nbr_cols
 BEGIN
    SET @sql = @sql + ' col' + CONVERT(varchar, @counter) + ' varchar(10) NULL,'
    SET @counter = @counter +1
END

SET @sql = STUFF(@sql, LEN(@sql), 1, ')')

EXEC(@sql)


SET @counter = 1
SET @sql = 'INSERT INTO #tmp_pivot_table SELECT '
WHILE @counter <= @max_nbr_cols
 BEGIN
    SET @sql = @sql + 'MAX(CASE counter WHEN ' + CONVERT(varchar, @counter) + ' THEN field1 ELSE '''' END) AS col' + CONVERT(varchar, @counter) + ', '
    SET @counter = @counter +1
END

SET @sql = STUFF(@sql, LEN(@sql), 1, '')

SET @sql = @sql + ' FROM #tmp_data_hold'

EXEC(@sql)


--DROP TABLE #tmp_data_hold

SELECT *
FROM #tmp_pivot_table
