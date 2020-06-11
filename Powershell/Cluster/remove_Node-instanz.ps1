cls

$_path_to_setup = """C:\CoreDB\SQLServer2014\setup.exe"""

$_Instanz = Read-Host "Instanzname: "
#remove instnaz
    $_remove_parameters = "/q /action=removeNode /INSTANCENAME=""$_Instanz"" /CONFIRMIPDEPENDENCYCHANGE=""0""" 
    Start-Process $_path_to_setup -ArgumentList $_remove_parameters -wait
    Read-Host "Press enter to close. "

