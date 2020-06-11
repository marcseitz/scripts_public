

SELECT

c.name AS ColumnName
,t.name AS TypeName
,c.max_length
,c.PRECISION
,c.scale
FROM sys.columns AS c 

JOIN sys.types AS t ON c.user_type_id=t.user_type_id
where OBJECT_NAME(c.OBJECT_ID) = 'INSERT_TALE_NAME'
ORDER BY c.OBJECT_ID;