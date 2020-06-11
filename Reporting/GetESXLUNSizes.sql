DECLARE @space bigint
DECLARE @minsize bigint


SET @minsize = 295302070272


CREATE TABLE #esxluns
(
NAME nvarchar(255),
STORAGE_URL nvarchar(255),
CAPACITY bigint,
FREE_SPACE bigint,
dbname nvarchar(100))

INSERT INTO #esxluns
SELECT 
      [NAME]
      ,[STORAGE_URL]
      ,CAST (CAPACITY AS bigint)
      ,[FREE_SPACE]
      , 'vcdb4'
      
  FROM [ESX003].[vcdb4].[dbo].[VPX_DATASTORE]
  
INSERT INTO #esxluns
SELECT 
      [NAME]
      ,[STORAGE_URL]
      ,CAST (CAPACITY AS bigint)
      ,[FREE_SPACE]
      , 'vcdb2'
      
  FROM [ESX004].[VCDB2].[dbo].[VPX_DATASTORE]
  
INSERT INTO #esxluns
SELECT 
      [NAME]
      ,[STORAGE_URL]
      ,CAST (CAPACITY AS bigint)
      ,[FREE_SPACE]
      , 'vcdb3'
      
  FROM [ESX005].[VCDB3].[dbo].[VPX_DATASTORE]
  
INSERT INTO #esxluns
SELECT 
      [NAME]
      ,[STORAGE_URL]
      ,CAST (CAPACITY AS bigint)
      ,[FREE_SPACE]
      , 'vcdb5'
      
  FROM [ESX005].[VCDB5].[dbo].[VPX_DATASTORE]

INSERT INTO #esxluns
SELECT 
      [NAME]
      ,[STORAGE_URL]
      ,CAST (CAPACITY AS bigint)
      ,[FREE_SPACE]
      , 'vcdb6'
      
  FROM [ESX005].[VCDB6].[dbo].[VPX_DATASTORE]

INSERT INTO #esxluns
SELECT 
      [NAME]
      ,[STORAGE_URL]
      ,CAST (CAPACITY AS bigint)
      ,[FREE_SPACE]
      , 'vcdb7'
      
  FROM [ESX005].[VCDB7].[dbo].[VPX_DATASTORE]

INSERT INTO #esxluns
SELECT 
      [NAME]
      ,[STORAGE_URL]
      ,CAST (CAPACITY AS bigint)
      ,[FREE_SPACE]
      , 'vcdb1'
      
  FROM [ESX006].[vcdb1].[dbo].[VPX_DATASTORE]
  
INSERT INTO #esxluns
  SELECT 
      [NAME]
      ,[STORAGE_URL]
      ,CAST (CAPACITY AS bigint)
      ,[FREE_SPACE]
      , 'vcdb9'
      
  FROM [ESX006].[vcdb9].[dbo].[VPX_DATASTORE]



SET @space = (

SELECT CAST(MIN(FREE_SPACE) AS bigint)
      
  FROM #esxluns
WHERE NAME <> 'TransferLUN')
   
  select * from #esxluns
  where NAME <> 'TransferLUN'
  ORDER BY FREE_SPACE ASC
  

DROP table #esxluns