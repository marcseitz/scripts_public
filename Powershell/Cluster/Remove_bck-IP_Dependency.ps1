#cls
#$clu = ""

function remove-bck_dep {
    param(
    $clu = ""
    )

    if ( $clu -eq "")
    {
        do 
        {
            if (!($clu = (Read-Host "Insert clustername.").ToUpper())) 
            {
                Write-host "No clustername."
            }
        } until ($clu)
    }

    #############################
    # remove bck ip from dns name
    foreach ($_depres in (Get-ClusterResource -Cluster $clu | where {$_.name -match "SQL Network Name "})) {
    write-host "check bck ip for group $_depres"
        $_dns = $_depres.OwnerGroup.Name.Split("\")[0]
        $_depres = $_depres.name
        if (($(Get-ClusterResourceDependency -Cluster $clu -Resource $_depres).DependencyExpression) -match ("-bck01")) 
        { 
            write-host "remove bck ip from dns name from group $_depres"
            Remove-ClusterResourceDependency -Cluster $clu -Resource $_depres "$_dns-bck01"
        }
    }
#    Read-Host "press enter to move to prefered owner" | Out-Null


    &"\\de-dacmgt980wp\services$\MS SQL (CS-022)\Installation and Configuration Scripts\Skripte\Powershell\Cluster\Move_all_to_prefered_owner.ps1" $clu
}

remove-bck_dep -clu $args[0]
