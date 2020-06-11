#$INPUT = "DE-DACSQLDWN610\DE_SPI_D_01;H:\Backup\MSSQL10_50.DE_SPI_D_01\MSSQL\Backup"
#$INPUT = "de-dacdbs987wp;D:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\Backup"
$INPUT = Get-Content \\de-dacmgt980wp\services$\MS SQL (CS-022)\Skripte\Powershell\Data.txt
#$INPUT = "DE-DACSQLDWN608\DE_SP_D_31;F:\Backup\MSSQL10_50.DE_SP_D_31\MSSQL\Backup"

####
##
##

function CurrentSize ([string] $_PATH) {
    return (Get-ChildItem $_PATH -Recurse | Measure-Object -property length -sum).sum/1GB
}

function MountPoint_Size ([string] $_SERVER, [string] $_PATH) {
    $_Volumes = Get-WmiObject -ComputerName $_SERVER -Class Win32_Volume
    $_Mountpoints = Get-WmiObject -ComputerName $_SERVER -Class Win32_MountPoint
    $_IsMountpoint = $false

    # find volume
    while ( $_PATH -ne "" ) {     
        $_Volume = $_Volumes | ? { $_.Caption -like ($_PATH+"*") }
        if ( $_Volume.Caption -like ($_PATH+"*")) {  break; }
        $_PATH = Split-Path $_PATH     
    } 

    # check if mountpoint
    if ( ( -Not ( $_Volume.Caption -match "^\w:\\$")) -and  ( $_Volume.Caption -ne "" ) ) {
        #$_Mountpoints | ? { $_.Volume -eq $_Volume.__RELPATH }
        If ( ($_Mountpoints | ? { $_.Volume -eq $_Volume.__RELPATH }).Volume -ne "") {        
            $_IsMountpoint = $true;         
            # Size
            $_Size = $_Volume.Capacity/1GB                 
        } else {
            $_Size = 0;

        }
    } else {
        $_Size = 0
    }
    return $_Size
}



foreach ($string in $INPUT) {
    # get data
    $_tmp = $string -split ";"
    $SERVER = ($_tmp[0] -split '\\')[0]
    $PATH = $_tmp[1]
    $PATH_ORG = $_tmp[1]

    $ErrorActionPreference = "SilentlyContinue"

    # generate UNC path
    $PATH = $PATH -replace '^(\w):\\(.+)$', ("\\$SERVER\"+'${1}'+'$\'+'${2}')

    # Output
    Write-Output ($SERVER+";"+$PATH_ORG+";"+((CurrentSize $PATH) -replace "\.",",")+";"+((MountPoint_Size $SERVER $PATH_ORG) -replace "\.",",")) >> OUTPUT.csv
}

