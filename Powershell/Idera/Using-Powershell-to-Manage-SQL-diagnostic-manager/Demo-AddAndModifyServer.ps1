<#
.SYNOPSIS
   Go through examples of adding, modifying, and removing servers
#>

#Add a server with all defaults
New-SQLdmMonitoredInstance -Path qa-bigrepo

#Remove a server from monitoring
Remove-SQLdmMonitoredInstance -Path qa-bigrepo

#Add a server with custom settings
New-SQLdmMonitoredInstance -Path qa-bigrepo -ScheduledCollectionIntervalMinutes 1 -Credential Get-Credential

#Modify a setting (in this case, enable query monitor)
Set-SQLdmMonitoredInstance -Path qa-bigrepo -QMEnabled 

#Remove again
Remove-SQLdmMonitoredInstance -Path qa-bigrepo
