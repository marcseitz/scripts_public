cls
$_path_to_setup = """C:\CoreDB\SQLServer2012_inkl_SP1\setup.exe"""
$_All_Instanze = $(Get-Item "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL" -ErrorAction SilentlyContinue).property
#$_All_Instanze

foreach ($instanz in $_All_Instanze) {
    $_installed = ""
    write-host "uninstall $instanz" -ForegroundColor Yellow
    $_remove_parameters = "/q /action=removeNode /INDICATEPROGRESS /INSTANCENAME=""$instanz"""
    Start-Process $_path_to_setup -ArgumentList $_remove_parameters -wait 
    write-host "Instanz $instanz uninstalled" -ForegroundColor Green
}
Read-Host "press Enter to exit"

