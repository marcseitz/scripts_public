cls

$_Allpfad = $($(Get-childItem -Path "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\") | Where-Object {$_.Name -like "*SqlServer*"}).Name

foreach ($_pfad in $_allpfad ) {
$_vers = $($_pfad).Split(".")[4]
$_path = "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.SqlServer.Management.PowerShell.$_vers\"
    If (Test-Path "$_path")
    { 
        $_Policy = $(Get-ItemProperty -path $_path -name "ExecutionPolicy").ExecutionPolicy
        if ($_Policy -eq "0")
        {
                        set-ItemProperty -path $_path -name "ExecutionPolicy" -value RemoteSigned
        }
    }
}
