#$nodes = "de-dacmscpwn551"#,"emadacmscpwn251","emadacmscpwn851","emadacmscpwn551","emadacmscpwn651","emadacmscpwn751","emadacmscpwn951"
$nodes = "de-dacmscpwn551","de-dacmscpwn552","de-dacmscpwn553","de-dacmscpwn554","de-dacmscpwn555","de-dacmscpwn556","emadacmscpwn251","emadacmscpwn252","emadacmscpwn253","emadacmscpwn351","emadacmscpwn352","emadacmscpwn451","emadacmscpwn452","emadacmscpwn551","emadacmscpwn552","emadacmscpwn651","emadacmscpwn652","emadacmscpwn751","emadacmscpwn752","emadacmscpwn851","emadacmscpwn852","emadacmscpwn853","emadacmscpwn951","emadacmscpwn952"
#stage $nodes = "emadacmscswn151","emadacmscswn152","emadacmscswn251","emadacmscswn252"
#$nodes = "emadacmscswn151"

foreach ($n in $nodes) {
    $n
    Invoke-Command -ComputerName $n -ScriptBlock { Remove-Item "c:\CoreDB\SQLServer2014\Updates\CU*" -ErrorAction SilentlyContinue -Force -Recurse}
    Copy-Item "\\de-dacmgt980wp\sdl$\Microsoft\Microsoft SQL Server 2014\Microsoft SQL Server 2014 SP1\Updates\CU6" "\\$n\c$\CoreDB\SQLServer2014\Updates\CU6\" -Container -Recurse -Force
    Copy-Item "\\de-dacmgt980wp\services$\MS SQL (CS-022)\Skripte\Powershell\Cluster\Cluster_Patchen\Patchskripte\02_PatchSQL.ps1" "\\$n\c$\CoreDB\" -Force

    #Invoke-Command -ComputerName $n -ScriptBlock { &C:\CoreDB\01_Failback_off.ps1 }
    #Invoke-Command -ComputerName $n -ScriptBlock { &C:\CoreDB\03_Move_all_to_prefered_owner.ps1 }
    #Invoke-Command -ComputerName $n -ScriptBlock { &C:\CoreDB\04_Failback_on.ps1 }
}




