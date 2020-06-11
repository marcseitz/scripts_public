Import-Module FailoverClusters

$clustergroups = Get-ClusterGroup | Where-Object {$_.IsCoreGroup -eq $false}
foreach ($cg in $clustergroups)
{
    $CGName = $cg.Name
    Write-Host "`nWorking on $CGName"
    $CurrentOwner = $cg.OwnerNode.Name
    Write-host "current = $CurrentOwner"
    $PreferredOwner = ($cg | Get-ClusterOwnerNode).Ownernodes[0].Name
    Write-host "prefered = $PreferredOwner"
}