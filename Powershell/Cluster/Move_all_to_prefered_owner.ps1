
function move-all {
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

 
    $clustergroups = Get-ClusterGroup -Cluster $clu | Where-Object {$_.IsCoreGroup -eq $false}
    foreach ($cg in $clustergroups)
    {
        $CGName = $cg.Name
        Write-Host "`nWorking on $CGName"
        $CurrentOwner = $cg.OwnerNode.Name
        $POCount = (($cg | Get-ClusterOwnerNode -Cluster $clu).OwnerNodes).Count
        if ($POCount -eq 0)
        {
            Write-Host "Info: $CGName doesn't have a preferred owner!" -ForegroundColor Magenta
        }
        else
        {
            $PreferredOwner = ($cg | Get-ClusterOwnerNode -Cluster $clu).Ownernodes[0].Name
            if ($CurrentOwner -ne $PreferredOwner)
            {
                Write-Host "Moving resource to $PreferredOwner, please wait..."
                $cg | Move-ClusterGroup -Cluster $clu -Node $PreferredOwner
            }
            else
            {
                write-host "Resource is already on preferred owner! ($PreferredOwner)"
            }
        }
    }
    Write-Host "`n`nFinished. Current distribution: "
    Get-ClusterGroup -Cluster $clu | Where-Object {$_.IsCoreGroup -eq $false}
}

move-all -clu $args[0]
