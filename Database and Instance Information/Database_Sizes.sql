USE MASTER

----
SET NOCOUNT  ON

DECLARE  @dbname SYSNAME

DECLARE  @string SYSNAME

SET @string = ''

SET @dbname = ''

--start temp tables
CREATE TABLE #DBS (
  DBID   INT,
  DBNAME VARCHAR(50))

CREATE TABLE #DATAFILESTATS (
  DBNAME       VARCHAR(50),
  FLAG         BIT DEFAULT 0,
  FILEID       TINYINT,
  [FILEGROUP]  TINYINT,
  TOTALEXTENTS DEC(15,1),
  USEDEXTENTS  DEC(15,1),
  [NAME]       VARCHAR(100),
  [FILENAME]   SYSNAME)

CREATE TABLE #SIZEINFO (
  DBNAME          VARCHAR(30) NOT NULL PRIMARY KEY CLUSTERED,
  TOTAL           DEC(15,1),
  DATA            DEC(15,1),
  DATA_USED       DEC(15,1),
  [DATA (%)]      DEC(15,1),
  DATA_FREE       DEC(15,1),
  [DATA_FREE (%)] DEC(15,1),
  LOG             DEC(15,1),
  LOG_USED        DEC(15,1),
  [LOG (%)]       DEC(15,1),
  LOG_FREE        DEC(15,1),
  [LOG_FREE (%)]  DEC(15,1),
  STATUS          DEC(15,1))

--End temp tables
DECLARE  @dbCount INT

DECLARE  @iCount INT

INSERT INTO #DBS
SELECT DBID,
       NAME
FROM   MASTER..SYSDATABASES

SET @dbcount = (SELECT COUNT(* )
                FROM   #DBS)

--select * from #dbs
--start loop
WHILE @dbcount > 0
  BEGIN
    SELECT   TOP 1 @dbname = DBNAME
    FROM     #DBS
    ORDER BY DBNAME ASC
    
    IF @@ROWCOUNT = 0
      BREAK
    
    SET @string = 'use [' + @dbname + '] DBCC SHOWFILESTATS with no_infomsgs'
    
    INSERT INTO #DATAFILESTATS
               (FILEID,
                [FILEGROUP],
                TOTALEXTENTS,
                USEDEXTENTS,
                [NAME],
                [FILENAME])
    EXEC( @string)
    
    UPDATE #DATAFILESTATS
    SET    DBNAME = @dbname,
           FLAG = 1
    WHERE  FLAG = 0
    
    UPDATE #DATAFILESTATS
    SET    TOTALEXTENTS = (SELECT SUM(TOTALEXTENTS) * 8 * 8192.0 / 1048576.0
                           FROM   #DATAFILESTATS
                           WHERE  DBNAME = @dbname)
    WHERE  FLAG = 1
           AND FILEID = 1
           AND FILEGROUP = 1
           AND DBNAME = @dbname
    
    UPDATE #DATAFILESTATS
    SET    USEDEXTENTS = (SELECT SUM(USEDEXTENTS) * 8 * 8192.0 / 1048576.0
                          FROM   #DATAFILESTATS
                          WHERE  DBNAME = @dbname)
    WHERE  FLAG = 1
           AND FILEID = 1
           AND FILEGROUP = 1
           AND DBNAME = @dbname
    
    DELETE FROM #DBS
    WHERE       DBNAME = @dbname
    
    SET @dbcount = @dbcount - 1
  END

--end loop
--start #sizeinfo load & update
INSERT #SIZEINFO
      (DBNAME,
       LOG,
       [LOG (%)],
       STATUS)
EXEC( 'dbcc sqlperf(logspace) with no_infomsgs')

UPDATE #SIZEINFO
SET    DATA = D.TOTALEXTENTS
FROM   #DATAFILESTATS D
       JOIN #SIZEINFO S
         ON D.DBNAME = S.DBNAME
WHERE  D.FLAG = 1
       AND D.FILEID = 1
       AND D.FILEGROUP = 1

UPDATE #SIZEINFO
SET    DATA_USED = D.USEDEXTENTS
FROM   #DATAFILESTATS D
       JOIN #SIZEINFO S
         ON D.DBNAME = S.DBNAME
WHERE  D.FLAG = 1
       AND D.FILEID = 1
       AND D.FILEGROUP = 1

UPDATE #SIZEINFO
SET    TOTAL = (DATA + LOG)

UPDATE #SIZEINFO
SET    [DATA (%)] = (DATA_USED * 100.0 / DATA)

UPDATE #SIZEINFO
SET    DATA_FREE = (DATA - DATA_USED)

UPDATE #SIZEINFO
SET    [DATA_FREE (%)] = (100 - [DATA (%)])

UPDATE #SIZEINFO
SET    LOG_USED = (LOG * [LOG (%)] / 100.0)

UPDATE #SIZEINFO
SET    LOG_FREE = (LOG - LOG_USED)

UPDATE #SIZEINFO
SET    [LOG_FREE (%)] = (LOG_FREE * 100.0 / LOG)

--end #sizeinfo load & update
BEGIN
  --final select for display
  SELECT DBNAME AS DB,
         TOTAL AS 'Total(mb)',
         DATA AS 'Data(mb)',
         DATA_USED AS 'Data Used(mb)',
         [DATA (%)],
         DATA_FREE AS 'Data Free(mb)',
         [DATA_FREE (%)] AS 'Data Free(%)',
         LOG AS 'Log(mb)',
         LOG_USED AS 'Log Used(mb)',
         [LOG (%)] AS 'Log Used(%)',
         LOG_FREE AS 'Log free(mb)',
         [LOG_FREE (%)] AS 'Log Free(%)'
  FROM     #SIZEINFO
  ORDER BY DBNAME ASC
END

DROP TABLE #DATAFILESTATS 
DROP TABLE #SIZEINFO 
DROP TABLE #DBS