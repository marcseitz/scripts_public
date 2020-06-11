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
    }
    else
    {
        $_isclustername = $(Invoke-Command -ComputerName $_remote -ScriptBlock { 
            try 
            {
                import-module failoverclusters -ErrorAction SilentlyContinue
                $_iscluster = $(get-cluster -ErrorAction SilentlyContinue).name
            } #try ende
            catch {} 
        $_iscluster
        } )

        if ( $_isclustername )
        {
            write-host "  Cluster: $_isclustername "
            foreach ($_node in $(Get-ClusterNode -cluster $_isclustername )) { #for each 2
                $_remote=$(Resolve-DnsName $_node | select name ).name
                    Invoke-Command -ComputerName $_remote -ScriptBlock { #invoke each 1
                    $_Allpfad = $($(Get-childItem -Path "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\") | Where-Object {$_.Name -like "*SqlServer*"}).Name
                    $_currentPolicy = $(get-executionPolicy)
                
                    foreach ($_pfad in $_allpfad ) { #for each 1
                    $_vers = $($_pfad).Split(".")[4]
                    $_path = "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.SqlServer.Management.PowerShell.$_vers\"
                        If (Test-Path "$_path") # if 2
                        { 
                            $_Policy = $(Get-ItemProperty -path $_path -name "ExecutionPolicy").ExecutionPolicy
                            if ($_Policy -ne "$_currentPolicy") #if 1
                            {
                                Write-host "    $env:COMPUTERNAME ExecutionPolicy = $_Policy on Pathversion $_vers CurrentWindowsPolicy = $_currentPolicy" -ForegroundColor red
                            }
                            else
                            {
                                Write-host "    $env:COMPUTERNAME ExecutionPolicy = $_Policy on Pathversion $_vers CurrentWindowsPolicy = $_currentPolicy" -ForegroundColor yellow
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
                $_currentPolicy = $(get-executionPolicy)
                
                foreach ($_pfad in $_allpfad ) {
                $_vers = $($_pfad).Split(".")[4]
                $_path = "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.SqlServer.Management.PowerShell.$_vers\"
                    If (Test-Path "$_path")
                    { 
                        $_Policy = $(Get-ItemProperty -path $_path -name "ExecutionPolicy").ExecutionPolicy
                        if ($_Policy -ne "$_currentPolicy")
                        {
                            Write-host "    $env:COMPUTERNAME ExecutionPolicy = $_Policy on Pathversion $_vers CurrentWindowsPolicy = $_currentPolicy" -ForegroundColor red
                        }
                        else
                        {
                            Write-host "    $env:COMPUTERNAME ExecutionPolicy = $_Policy on Pathversion $_vers CurrentWindowsPolicy = $_currentPolicy" -ForegroundColor yellow
                        }
                    }
                }
            }
        }
    }
}
