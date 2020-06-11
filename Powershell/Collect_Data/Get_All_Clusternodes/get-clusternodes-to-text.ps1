cls 
$_Serverlist="$PSScriptRoot\servers.txt"

foreach ($_node in (get-content "$_Serverlist")) {
    $_node = $_node.Split("\")[0]
    $cluster = $(Resolve-DnsName $_node).name
    $_nodes = $(try { $(gwmi -class "MSCluster_Node" -namespace "root\mscluster" -computername $cluster -Authentication PacketPrivacy -ErrorAction SilentlyContinue | add-member -pass NoteProperty Cluster $cluster -ErrorAction SilentlyContinue).name }
                Catch{})
    if ( $_nodes ) { $_nodes |  Out-File $PSScriptRoot\Clusternodes.txt -Encoding default -Append 
        $_node |  Out-File $PSScriptRoot\Clusternames.txt -Encoding default -Append
        #"----------------" |  Out-File $PSScriptRoot\Clusternodes_2.txt -Encoding default -Append
        }
    else { $_node |  Out-File $PSScriptRoot\NonClusternodes_2.txt -Encoding default -Append }
}
