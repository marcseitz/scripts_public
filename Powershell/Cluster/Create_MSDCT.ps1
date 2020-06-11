
$_Create_MSDTC = 0
if (!(Get-ClusterResource | select name | where {$_.name -eq "MSDTC"}).name)
{
    	write-host "MSDTC konfigurieren"
	    $_Create_MSDTC = 1
		$_msdtc_disk = read-host "MSDTC Disknummer"
		$_mstdc_name = read-host "MSDTC DNS Name"
		$_mstdc_ip = read-host "MSDTC IP"
}
else
{
	$_Create_MSDTC = 0
}

if ($_Create_MSDTC -eq 1) 
{
    #create MSDTC Disk
    Initialize-Disk -Number $_msdtc_disk -PartitionStyle GPT -PassThru -ErrorAction SilentlyContinue 
    set-disk -number $_msdtc_disk -IsOffline 0
    set-disk -number $_msdtc_disk -IsReadOnly 0
    $_out = New-Partition -DiskNumber $_msdtc_disk -DriveLetter "M" -UseMaximumSize
    $_out = $(Format-Volume -DriveLetter M -FileSystem NTFS -NewFileSystemLabel "MSDTC" -Force -Confirm:$false)


    $_remove_user = "Authenticated Users;Creator Owner;Users;Everyone"
    foreach ($user in ($_remove_user.Split(";"))) {
    $colRights = [System.Security.AccessControl.FileSystemRights]"Read" 
    $InheritanceFlag = [System.Security.AccessControl.InheritanceFlags]::None 
    $PropagationFlag = [System.Security.AccessControl.PropagationFlags]::None 
    $objType =[System.Security.AccessControl.AccessControlType]::Allow 
    $objUser = New-Object System.Security.Principal.NTAccount("$user") 
    $objACE = New-Object System.Security.AccessControl.FileSystemAccessRule `
        ($objUser, $colRights, $InheritanceFlag, $PropagationFlag, $objType) 
    $objACL = Get-ACL "M:" 
    $objACL.RemoveAccessRuleAll($objACE) 
    Set-ACL "M:" $objACL
    }

    # Add to Cluster
    Add-ClusterResource -Name MSDTC -ResourceType "Physical Disk" -Group "Available Storage"
    Get-ClusterResource MSDTC | Set-ClusterParameter DiskPath M
    (Get-ClusterResource MSDTC).RestartThreshold=5
    (Get-ClusterResource MSDTC).RestartDelay=500
    (Get-ClusterResource MSDTC).RestartPeriod=300000
    Start-ClusterResource MSDTC

    # Create a new HA Server Role - Distributed Transaction Coordinator
    Add-ClusterServerRole -Name $_mstdc_name -Storage "MSDTC" -StaticAddress $_mstdc_ip
    # Add the MSDTC Service to the new Server Role
    Get-ClusterGroup $_mstdc_name | Add-ClusterResource -Name MSDTC-$_mstdc_name -ResourceType "Distributed Transaction Coordinator"
    # Create Dependencies for the DTC group
    Add-ClusterResourceDependency MSDTC-$_mstdc_name $_mstdc_name
    Add-ClusterResourceDependency MSDTC-$_mstdc_name "MSDTC"
    # Start DTC group
    Start-ClusterGroup $_mstdc_name

    Write-Host "Enabling MSDTC for Network Access…" -foregroundcolor yellow
    $System_OS=(Get-WmiObject -class Win32_OperatingSystem).Caption
    If ($System_OS -match "2012 R2")
        {
        Set-DtcNetworkSetting -DtcName $_mstdc_name -AuthenticationLevel Incoming -InboundTransactionsEnabled 1 -OutboundTransactionsEnabled 1 -RemoteClientAccessEnabled 1 -confirm:$false
        }
    Else
        {
        $DTCSecurity = "Incoming"
        $RegPath = "HKLM:\SOFTWARE\Microsoft\MSDTC\"

        #Set Security and MSDTC path
            $RegSecurityPath = "$RegPath\Security"
            Set-ItemProperty -path $RegSecurityPath -name "NetworkDtcAccess" -value 1
            Set-ItemProperty -path $RegSecurityPath -name "NetworkDtcAccessClients" -value 1
            Set-ItemProperty -path $RegSecurityPath -name "NetworkDtcAccessTransactions" -value 1
            Set-ItemProperty -path $RegSecurityPath -name "NetworkDtcAccessInbound" -value 1
            Set-ItemProperty -path $RegSecurityPath -name "NetworkDtcAccessOutbound" -value 1
            Set-ItemProperty -path $RegSecurityPath -name "LuTransactions" -value 1             

            if ($DTCSecurity -eq "None")
            {
                Set-ItemProperty -path $RegPath -name "TurnOffRpcSecurity" -value 1
                Set-ItemProperty -path $RegPath -name "AllowOnlySecureRpcCalls" -value 0
                Set-ItemProperty -path $RegPath -name "FallbackToUnsecureRPCIfNecessary" -value 0
            }
            elseif ($DTCSecurity -eq "Incoming")
            {
                Set-ItemProperty -path $RegPath -name "TurnOffRpcSecurity" -value 0
                Set-ItemProperty -path $RegPath -name "AllowOnlySecureRpcCalls" -value 0
                Set-ItemProperty -path $RegPath -name "FallbackToUnsecureRPCIfNecessary" -value 1
            }
            else
            {
                Set-ItemProperty -path $RegPath -name "TurnOffRpcSecurity" -value 0
                Set-ItemProperty -path $RegPath -name "AllowOnlySecureRpcCalls" -value 1
                Set-ItemProperty -path $RegPath -name "FallbackToUnsecureRPCIfNecessary" -value 0
            }
        }
        Restart-Service MSDTC
        Write-Host "——MSDTC has been configured—–" -foregroundcolor green
} #end Create MSTDC
