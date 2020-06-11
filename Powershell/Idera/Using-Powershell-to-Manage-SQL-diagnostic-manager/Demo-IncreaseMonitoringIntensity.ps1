<#
.SYNOPSIS
   Increase intensity of monitoring 
.DESCRIPTION
   Change collection interval to 1 minute and turn on Query Monitor
.PARAMETER instanceName
   Name of monitored server to increase monitoring of
#>

Param(
  [string]$instanceName
)

Set-SQLdmMonitoredInstance -Path $(Escape-SQLdmName -Name $instanceName) -QMEnabled -ScheduledCollectionIntervalMinutes 1
