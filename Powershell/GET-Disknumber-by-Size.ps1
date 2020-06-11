    #################################################################################################################
    #          Start     SET DISKNO BY SIZE
    #################################################################################################################

    cls

    function config-disk {
    param(
        $DISK_ID,
        $DRIVE_LETTER,
        $DISK_NAME
    )

        $_out= $(Initialize-Disk -Number $DISK_ID -PartitionStyle GPT -PassThru -ErrorAction SilentlyContinue )
        $_out = $(set-disk -number $DISK_ID -IsOffline 0)
        $_out = $(set-disk -number $DISK_ID -IsReadOnly 0)
        $_out= $(New-Partition -DiskNumber $DISK_ID -UseMaximumSize -DriveLetter $DRIVE_LETTER )
        $_out= $(Format-Volume -DriveLetter $DRIVE_LETTER -NewFileSystemLabel $DISK_NAME -FileSystem NTFS -AllocationUnitSize 65536 –Force -Confirm:$false)
    }

    function get-disksize {
    param(
            $DISK_NAME,
            $Disksize,
            $DISK_LETTER#,
#                $USER_SA_SQL
            )
        $_DiskMin = $($($Disksize*1024*1024*1024)-1000)
        $_DiskMax = $($($Disksize*1024*1024*1024)+1000)

        $Disks=$(get-disk  | where {$_.NumberOfPartitions -lt 1 -and $_.Size -gt $_DiskMin -and $_.Size -lt $_DiskMax} | sort {$_.number} ).Number[0]
            
        ## ARGUMENTS ##
	    $DISK_ID = $Disks
	        
        if ( $DISK_LETTER -match "^\w:$") { $DISK_MOUNTP = "letter="+$DISK_LETTER } else { $DISK_MOUNTP = "mount="+$DISK_LETTER }

	    ## INITIALIZE DISK ##
        if ( $DISK_MOUNTP -match "letter" ) 
        {
            $DRIVE_LETTER = $DISK_LETTER.TrimEnd(":")
            $_out= $(Initialize-Disk -Number $DISK_ID -PartitionStyle GPT -PassThru -ErrorAction SilentlyContinue )
            $_out = $(set-disk -number $DISK_ID -IsOffline 0)
            $_out = $(set-disk -number $DISK_ID -IsReadOnly 0)
            $_out= $(New-Partition -DiskNumber $DISK_ID -UseMaximumSize -DriveLetter $DRIVE_LETTER )
            $_out= $(Format-Volume -DriveLetter $DRIVE_LETTER -NewFileSystemLabel $DISK_NAME -FileSystem NTFS -AllocationUnitSize 65536 –Force -Confirm:$false)
            $Arg_ACL_AU = ($DISK_LETTER + " /remove ""Authenticated Users""")
		    $Arg_ACL_CO = ($DISK_LETTER + " /remove ""Creator Owner""")
		    $Arg_ACL_User = ($DISK_LETTER + " /remove Users")
		    $Arg_ACL_EO = ($DISK_LETTER + " /remove Everyone")
		    #$Arg_ACL_SA_SQL = ($DISK_LETTER + " /grant ""$USER_SA_SQL"":(OI)(CI)F")
        } 
        else 
        {
            #Write-host "mount= $DISK_LETTER"
            $_out= $(Initialize-Disk -Number $DISK_ID -PartitionStyle GPT -PassThru -ErrorAction SilentlyContinue )
            $_out= $(set-disk -number $DISK_ID -IsOffline 0)
            $_out= $(set-disk -number $DISK_ID -IsReadOnly 0)
            $_out= $(New-Partition -DiskNumber $DISK_ID -UseMaximumSize -DriveLetter B )
            $_out= $(Format-Volume -DriveLetter B -NewFileSystemLabel $DISK_NAME -FileSystem NTFS -AllocationUnitSize 65536 –Force -Confirm:$false )
            $Arg_ACL_AU = ("B:" + " /remove ""Authenticated Users""")
		    $Arg_ACL_CO = ("B:" + " /remove ""Creator Owner""")
		    $Arg_ACL_User = ("B:" + " /remove Users")
		    $Arg_ACL_EO = ("B:" + " /remove Everyone")
		    $Arg_ACL_SA_SQL = ("B:" + " /grant ""$USER_SA_SQL"":(OI)(CI)F")
    	} # End Init disks
	
	    ## DISK RIGHTS ##
	    Write-Host "SET RIGHTS"
	        
	    $_out= $(Start-Process "C:\Windows\System32\icacls.exe" -ArgumentList $Arg_ACL_AU -NoNewWindow -Wait )
	    $_out= $(Start-Process "C:\Windows\System32\icacls.exe" -ArgumentList $Arg_ACL_CO -NoNewWindow -Wait )
	    $_out= $(Start-Process "C:\Windows\System32\icacls.exe" -ArgumentList $Arg_ACL_User -NoNewWindow -Wait)
	    $_out= $(Start-Process "C:\Windows\System32\icacls.exe" -ArgumentList $Arg_ACL_EO -NoNewWindow -Wait )
	    #$_out= $(Start-Process "C:\Windows\System32\icacls.exe" -ArgumentList $Arg_ACL_SA_SQL -NoNewWindow -Wait) 
	    if (!$?) { Write-Host ("  Error Rights") }
	    else { Write-Host ("  Success Rights") }

	    ## REASSIGN DRIVE LETTER ##
	    ## INITIALIZE DISK ##
	    if ( -not ($DISK_MOUNTP -match "letter" )) 
        {
		    Write-Host "Create Mountpoints on primary disk"
			# MP
		    Write-Host ("  Create Dir: $DISK_LETTER ID: $DISK_ID")
		    $Out=New-Item ($DISK_LETTER) -type directory
	        $Out=Add-PartitionAccessPath -DiskNumber $DISK_ID -PartitionNumber 2 -AccessPath $DISK_LETTER -Passthru | set-Partition -NoDefaultDriveLetter:$True
        
$DISKPART_COMMAND = @"
select volume b:
remove letter=b:
exit
"@
	        ## RUN DISKPART to remove driveletter B
	        $DISKPART_COMMAND | C:\Windows\System32\diskpart.exe 
        }
    } # ende for each config disk
    if ($_isClusterservice)
    {
        ## CLUSTER ADD Disks
        foreach ($line in $input) {

	        $SPLIT = $line -split ";"

	        ## ARGUMENTS ##
	        $DISK_ID = $SPLIT[0] #$args[0]
	        $DISK_NAME = $SPLIT[1] #$args[1]
	        $DISK_LETTER = $SPLIT[2] #$args[2]
	        if ( $DISK_LETTER -match "^\w:$") { $DISK_MOUNTP = "letter="+$DISK_LETTER } else { $DISK_MOUNTP = "mount="+$DISK_LETTER }

            $_out= $(Add-ClusterResource -Name $DISK_NAME -ResourceType "Physical Disk" -Group "Available Storage")
	        $_out= $(Get-ClusterResource $DISK_NAME | Set-ClusterParameter DiskPath $DISK_LETTER)
	        $_out= $((Get-ClusterResource $DISK_NAME).RestartThreshold=5)
	        $_out= $((Get-ClusterResource $DISK_NAME).RestartDelay=500)
	        $_out= $((Get-ClusterResource $DISK_NAME).RestartPeriod=300000)
	        Start-ClusterResource $DISK_NAME
        }
    }
        

#################################################################################################################
#          Start     SET DISKNO BY SIZE
#################################################################################################################

$Letter = "G"
$instance = "de_tst_345"
$Drives = ("Rootdisk","SystemDBs","UserDBs","Userlogs","TempDB")
$size = 1,4,5,4,5
$s=0

Foreach ($Drive in $Drives) {
    $MountSize = $size[$s]
    $s=($S+1)
    if ($Drive -match "Rootdisk" ) {$DriveLetter = "$Letter"+":"} else {$DriveLetter = "$Letter"+":\"+"$Drive"}
        $DISK_NAME = "$instance"+"_"+"$Drive"
        
    $_dn = $(get-disksize -DISK_NAME $DISK_NAME -Disksize $MountSize -DISK_LETTER $DriveLetter )
}

