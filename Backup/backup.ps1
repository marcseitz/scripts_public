## Full + Log Backup of MS SQL Server databases/span>            
## with SMO.  

param($backup, $Server)
          
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.ConnectionInfo');            
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Management.Sdk.Sfc');            
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO');            
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMOExtended');   

# Handle any errors that occur
Function Error_Handler {
  Write-Host "Error Category: " + $error[0].CategoryInfo.Category 
  Write-Host " Error Object: " + $error[0].TargetObject 
  Write-Host " Error Message: " + $error[0].Exception.Message 
  Write-Host " Error Message: " + $error[0].FullyQualifiedErrorId 
  }
Trap {
  # Handle the error
  Error_Handler;
  # End the script.
  break
  }

$Dest = "";    # Backup path on server (optional).            
$srv = New-Object Microsoft.SqlServer.Management.Smo.Server $Server;      

if ($backup -eq "FULL")
{      
# If missing set default backup directory.            
If ($Dest -eq "")            
{ $Dest = $server.Settings.BackupDirectory +"\FULL\"+ $db.Name +"\" };
         
Write-Output ("Started at: " + (Get-Date -format yyyy-MM-dd-HH:mm:ss));            
# Full-backup for every database            
foreach ($db in $srv.Databases)            
{            
    If($db.Name -ne "tempdb")  # Non need to backup TempDB            
    {            
        $timestamp = Get-Date -format yyyy-MM-dd-HH-mm-ss;            
        $backup = New-Object ("Microsoft.SqlServer.Management.Smo.Backup");            
        $backup.Action = "Database";            
        $backup.Database = $db.Name;            
        $backup.Devices.AddDevice($Dest + $db.Name + "_full_" + $timestamp + ".sbk", "File");            
        $backup.BackupSetDescription = "Full backup of " + $db.Name + " " + $timestamp;            
        $backup.Incremental = 0;            
        # Starting full backup process.            
        $backup.SqlBackup($srv);     
        # For db with recovery mode <> simple: Log backup.            
        If ($db.RecoveryModel -ne 3)            
        {            
            $timestamp = Get-Date -format yyyy-MM-dd-HH-mm-ss;            
            $backup = New-Object ("Microsoft.SqlServer.Management.Smo.Backup");            
            $backup.Action = "Log";            
            $backup.Database = $db.Name;            
            $backup.Devices.AddDevice($Dest + $db.Name + "_log_" + $timestamp + ".trn", "File");            
            $backup.BackupSetDescription = "Log backup of " + $db.Name + " " + $timestamp;            
            #Specify that the log must be truncated after the backup is complete.            
            $backup.LogTruncation = "Truncate";
            # Starting log backup process            
            $backup.SqlBackup($srv);            
        };  

          
    };            
};            
Write-Output ("Finished at: " + (Get-Date -format  yyyy-MM-dd-HH:mm:ss));
};

if ($backup -eq "DIFF")
{      
# If missing set default backup directory.            
If ($Dest -eq "")            
{ $Dest = $server.Settings.BackupDirectory +"\DIFF\"+ $db.Name +"\" };  



Write-Output ("Started at: " + (Get-Date -format yyyy-MM-dd-HH:mm:ss));            
# Diff-backup for every database            
foreach ($db in $srv.Databases)            
{            
    If($db.Name -ne "tempdb" -and $db.Name -ne "master")  # Non need to backup TempDB            
    {            
        $timestamp = Get-Date -format yyyy-MM-dd-HH-mm-ss;            
        $backup = New-Object ("Microsoft.SqlServer.Management.Smo.Backup");            
        $backup.Action = "Database";            
        $backup.Database = $db.Name;            
        $backup.Devices.AddDevice($Dest + $db.Name + "_diff_" + $timestamp + ".sbk", "File");            
        $backup.BackupSetDescription = "Differential backup of " + $db.Name + " " + $timestamp;            
        $backup.Incremental = 1;            
        # Starting differential backup process.            
        $backup.SqlBackup($srv);     
        # For db with recovery mode <> simple: Log backup.            
        If ($db.RecoveryModel -ne 3)            
        {            
            $timestamp = Get-Date -format yyyy-MM-dd-HH-mm-ss;            
            $backup = New-Object ("Microsoft.SqlServer.Management.Smo.Backup");            
            $backup.Action = "Log";            
            $backup.Database = $db.Name;            
            $backup.Devices.AddDevice($Dest + $db.Name + "_log_" + $timestamp + ".trn", "File");            
            $backup.BackupSetDescription = "Log backup of " + $db.Name + " " + $timestamp;            
            #Specify that the log must be truncated after the backup is complete.            
            $backup.LogTruncation = "Truncate";
            # Starting log backup process            
            $backup.SqlBackup($srv);            
        };    

} 


 If($db.Name -eq "master")  # FULL Backup of Master DB          
    {            
        $timestamp = Get-Date -format yyyy-MM-dd-HH-mm-ss;            
        $backup = New-Object ("Microsoft.SqlServer.Management.Smo.Backup");            
        $backup.Action = "Database";            
        $backup.Database = $db.Name;            
        $backup.Devices.AddDevice($Dest + $db.Name + "_full_" + $timestamp + ".sbk", "File");            
        $backup.BackupSetDescription = "Differential backup of " + $db.Name + " " + $timestamp;            
        $backup.Incremental = 0;            
        # Starting differential backup process.            
        $backup.SqlBackup($srv);     
        # For db with recovery mode <> simple: Log backup.            
        If ($db.RecoveryModel -ne 3)            
        {            
            $timestamp = Get-Date -format yyyy-MM-dd-HH-mm-ss;            
            $backup = New-Object ("Microsoft.SqlServer.Management.Smo.Backup");            
            $backup.Action = "Log";            
            $backup.Database = $db.Name;            
            $backup.Devices.AddDevice($Dest + $db.Name + "_log_" + $timestamp + ".trn", "File");            
            $backup.BackupSetDescription = "Log backup of " + $db.Name + " " + $timestamp;            
            #Specify that the log must be truncated after the backup is complete.            
            $backup.LogTruncation = "Truncate";
            # Starting log backup process            
            $backup.SqlBackup($srv);            
        };  

      
    };            
};            
Write-Output ("Finished at: " + (Get-Date -format  yyyy-MM-dd-HH:mm:ss));
};







