<#
.SYNOPSIS
   Loop through all SQLdm alerts and output to console
.DESCRIPTION
   Loop through all SQLdm alerts and output to console
#>

#Set the location to the SQLdm Instances directory
#Set-Location is equivalent to the CD shell command
Set-Location SQLDM:\Instances

#Save this location for future reference
Push-Location

#Get a list of all instances
$instances = Get-ChildItem

#Step through every instance
foreach ($i in $instances)
{
	#Move to that instance location in the structure
	Set-Location $i.PSChildName
	
	#Move to the alerts for that server
	Set-Location "Alerts"
	
	#Print the server name and the number of alerts
	$alerts = Get-ChildItem 
	"$($i.InstanceName) Alerts: $($alerts.Count)" 
	
	#For each alert, print the metric, severity, and message
	foreach ($a in $alerts)
	{
		"`t $($a.Metric) $($a.Severity): $($a.Message)"
	}
	
	#Return to the saved location to continue the loop
	Pop-Location
}