/*
	FileName:		Evaluate_Login_Security_Settings_By_Server.sql
	Autor:			Uwe Ricken - db Berater GmbH
	Date:			24.04.2015 / �berarbeitet am 23.12.2015 -> FROM sys.server_principals WHERE type IN ('U', 'G');

	Comment:		This script evaluates for each login its membership
					to dedicated server- and database roles.
					The output is a dedicated T-SQL-Command for each
					privileged access object

	Requirements:	sysadmin privileges are required
*/
-- if the user is not a sysadmin the routine will stop
IF IS_SRVROLEMEMBER('sysadmin') != 1
BEGIN
	RAISERROR ('Sie muessen Mitglied der Serverrolle [sysadmin] sein', 16, 1) WITH NOWAIT;
	RETURN
END
GO

USE master;
SET NOCOUNT ON;
GO

DECLARE @ScriptDate NVARCHAR(255) = '-- script created at: ' + CAST(GETDATE() AS NVARCHAR(20));

RAISERROR ('-- Creation of all logins if they do not exist!', 0, 1) WITH NOWAIT;
RAISERROR ('-- SQL LOGINS WILL NOT BE SCRIPTED!!!', 0, 1) WITH NOWAIT;
RAISERROR ('-- created by script of Uwe Ricken - db Berater GmbH', 0, 1) WITH NOWAIT;
RAISERROR (@ScriptDate, 0, 1) WITH NOWAIT;
GO

SELECT 'IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = ' + QUOTENAME(name, '''') + ')
CREATE LOGIN ' + QUOTENAME(name) + ' FROM WINDOWS WITH
	DEFAULT_DATABASE = ' + QUOTENAME(default_database_name) +  ',
	DEFAULT_LANGUAGE = ' + default_language_name + ';
GO

'
FROM sys.server_principals WHERE type IN ('U', 'G');
GO

-- Logins and roles
RAISERROR ('-- Adding windows logins to dedicated server roles...', 0, 1) WITH NOWAIT;
IF CAST(SERVERPROPERTY('ProductVersion') AS CHAR(2)) <= 10
SELECT	'sp_addsrvrolemember @loginame= ' + QUOTENAME(sp.name, '''') + ', @rolename = ' +QUOTENAME(sr.name, '''') + ';
GO'
FROM	sys.server_principals AS SP INNER JOIN sys.server_role_members AS SRM
		ON	(sp.principal_id = SRM.member_principal_id) INNER JOIN sys.server_principals AS SR
		ON	(SRM.role_principal_id = SR.principal_id)
WHERE	SP.type = 'U';

ELSE

SELECT	'ALTER SERVER ROLE ' + QUOTENAME(sr.name) + ' ADD MEMBER ' + QUOTENAME(SP.name) + ';
GO

'
FROM	sys.server_principals AS SP INNER JOIN sys.server_role_members AS SRM
		ON	(sp.principal_id = SRM.member_principal_id) INNER JOIN sys.server_principals AS SR
		ON	(SRM.role_principal_id = SR.principal_id)
WHERE	SP.type = 'U';
GO


/*----------------------- Database Users ---------------------------------*/
RAISERROR ('-- creation of all database users if they do not exist', 0, 1) WITH NOWAIT;
EXEC sp_msforeachdb 'USE [?];
RAISERROR (''-- Database: %s'', 0, 1, ''?'') WITH NOWAIT;
SELECT	''IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = '' + QUOTENAME(DP.name COLLATE SQL_Latin1_General_CP1_CI_AS, '''''''') + '')
CREATE USER '' + QUOTENAME(DP.name COLLATE SQL_Latin1_General_CP1_CI_AS) + '' FROM LOGIN '' + QUOTENAME(SP.name COLLATE SQL_Latin1_General_CP1_CI_AS) + ''
WITH DEFAULT_SCHEMA = '' + QUOTENAME (default_schema_name COLLATE SQL_Latin1_General_CP1_CI_AS) + '';
GO

''
FROM	sys.database_principals AS DP INNER JOIN sys.server_principals AS SP
		ON (DP.SId = SP.SId)
WHERE	SP.type = ''U'';';
GO

RAISERROR ('-- adding database users to dedicated database roles.', 0, 1) WITH NOWAIT;
IF CAST(SERVERPROPERTY('ProductVersion') AS CHAR(2)) <= 10
EXEC sp_msforeachdb 'USE [?];
RAISERROR (''-- Database: %s'', 0, 1, ''?'') WITH NOWAIT;
SELECT	''EXEC sp_addrolemember @rolename = '' + QUOTENAME(DR.NAME COLLATE SQL_Latin1_General_CP1_CI_AS, '''''''') + '', @membername = '' + QUOTENAME(DU.name COLLATE SQL_Latin1_General_CP1_CI_AS, '''''''') + '';''
FROM	sys.server_principals AS SP INNER JOIN sys.database_principals AS DU
		ON (SP.SID = DU.SID) INNER JOIN sys.database_role_members AS DRM
		ON (DU.principal_id = DRM.member_principal_id) INNER JOIN sys.database_principals AS DR
		ON (DRM.role_principal_id = DR.principal_id)
WHERE	SP.type = ''U'';'

ELSE

EXEC sp_msforeachdb 'USE [?];
RAISERROR (''-- Database: %s'', 0, 1, ''?'') WITH NOWAIT;
SELECT	''ALTER ROLE '' + QUOTENAME(DR.name COLLATE SQL_Latin1_General_CP1_CI_AS) + '' ADD MEMBER '' + QUOTENAME(DU.name COLLATE SQL_Latin1_General_CP1_CI_AS) + '';''
FROM	sys.server_principals AS SP INNER JOIN sys.database_principals AS DU
		ON (SP.SID = DU.SID) INNER JOIN sys.database_role_members AS DRM
		ON (DU.principal_id = DRM.member_principal_id) INNER JOIN sys.database_principals AS DR
		ON (DRM.role_principal_id = DR.principal_id)
WHERE	SP.type = ''U'';'
GO