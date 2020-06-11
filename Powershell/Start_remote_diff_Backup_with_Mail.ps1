# Start remote SQL Server Backup und send mail
#cls

$Servername = "DE-DACSQLUWV016\DE_TST_03" 
$DB = "SQLcompliance"
$LW = "D:\Backup"
$log = "F:\SQL\temp\output_backup-$DB.txt"
$_from_mail = "SQL MGT Server <mssql_reportingservice@de.pwc.com>"
$_to_mail = "Matthias Korn <tobias.kolberg@de.pwc.com>"
 
$hostname = $($Servername.Split("\\"))[0]
$instancename = $($Servername.Split("\\"))[1]
$Ziel = "$LW\$DB.bak"
$sql = "BACKUP DATABASE [$DB] TO  DISK = N'$Ziel' WITH  DIFFERENTIAL , NOFORMAT, NOINIT,  NAME = N'$DB-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10 "
$Backupjob = $(sqlcmd -S $Servername -Q $sql -o "$log")

$lastline = $(Get-Content $log | select -Last 1)
if ($lastline -like "*success*") 
{
#    write-host "Backup gelaufen"
    $sub = „SQL Backup erfolgreich“
    $body = "Backup der DB $DB auf dem Server $Servername wurde erfolgreich im Dump: $Ziel erstellt. `r `n $(foreach ($line in $(Get-Content $log)) { "$line `r" })"
    Send-MailMessage -SmtpServer smtp-prod -to $_to_mail -from $_from_mail -Cc "tobias.kolberg@de.pwc.com" -Subject $sub -body $body -Encoding ([System.Text.Encoding]::UTF8)
}
else
{
#    write-host "Backup nicht gelaufen"
    $sub = „SQL Backup fehlgeschlagen“
    $body = "Backup fehlgeschlagen. siehe log: `r `n $(foreach ($line in $(Get-Content $log)) { "$line `r" })"
    Send-MailMessage -SmtpServer smtp-prod -to $_to_mail -from $_from_mail -Cc "tobias.kolberg@de.pwc.com" -Subject $sub -body "$body" -Encoding ([System.Text.Encoding]::UTF8)
}


