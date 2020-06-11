<#
.SYNOPSIS
   Decrease intensity of monitoring 
.DESCRIPTION
   Change collection interval to 6 minutes and turn off Query Monitor
.PARAMETER instanceName
   Name of monitored server to decrease monitoring of
.EXAMPLE
   <An example of using the script>
#>

Param(
  [string]$instanceName
)

Set-SQLdmMonitoredInstance -Path $(Escape-SQLdmName -Name $instanceName) -QMDisabled -ScheduledCollectionIntervalMinutes 6
