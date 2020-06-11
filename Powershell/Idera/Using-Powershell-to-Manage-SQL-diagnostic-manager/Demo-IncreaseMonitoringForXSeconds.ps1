<#
.SYNOPSIS
   Intensify monitoring for a fixed number of seconds
.DESCRIPTION
   Set monitoring interval to 1 minute and enable query monitor for the specified number of seconds
.PARAMETER instanceName
   The instance to affect
.PARAMETER intervalInSeconds
   Number of seconds to keep intensified monitoring running
#>

Param(
  [string]$instanceName,
  [int]$intervalInSeconds
)

Demo-IncreaseMonitoringIntensity.ps1 -instanceName $instanceName
sleep $intervalInSeconds
Demo-DecreaseMonitoringIntensity.ps1 -instanceName $instanceName