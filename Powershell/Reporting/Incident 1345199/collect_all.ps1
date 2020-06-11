
cls
[xml]$_server = Get-Content -Path "$PSScriptRoot\server.xml"
$_land = $($_server.All.Land)
$_land1 = $_land.land
$countall = 0
$gesamtall = 0
$_Name = ""
foreach ($_group in $_land) {
    #$_ergeniss_nodes = 0
    $count_land_all =  0
    $land = $_group.Land
    $node_names = $_group._Nodes
    $instanzen = $_group._anzahl_instanzen
    $nodes = $_group._anzahl_nodes
    $incident = $_group._Incident
    $gesamt = $([int]$instanzen * [int]$nodes)
   
    write-host "Land $land Incident: $incident" -ForegroundColor yellow
#    Write-Host "Discover on all nodes: "
    write-host "Anzahl Nodes $nodes - instanzen $instanzen - gesamt: $gesamt" -ForegroundColor yellow
    write-host "-----------------------------------------------" -ForegroundColor White
   
    ForEach ($name in $node_names.Split(";")) {
        $_test= $((Resolve-DnsName $name -ErrorAction SilentlyContinue).name)
        #Write-host "test:$_test" 
        if ($_test)
        { #Write-Host "server erreichbar"
            $_ergeniss_nodes = 0
            $_Name = $(Resolve-DnsName $name -ErrorAction SilentlyContinue).name 
            Write-Host "run on host $name"
           
                $_ergeniss_nodes = $(Invoke-Command -ComputerName $_name -ScriptBlock {
                    try 
                    {
                        $_productroot = 0
                        $_logfolder = ""
                        Start-Process "C:\CoreDB\SQLServer2014\Setup.exe" -ArgumentList " /Action=RunDiscovery /Q" -Wait
                        start-sleep 10
                        $_logfolder = $($((Get-Content -path "C:\Program Files\Microsoft SQL Server\120\Setup Bootstrap\Log\summary.txt" | Select-String -SimpleMatch "Configuration file:")).ToString().Split("\"))[($_.count-2)]
                        [xml]$_discover = Get-Content -Path "C:\Program Files\Microsoft SQL Server\120\Setup Bootstrap\Log\$_logfolder\SqlDiscoveryReport.xml"
                        $_productroot = $($(($_discover.ArrayOfDiscoveryInformation.DiscoveryInformation.Feature) | where {$_ -match "Database Engine Services"} ).Count )
                        $Prod2=[string]$_productroot
                        $Prod2
                    }
                    catch 
                    {
                        Write-Host "Keine SQL Resourcen auf dem Server." -ForegroundColor Red
                        #[String]$_ergeniss_nodes = 
                        "0"            
                    }
                } -ErrorAction ignore)

    #       Write-host "count land all $count_land_all"
        [int]$count_land_Server = $_ergeniss_nodes.split(" ")[0]
        $count_land_all = ($count_land_all + $count_land_Server)
        }
        else
        {
            Write-Host "server $name nicht erreichbar, oder noch nicht installiert. (keine DNS auflösung)" -ForegroundColor Red
        }
    }
#    write-host "- Anzahl Nodes $nodes - instanzen $instanzen - gesamt: $gesamt"
#    write-host "-----------------------------------------------"
    write-host "Installiert $count_land_all von $gesamt " -ForegroundColor Green
    write-host "===============================================" -ForegroundColor White

    $countall = ([int]$count_land_all + [int]$countall)
    $gesamtall = ([int]$gesamtall + [int]$gesamt)
}
write-host " "
write-host "############################################"
write-host "OverAll Installiert $countall von $gesamtall" -ForegroundColor Green


Read-Host "enter to close." | Out-Null