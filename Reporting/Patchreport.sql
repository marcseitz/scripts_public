;With CTE_SQLEditions([Major],[Minor],[Build],[BuildMinor])
AS
(
select 
 parsename(convert(varchar,serverproperty ('productversion')),4) As Major,
 parsename(convert(varchar,serverproperty ('productversion')),3) As Minor,
 parsename(convert(varchar,serverproperty ('productversion')),2) As Build,
 parsename(convert(varchar,serverproperty ('productversion')),1) As Buildminor
)
Select *
,CASE 

WHEN Major = 9 -- SQL 2005
THEN 
CASE 
WHEN Build < 5000 THEN 'SP4 f�r SQL 2005 mu� installiert wrden' --Aktuelle SP Buildnummer eintragen
END
WHEN Major = 10 And Minor = 0   -- SQL 2008 
THEN 
CASE
WHEN Build < 5500 THEN 'SP3 f�r SQL 2008 mu� installiert werden' --Aktuelle SP Buildnummer eintragen
END
WHEN Major = 10 And Minor = 50 -- SQL 2008 R2
THEN 
CASE
WHEN Build < 2500 THEN 'SP1 f�r SQL 2008 R2 mu� installiert werden' --Aktuelle SP Buildnummer eintragen
END 
END
FROM CTE_SQLEditions
