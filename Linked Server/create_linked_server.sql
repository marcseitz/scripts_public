--
-- Create all Linked Server.sql
--
-- Das Skript generiert nur SQL Queries, welche nicht ausgeführt werden!
-- 
-- Das Skript muss in der VM ausgeführt werden.
--
-- Dieses Skript generiert in einer VM Instanz alle benötigten Linked Server Einstellungen als SQL Script,
-- welches im Anschluss manuell ausgeführt werden muss.
--
BEGIN

     DECLARE @UserName                  NVARCHAR(50) = 'SQL_CARE_HFSAP_PRD',
	         @UserPasswort              NVARCHAR(50) = 'AjAJHZDEKLpsdoiuqwerNm9AB',
			 --@Environment               NVARCHAR(10) = 'INT',
			 @RemoteIPWithPortPrimary   NVARCHAR(50),
			 @RemoteIPWithPortSecondary NVARCHAR(50),
			 @RemoteServerNamePrimary   NVARCHAR(50) = 'REMOTE_',                -- wird noch erweitert um den entsprechenden Server\Instanz Teil
			 @RemoteServerNameSecondary NVARCHAR(50) = 'REMOTE_',                -- wird noch erweitert um den entsprechenden Server\Instanz Teil
			 @curServer                 NVARCHAR(50),
			 @curIPPort                 NVARCHAR(50);

	 DECLARE cur CURSOR FOR 
	 SELECT RemoteServerName = @RemoteServerNameSecondary+'DEGCCPPSQLPWV17\CCP_PE_06', 
	        RemoteIPWithPort = '10.240.5.206,41434'

     PRINT '-- '
	 PRINT '-- Create all Linked Server.sql'
	 PRINT '-- ';

     PRINT 'USE [master]'
     PRINT 'GO'

     OPEN cur
	 FETCH NEXT FROM cur INTO @curServer, @curIPPort;
     WHILE @@FETCH_STATUS = 0
     BEGIN   
          PRINT 'EXEC master.dbo.sp_addlinkedserver @server = N'''+@curServer+''', @srvproduct=N''SQLNCLI'', @provider=N''SQLNCLI'', @datasrc=N'''+@curIPPort+''' '
		  PRINT 'EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname = N'''+@curServer+''', @locallogin = NULL , @useself = N''False'', @rmtuser = N'''+@UserName+''', @rmtpassword = N'''+@UserPasswort+''' '
          FETCH NEXT FROM cur INTO @curServer, @curIPPort;
     END
     CLOSE cur;
     DEALLOCATE cur;	 
END