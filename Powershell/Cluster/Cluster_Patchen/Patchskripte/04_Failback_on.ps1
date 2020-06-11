Import-Module FailoverClusters
Foreach ($cg in $(Get-ClusterGroup | where {$_.name -like "SQL Server*"})) {
$cg 
if ($cg.AutoFailbackType -eq 0) { $cg.AutoFailbackType = 1 }
}
