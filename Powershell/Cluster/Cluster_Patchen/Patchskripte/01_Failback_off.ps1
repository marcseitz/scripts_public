Import-Module FailoverClusters
Foreach ($cg in $(Get-ClusterGroup | where {$_.name -like "SQL Server*"})) {
$cg 
if ($cg.AutoFailbackType -eq 1) { $cg.AutoFailbackType = 0 }
}
