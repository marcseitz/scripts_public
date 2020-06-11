-- Temptable erstellen zum Sammeln der Anzahl der Instanzen die dem Patchlevel nicht entsprechen
CREATE TABLE #tmp
( countsrv int)
-- Abfrage aller SQL 2000 Instanzen und schreiben des Ergebnis in die Temptable
  DECLARE @sql2000 int
  SET @sql2000 = (select Build from Reporting.dbo.SQL_build where Major = 8)
   INSERT INTO #tmp
  select count(srv_name) as countsrv from SQLMGT.dbo.tbl_SQLReport where major = 8 and majorbuild < @sql2000

  -- Abfrage aller SQL 2005 Instanzen und schreiben des Ergebnis in die Temptable
    DECLARE @sql2005 int
  SET @sql2005 = (select Build from Reporting.dbo.SQL_build where Major = 9)
     INSERT INTO #tmp
  select count(srv_name) as countsrv from SQLMGT.dbo.tbl_SQLReport where major = 9 and majorbuild < @sql2005

  -- Abfrage aller SQL 2008 Instanzen und schreiben des Ergebnis in die Temptable
    DECLARE @sql2008 int
  SET @sql2008 = (select Build from Reporting.dbo.SQL_build where Major = 10 AND Minor = 0)
  	   INSERT INTO #tmp
  select count(srv_name) as countsrv  from SQLMGT.dbo.tbl_SQLReport where major = 10 AND minor = 0 and majorbuild < @sql2008

  -- Abfrage aller SQL 2008 R2 Instanzen und schreiben des Ergebnis in die Temptable
    DECLARE @sql2008r2 int
	  SET @sql2008r2 = (select Build from Reporting.dbo.SQL_build where Major = 10 AND Minor = 50)
  	   INSERT INTO #tmp
  select count(srv_name) as countsrv from SQLMGT.dbo.tbl_SQLReport where major = 10 AND minor = 50 and majorbuild < @sql2008r2

  -- Abfrage aller SQL 2012 Instanzen und schreiben des Ergebnis in die Temptable
  DECLARE @sql2012 int
   SET @sql2012 = (select Build from Reporting.dbo.SQL_build where Major = 11)
      INSERT INTO #tmp
  select count(srv_name) as countsrv from SQLMGT.dbo.tbl_SQLReport where major = 11 and majorbuild < @sql2012

  -- Errechnen der Gesamtsumme der Instanzen
  DECLARE @gesamt int
  SET @gesamt = (select count(srv_name) from SQLMGT.dbo.tbl_SQLReport)
  -- Rechnen beider Summen (Gesamtliste zu Patchen und Gesamtliste)
  select sum(countsrv) as Patchen, @gesamt as Gesamt from #tmp
  --select count(srv_name) from SQLMGT.dbo.tbl_SQLReport

  -- Löschen der Temptable
  drop table #tmp
