cls
#$node = "DE-DACMSCPWN901"
$node = "EMADACMSCPWN251"

# Status: Clustercheck läuft, Backup ende Check läuft
# nächster: 

function check-AuraBackups {
param(
        $instanz
)
    Invoke-Command -ComputerName $node -ScriptBlock {
    $_wait_for = 5  #wait in seconds for loop
#    $timeout = new-timespan -Minutes 1 #timeout for loop
    $timeout = new-timespan -Seconds 15 #timeout for loop
    $sw = [diagnostics.stopwatch]::StartNew()

    $instanz = $Args[0]
    $_komplete_path = (Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL12.$instanz\MSSQLServer" | select "BackupDirectory").BackupDirectory
    $_bck_p_sp = $_komplete_path.Split("\")[0]

    $_ok_file_path_diff = "$_bck_p_sp\Backup\Backupteam\Diff\SQLDumpBackup"
    $_ok_file_path_full = "$_bck_p_sp\Backup\Backupteam\Full\SQLDumpBackup"
    $_ok_file_path = "$_bck_p_sp\Backup\Backupteam\SQLDumpBackup"
    $_timeout_exit=""

    write-host "run on $instanz"
    do
    {
        if (test-path $_ok_file_path_diff) 
        {
            $_ok_file = "$_ok_file_path_diff\SQLDumpOK.dat"
            if (!(test-path -Path $_ok_file))
            {
                $_ok_file = "$_ok_file_path_full\SQLDumpOK.dat"
                $_OK_exist = (test-path -Path $_ok_file -NewerThan (Get-Date).AddHours(-3))
            }
            else
            {
                $_OK_exist = (test-path -Path $_ok_file -NewerThan (Get-Date).AddHours(-3))
            }
        }
        else
        {
            $_ok_file = "$_ok_file_path\SQLDumpOK.dat"
            $_OK_exist = (test-path -Path $_ok_file -NewerThan (Get-Date).AddHours(-3))
        }
     #   $sw.elapsed.Seconds
    
        if ($sw.elapsed -gt $timeout)
        {
            $_timeout_exit="1"
        }
    
        Start-Sleep -Seconds $_wait_for

    } until ($_ok_exist -or $_timeout_exit)


    if ($_OK_exist) 
    {
        Write-Host "SQL Backup ist fertig"
    }
    else
    {
        write-host "Timed out"
    }
  } -ArgumentList  $instanz  
} 

function check-clusternode {
param (
        $ClusterNode
)
    $_all_groups_on_node = (Invoke-Command -ComputerName $ClusterNode -ScriptBlock {
                            $_cur_node = $Args[0]
                            $_all_groups_on_node = (Get-ClusterGroup | where { $_.name -like "*_AUR_*" } | where {$_.OwnerNode -eq $_cur_node} ).name
                            $_all_groups_on_node
                            } -ArgumentList $ClusterNode
                           )
    $_all_groups_on_node
}

$_all_groups_remote = (check-clusternode -ClusterNode $node)

do
{
    if($_all_groups_remote)
    {
        foreach ($_rem_group in $_all_groups_remote ) {
            $_rem_inst = (($_rem_group.split("("))[1]).split(")")[0]
            check-AuraBackups -instanz $_rem_inst
        }
    }
    else
    {
        $_empty_node = 1
    }
} until ($_empty_node)






