<#
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$scriptPath
$scriptLogPath = "$scriptPath\Logs"
$scriptLogPath
$zeit = (Get-Date -DisplayHint Time)
$zeit

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
    $scriptLogPath = "$scriptPath\Logs"
    $Datum=(get-date -DisplayHint Date -Format yyyy_MM_dd)
    $scriptLogfile = "$scriptLogPath\$Datum-Copy_QPilot_log.txt"
    $scriptLogfile
    #>

#Copy-Item -Path "\\de-dacmgt980wp\services$\MS SQL (CS-022)\Skripte\Powershell\Copy_Qpilot_DBs.ps1" -Destination "D:\SystemDBs\Skripte\Copy_Qpilot_DBs.ps1" -force

#$fullPath = "C:\CoreDB\SQL-Doku.txt"

#Get-ItemProperty -Path "C:\CoreDB\*" 


#Test-Path $fullPath -newerThan (Get-Date).AddDays(-1)



#$nodes = "de-dacmscpwn551"#,"emadacmscpwn251","emadacmscpwn851","emadacmscpwn551","emadacmscpwn651","emadacmscpwn751","emadacmscpwn951"
#$nodes = "de-dacmscpwn551","de-dacmscpwn552","de-dacmscpwn553","de-dacmscpwn554","de-dacmscpwn555","de-dacmscpwn556","emadacmscpwn251","emadacmscpwn252","emadacmscpwn253","emadacmscpwn351","emadacmscpwn352","emadacmscpwn451","emadacmscpwn452","emadacmscpwn551","emadacmscpwn552","emadacmscpwn651","emadacmscpwn652","emadacmscpwn751","emadacmscpwn752","emadacmscpwn851","emadacmscpwn852","emadacmscpwn853","emadacmscpwn951","emadacmscpwn952"
#stage $nodes = "emadacmscswn151","emadacmscswn152","emadacmscswn251","emadacmscswn252"

$nodes = "emadacmscswn152"#,"emadacmscswn252"

foreach ($n in $nodes) {
    $n
    Invoke-Command -ComputerName $n -ScriptBlock { Remove-Item "c:\CoreDB\SQLServer2014\Updates\CU*" -ErrorAction SilentlyContinue -Force -Recurse}
    Copy-Item "\\de-dacmgt980wp\sdl$\Microsoft\Microsoft SQL Server 2014\Microsoft SQL Server 2014 SP1\Updates\CU6" "\\$n\c$\CoreDB\SQLServer2014\Updates\CU6\" -Container -Recurse -Force
    Copy-Item "\\de-dacmgt980wp\services$\MS SQL (CS-022)\Skripte\Powershell\Cluster\Cluster_Patchen\Patchskripte\02_PatchSQL.ps1" "\\$n\c$\CoreDB\" -Force
    
    #Invoke-Command -ComputerName $n -ScriptBlock { 
    #$Null = &C:\CoreDB\01_Failback_off.ps1 
    #(Get-ClusterGroup | where {$_.OwnerNode -eq $env:computername}).name
    #(Get-ClusterGroup | where {$_.OwnerNode -eq $env:computername} | Move-ClusterGroup)
    #}
    #Invoke-Command -ComputerName $n -ScriptBlock { &C:\CoreDB\03_Move_all_to_prefered_owner.ps1 }
    #Invoke-Command -ComputerName $n -ScriptBlock { &C:\CoreDB\04_Failback_on.ps1 }
}




