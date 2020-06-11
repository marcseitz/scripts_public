<#
    ACHTUNG: Das Skript benötigt Sysadmin Rechte in der DB !!!
#>

cls
$_Instanz = "DE-DACADMDWV996\DE_RDS_D_01"
$_DB = "RDFarm"
$_Gruppe = "PWCDEDEV\GR_SRV_RDS_Broker"

$_DB_Log = $_DB + "_log"
$_quelle = $("SELECT physical_name FROM sys.master_files Where name = '$_DB_Log'")
$_quellpfad = $(Invoke-Sqlcmd -Query "$_quelle" -ServerInstance "$_Instanz").physical_name
$_zielpfad = $_quellpfad.Replace("UserDBs","UserLogs")
$_node = $($_Instanz).Split("\")[0]
$_node = $(Resolve-DnsName($_node)).name

#######
#set-offline

write-host "set DB $_DB offline"

$_query = "USE master
GO
ALTER DATABASE $_DB SET OFFLINE WITH ROLLBACK IMMEDIATE
GO"

Invoke-Sqlcmd -Query "$_query" -ServerInstance "$_Instanz" 
write-host "wait"
Start-Sleep 30


#######
# Move DB Files

write-host "Move files for $_DB from $_quellpfad to $_zielpfad"

Invoke-Command -ComputerName $_node -command { 
    move-item $args[0] $args[1] 
} -ArgumentList $_quellpfad,$_zielpfad


#######
# Alter DB

write-host "alter filedirectory in $_DB"

$_query = "USE master
GO
ALTER DATABASE $_DB 
MODIFY FILE 
( NAME = $_DB_Log, 
FILENAME = '$_zielpfad')"


Invoke-Sqlcmd -Query "$_query" -ServerInstance "$_Instanz"
write-host "wait"
Start-Sleep 30


#######
#set-online

write-host "set DB $_DB online"

$_query = "USE master
GO
ALTER DATABASE $_DB SET ONLINE;"

Invoke-Sqlcmd -Query "$_query" -ServerInstance "$_Instanz"
write-host "wait"
Start-Sleep 30

#######
#config DB       , MAXSIZE = UNLIMITED

write-host "configure $_DB"

$_query = "USE [master]
GO
ALTER DATABASE [$_DB] MODIFY FILE ( NAME = N'$_DB_log', SIZE = 524288KB , FILEGROWTH = 262144KB )
GO
ALTER DATABASE [$_DB] MODIFY FILE ( NAME = N'$_DB', SIZE = 1048576KB , FILEGROWTH = 102400KB )
GO
DROP USER [$_Gruppe]
GO
USE [$_DB]
GO
EXEC dbo.sp_changedbowner @loginame = N'pwcsysop', @map = false
GO
CREATE USER [$_Gruppe] FOR LOGIN [$_Gruppe]
GO
ALTER ROLE [db_owner] ADD MEMBER [$_Gruppe]
GO"

Invoke-Sqlcmd -Query "$_query" -ServerInstance "$_Instanz"

write-host "Finish" -ForegroundColor Green

