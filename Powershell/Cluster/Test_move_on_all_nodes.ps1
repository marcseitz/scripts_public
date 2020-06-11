cls
$clu = ""
$_group = ""

do 
{
    if (!($clu = (Read-Host "Insert clustername.").ToUpper())) 
    {
        Write-host "No clustername."
    }
} until ($clu)

do 
{
    if (!($_group1 = (Read-Host "Insert clustergoup to move. (de-dacsqlswn443) ").ToUpper())) 
    {
        Write-host "No clustergoup to move."
    }
} until ($_group1)

if (!($_group = $($(Get-ClusterGroup -Cluster $clu) | where {$_.name -like "$_group1*" }).name))
{
    Write-Host "No group found with name like $_group1 in cluster $clu" -ForegroundColor Red
    $(Get-ClusterGroup -Cluster $clu).name
    exit
}

foreach ( $_nodename in (Get-ClusterNode -Cluster $clu).name ) {
    Write-host "     Move $_group to Node $_nodename "
    $(Move-ClusterGroup -Cluster $clu -Name $_group -Node $_nodename).state
}

$_firstnode = $(Get-ClusterNode -Cluster $clu).name | select -First 1
Write-host "     Move $_group to first Node - $_firstnode"
$(Move-ClusterGroup -Cluster $clu -Name $_group -Node $_firstnode).state

Write-Host "Finished on Cluster $clu" -ForegroundColor Green

&"\\de-dacmgt980wp\services$\MS SQL (CS-022)\Installation and Configuration Scripts\Skripte\Powershell\Cluster\Remove_bck-IP_Dependency.ps1" $clu
