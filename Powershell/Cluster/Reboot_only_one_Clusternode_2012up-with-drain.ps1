cls
$_nodename = ""
$_rebooted = ""
$_server_down = ""

do 
{
    if (!($_nodename = (Read-Host "Insert nodename for reboot.").ToUpper())) 
    {
        Write-host "No nodename is instert for reboot."
    }
} until ($_nodename)


Write-host "Pause Node $_nodename "
Suspend-ClusterNode -Drain -ForceDrain -Name $_nodename -Wait
Write-host "Reboot Node $_nodename "
Restart-Computer -ComputerName $_nodename -Force

do
{
    if ( (Test-Connection -ComputerName $_nodename -Count 1 -Quiet) -eq "True" )
    {
        if ( $_server_down )
        {
            $_rebooted = "1"
        }
        else
        {
            $_rebooted = ""
        }
    }
    else
    {
        $_server_down = "1"
    }
} until ($_rebooted)

Start-Sleep 60
Resume-ClusterNode -Cluster $clu -Name $_nodename -Failback Immediate
start-sleep 60
Write-Host "Alle Nodes im Cluster $clu rebootet" -ForegroundColor Green