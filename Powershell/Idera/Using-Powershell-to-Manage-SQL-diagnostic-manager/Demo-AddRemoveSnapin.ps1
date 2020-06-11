<#
.SYNOPSIS
   Add the SQLdm snapin and remove it again
.DESCRIPTION
   Add the SQLdm snapin and remove it again
.PARAMETER <paramName>
   None
.EXAMPLE
   N/A
#>
Write-Output 'Before Adding'
Get-PSSnapin | Format-Wide
Add-PSSnapin sqldmsnapin
Write-Output 'After Adding'
Get-PSSnapin | Format-Wide
Remove-PSSnapin sqldmsnapin
Write-Output 'After Removing'
Get-PSSnapin | Format-Wide


