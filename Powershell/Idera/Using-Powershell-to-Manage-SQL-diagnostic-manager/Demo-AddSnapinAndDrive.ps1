<#
.SYNOPSIS
   Add the SQLdm Snapin and a SQLdm Drive
.DESCRIPTION
   Add the SQLdm Snapin and a SQLdm Drive with name SQLDM:
.PARAMETER <paramName>
   None
.EXAMPLE
   N/A
#>
Add-PsSnapin sqldmsnapin
New-SQLdmDrive -Name SQLDM -RepositoryInstance VHARPL2 -RepositoryName SQLdmRepository 
