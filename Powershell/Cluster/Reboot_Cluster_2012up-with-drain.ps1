cls
$_nodename = ""
$clu = ""
$_quest = ""

do 
{
    if (!($clu = (Read-Host "Insert clustername for reboot.").ToUpper())) 
    {
        Write-host "No clustername is instert for reboot."
    }
} until ($clu)

if (!($_quest = (Read-host "Do you want to reboot all Nodes on cluster $clu ? [N]"))) 
{
    $_quest = "n"
}

if ( $_quest -eq "n" )
{
    exit
}

foreach ( $_nodename in (Get-ClusterNode -Cluster $clu).name ) {
$_rebooted = ""
$_server_down = ""
    
    Write-host "Pause Node $_nodename "
    Suspend-ClusterNode -Drain -ForceDrain -Name $_nodename -Cluster $clu -Wait
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
}
Write-Host "Alle Nodes im Cluster $clu rebootet" -ForegroundColor Green