$_path_to_setup = """C:\CoreDB\SQLServer2014\setup.exe"""
#remove instnaz
    $_remove_parameters = "/q /action=removeNode /INSTANCENAME=""de-tst-01"" /CONFIRMIPDEPENDENCYCHANGE=""0""" 
    Start-Process $_path_to_setup -ArgumentList $_remove_parameters -wait
    Read-Host "Press enter to close. "

