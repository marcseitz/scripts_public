# Take disk Online, Format for SQL an Inster to Cluster
# Start .\Disk2Cluster_SQL.ps1 .\Disk_SQL.txt

$input = Get-Content ( $args[0] ) 
foreach ($line in $input) {

	$SPLIT = $line -split ";"


	## ARGUMENTS ##
	$DISK_ID = $SPLIT[0] #$args[0]
	$DISK_NAME = $SPLIT[1] #$args[1]
	$DISK_LETTER = $SPLIT[2] #$args[2]
    $USER_SA_SQL = $SPLIT[3] #$args[3]
	if ( $DISK_LETTER -match "^\w:$") { $DISK_MOUNTP = "letter="+$DISK_LETTER } else { $DISK_MOUNTP = "mount="+$DISK_LETTER }

	## INITIALIZE DISK ##
	if ( $DISK_MOUNTP -match "letter" ) {
$DISKPART_COMMAND = @"
select disk $DISK_ID
attributes disk clear readonly
online disk
create partition primary
format fs=ntfs unit=64k label='$DISK_NAME' quick
assign $DISK_MOUNTP
exit
"@
	} else {
$DISKPART_COMMAND = @"
select disk $DISK_ID
attributes disk clear readonly
online disk
create partition primary
format fs=ntfs unit=64k label='$DISK_NAME' quick
assign letter=b:
exit
"@
	}
	
	## RUN DISKPART
	$DISKPART_COMMAND | C:\Windows\System32\diskpart.exe 

	## DISK RIGHTS ##
	Write-Host "SET RIGHTS"
	if ( $DISK_MOUNTP -match "letter" ) {
		$Arg_ACL_AU = ($DISK_LETTER + " /remove ""Authenticated Users""")
		$Arg_ACL_CO = ($DISK_LETTER + " /remove ""Creator Owner""")
		$Arg_ACL_User = ($DISK_LETTER + " /remove Users")
		$Arg_ACL_EO = ($DISK_LETTER + " /remove Everyone")
		$Arg_ACL_SA_SQL = ($DISK_LETTER + " /grant ""$USER_SA_SQL"":(OI)(CI)F")
	} else {
		$Arg_ACL_AU = ("B:" + " /remove ""Authenticated Users""")
		$Arg_ACL_CO = ("B:" + " /remove ""Creator Owner""")
		$Arg_ACL_User = ("B:" + " /remove Users")
		$Arg_ACL_EO = ("B:" + " /remove Everyone")
 		$Arg_ACL_SA_SQL = ("B:" + " /grant ""$USER_SA_SQL"":(OI)(CI)F")
	}
	Start-Process "C:\Windows\System32\icacls.exe" -ArgumentList $Arg_ACL_AU -NoNewWindow -Wait 
	Start-Process "C:\Windows\System32\icacls.exe" -ArgumentList $Arg_ACL_CO -NoNewWindow -Wait 
	Start-Process "C:\Windows\System32\icacls.exe" -ArgumentList $Arg_ACL_User -NoNewWindow -Wait
	Start-Process "C:\Windows\System32\icacls.exe" -ArgumentList $Arg_ACL_EO -NoNewWindow -Wait 
	Start-Process "C:\Windows\System32\icacls.exe" -ArgumentList $Arg_ACL_SA_SQL -NoNewWindow -Wait 
	if (!$?) { Write-Host ("  Error Rights") }
	else { Write-Host ("  Success Rights") }

	## REASSIGN DRIVE LETTER ##
	## INITIALIZE DISK ##
	if ( -not ($DISK_MOUNTP -match "letter" )) {
		Write-Host "Create Mountpoints on primary disk"
			
		# MP
		Write-Host ("  Create Dir: "+$DISK_LETTER)
		New-Item ($DISK_LETTER) -type directory
	
$DISKPART_COMMAND = @"
select volume b:
assign $DISK_MOUNTP
remove letter=b:
exit
"@

	## RUN DISKPART
	$DISKPART_COMMAND | C:\Windows\System32\diskpart.exe 

	}
}