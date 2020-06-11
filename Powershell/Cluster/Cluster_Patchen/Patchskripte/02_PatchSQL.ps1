cls
$_2008R2SP = ""
$_2008R2SP_patch = ""
$_2008SP = ""
$_2008SP_patch = ""
$_2012SP = ""
$_2012SP_patch = ""
$_2014SP = ""
$_2014SP_patch = "1"

$_Instanzname = $($(Get-Service | where-object {$_.displayName -like "SQL Server (*"}))

$_ask = "$_2008R2SP"+"$_2008R2SP_patch"+"$_2008SP"+"$_2008SP_patch"+"$_2012SP"+"$_2012SP_patch"+"$_2014SP"+"$_2014SP_patch"
#if ($_ask) {Write-host "Auftrag im header definiert"} else {Write-host "Auftragsdaten erfassen"}

# intern oder extern
if (test-path "\\de-dacmgt980wp\sdl$" -ErrorAction SilentlyContinue )
{
    $_sdl = "\\de-dacmgt980wp\sdl$\Microsoft"
}
else
{
    $_sdl = "\\de-dacmgt981wp\sdl$\Microsoft"
}


<#
Foreach ($_name in $_Instanzname) { 
    $_SQL = ""
    $_currInstance = $_name.name.split("$")[1] 
    $_path = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$_currInstance\MSSQLServer\CurrentVersion\"
    $_Version = ($(Get-ItemProperty -path $_path -name "CurrentVersion").CurrentVersion).split(".")
#    $_Version[2]
    if ( $_Version[0] -eq "10" )
    {
        if ( $_Version[1] -eq "50" )
        {
            if ( $_Version[2] -lt "6529" )
            {
                if ( $_Version[2] -lt "6000" )
                {
                    $_2008R2SP_patch = "1"
                }
                else
                {
                    $_2008R2SP = "1"
                }
            }
        }
        else
        {
            if ( $_Version[2] -lt "6535" )
            {
                if ( $_Version[2] -lt "6000" )
                {
                    $_2008SP = "1"
                }
                else
                {
                    $_2008SP_patch = "1"
                }
            }
        }
    }
    else
    {
        if ( $_Version[0] -eq "12" )
        {
            if ( $_Version[2] -lt "5634" )
            {
                if ( $_Version[2] -lt "5058" )
                {
                    $_2012SP = "1"
                }
                else
                {
                    $_2012SP_patch = "1"
                }
            }
        }
        else
        {
            if ( $_Version[0] -eq "12" )
            {
                if ( $_Version[2] -lt "5634" )
                {
                    if ( $_Version[2] -lt "5058" )
                    {
                        $_2014SP = "1"
                    }
                    else
                    {
                       $_2014SP_patch = "1"
                    }
                }
            }
        }
    }
}

#>

# Function install
function installpatch {

    $_path2 = $args[0]
    $_sversion2 = $args[1]
    Start-Process -FilePath $_path -ArgumentList "/action=Patch /allinstances /quiet /IAcceptSQLServerLicenseTerms" -Wait
#    Write-host "Start-Process -FilePath $_path2 -ArgumentList '/action=Patch /allinstances /quiet /IAcceptSQLServerLicenseTerms' -Wait"
    Start-Process "notepad.exe" -ArgumentList "C:\Program Files\Microsoft SQL Server\$_sversion2\Setup Bootstrap\Log\Summary.txt" -Wait
    Restart-Computer
    exit
}
# end function install

if ($_ask) {Write-host "Auftrag im header definiert"}
else
{
    Write-host "Auftragsdaten erfassen"
    $_auswahl1 = read-host "enter 2008=1 , 2008R2=2 , 2012=3 , 2014=4 , discover=0"
    if ( $_auswahl1 -ne "0")
    {
    $_auswahl2 = read-host "enter SP=1 , patch=2"
    }
    else
    {
        $_auswahl1 = ""
        Start-Process "$_sdl\Microsoft SQL Server 2014\Microsoft SQL Server 2014 SP1\Setup.exe" -ArgumentList " /Action=RunDiscovery" -Wait
        $_auswahl1 = read-host "enter 2008=1 , 2008R2=2 , 2012=3 , 2014=4 , discover=0"
        $_auswahl2 = read-host "enter SP=1 , patch=2"
    }
}


