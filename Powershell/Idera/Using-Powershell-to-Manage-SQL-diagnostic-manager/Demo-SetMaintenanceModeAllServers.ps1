<#
.SYNOPSIS
   Enable maintenance mode for all servers, then disable
.DESCRIPTION
   Enable maintenance mode for all servers, then disable
#>

#Set the location to the SQLdm Instances directory
Set-Location SQLDM:\Instances

#Get a list of all instances
$instances = Get-ChildItem

#Step through every instance
foreach ($i in $instances)
{
	# Turn on maintenance mode
	Set-SQLdmMonitoredInstance -Path (Escape-SQLdmName -Name $i.InstanceName) -MMAlways
}

#Step through every instance
foreach ($i in $instances)
{
	# Turn off maintenance mode
	Set-SQLdmMonitoredInstance -Path (Escape-SQLdmName -Name $i.InstanceName) -MMNever
}