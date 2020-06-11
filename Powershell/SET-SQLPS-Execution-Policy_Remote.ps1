cls
$_Serverlist="$PSScriptRoot\servers.txt"

foreach ($_node in (get-content "$_Serverlist")) {

    $_iscluster = ""
    $_remote=$(Resolve-DnsName $_node | select name ).name
    Write-Host "On Node $_remote"
    $_computer = try { Invoke-Command -ComputerName $_remote -ScriptBlock { $env:COMPUTERNAME } -ErrorAction SilentlyContinue } catch {}

    if (!$_computer) 
    { 
        Write-host "=      Could not connect to $_node" -ForegroundColor Red 
        $_node | Out-File $PSScriptRoot\error_servers.txt -Encoding default -Append
    }
    else
    {

    $_isclustername = $(Invoke-Command -ComputerName $_remote -ScriptBlock { 
        try 
        {
            import-module failoverclusters -ErrorAction SilentlyContinue
            $_iscluster = $(get-cluster -ErrorAction SilentlyContinue).name
        } 
        catch {} 
        $_iscluster
    })

    if ( $_isclustername )
    {
        write-host "  Cluster: $_isclustername"
        foreach ($_node in $(Get-ClusterNode -cluster $_isclustername )) {
            $_remote=$(Resolve-DnsName $_node | select name ).name
                Invoke-Command -ComputerName $_remote -ScriptBlock {
                $_Allpfad = $($(Get-childItem -Path "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\") | Where-Object {$_.Name -like "*SqlServer*"}).Name

                foreach ($_pfad in $_allpfad ) {
                $_vers = $($_pfad).Split(".")[4]
                $_path = "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.SqlServer.Management.PowerShell.$_vers\"
                    If (Test-Path "$_path")
                    { 
                        $_Policy = $(Get-ItemProperty -path $_path -name "ExecutionPolicy").ExecutionPolicy
                        if ($_Policy -ne "0")
                        {
                            Write-host "    $env:COMPUTERNAME ExecutionPolicy = $_Policy on Pathversion $_vers" -ForegroundColor yellow
    #                        $_node | Out-File $PSScriptRoot\ToChange-servers.txt -Encoding default -Append
    #                        set-ItemProperty -path $_path -name "ExecutionPolicy" -value 0
                        }
                        else
                        {
                            Write-host "    $env:COMPUTERNAME allready set ExecutionPolicy = $_Policy on Pathversion $_vers" -ForegroundColor Green
    #                        $_node | Out-File $PSScriptRoot\finished-servers.txt -Encoding default -Append
                        }
                    }
                }
            }
        } 
        $_isclustername = ""
    }
    else
    {
    write-host "  No Cluster"
        Invoke-Command -ComputerName $_remote -ScriptBlock {
            $_Allpfad = $($(Get-childItem -Path "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\") | Where-Object {$_.Name -like "*SqlServer*"}).Name
            foreach ($_pfad in $_allpfad ) {
            $_vers = $($_pfad).Split(".")[4]
            $_path = "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.SqlServer.Management.PowerShell.$_vers\"
                If (Test-Path "$_path")
                { 
                    $_Policy = $(Get-ItemProperty -path $_path -name "ExecutionPolicy").ExecutionPolicy
                    if ($_Policy -ne "0")
                    {
                        Write-host "    $env:COMPUTERNAME ExecutionPolicy = $_Policy on Pathversion $_vers" -ForegroundColor yellow
   #                     $_node | Out-File $PSScriptRoot\ToChange-servers.txt -Encoding default -Append

    #                   set-ItemProperty -path $_path -name "ExecutionPolicy" -value 0
                    }
                    else
                    {
                        Write-host "    $env:COMPUTERNAME allready set ExecutionPolicy = $_Policy on Pathversion $_vers" -ForegroundColor Green
  #                      $_node | Out-File $PSScriptRoot\finished-servers.txt -Encoding default -Append
                    }
                }
            }
        } -ErrorAction SilentlyContinue
    }
    }
}