if ( $_auswahl1 -eq 1 )
{
    if ( $_auswahl2 -eq 1 )
    {
        Write-host "install SP4 for 2008"
        $_path = "$_sdl\SQL Server\Microsoft.SQL.Server.2008.RTM\Updates\SP4\SQLServer2008SP4-KB2979596-x64-ENU.exe"
        $_sversion = "80"
        installpatch $_path $_sversion
    }

    if ( $_auswahl2 = "2" )
    {
        Write-host "install Patch for 2008 with SP"
        $_path = "$_sdl\SQL Server\Microsoft.SQL.Server.2008.SP4\Updates\SecPatch_MS15-058\SQLServer2008-KB3045308-x64.exe"
        $_sversion = "80"
        installpatch $_path $_sversion
    }
}

if ( $_auswahl1 -eq 2 )
{
    if ( $_auswahl2 -eq 1 )
    {
        Write-host "install SP3 for 2008R2"
        $_path = "$_sdl\SQL Server\Microsoft SQL Server 2008 R2\SQL2008R2_SP3\SQLServer2008R2SP3-KB2979597-x64-ENU.exe"
        $_sversion = "100"
        installpatch $_path $_sversion
    }

    if ( $_auswahl2 = "2" )
    {
        Write-host "install Patch for 2008R2 with SP"
        $_path = "$_sdl\SQL Server\Microsoft SQL Server 2008 R2\SQL2008R2_SP3\Updates\SecPatch_MS15-058\SQLServer2008R2-KB3045314-x64.exe"
        $_sversion = "100"
        installpatch $_path $_sversion
    }
}

if ( $_auswahl1 -eq 3 )
{
    if ( $_auswahl2 -eq 1 )
    {
        Write-host "install SP2 for 2012"
        $_path = "$_sdl\Microsoft SQL Server 2012\Updates\SP2\SP2\SQLServer2012SP2-KB2958429-x64-ENU.exe"
        $_sversion = "110"
        installpatch $_path $_sversion
    }

    if ( $_auswahl2 = "2" )
    {
        Write-host "install Patch for 2012 with SP"
        $_path = "$_sdl\Microsoft SQL Server 2012\Microsoft SQL Server 2012 SP2\Updates\CU8\SQLServer2012-KB3082561-x64.exe"
        $_sversion = "110"
        installpatch $_path $_sversion
    }
}

if ( $_auswahl1 -eq 4 )
{
    if ( $_auswahl2 -eq 1 )
    {
        Write-host "install SP1 for 2014"
        $_path = "$_sdl\Microsoft SQL Server 2014\Microsoft SQL Server 2014 RTM\Updates\SP1\setup.exe"
        $_sversion = "120"
        installpatch $_path $_sversion
    }

    if ( $_auswahl2 = "2" )
    {
        Write-host "install Patch for 2014 with SP"
        $_path = "$_sdl\Microsoft SQL Server 2014\Microsoft SQL Server 2014 SP1\Updates\CU6\SQLServer2014-KB3144524-x64.exe"
        $_sversion = "120"
        installpatch $_path $_sversion
    }
}



#if ($_2014SP_patch)
#{
#    Write-host "install Patch for 2014 with SP"
#    $_path = "$_sdl\Microsoft SQL Server 2014\Microsoft SQL Server 2014 SP1\Updates\CU6\SQLServer2014-KB3167392-x64.exe"
#    $_sversion = "120"
#    installpatch $_path $_sversion
#}

if ($_2014SP_patch)
{
    Write-host "install Patch for 2014 with SP"
    $_path = "C:\CoreDB\SQLServer2014\Updates\CU6\SQLServer2014-KB3167392-x64.exe"
    $_sversion = "120"
    installpatch $_path $_sversion
}
