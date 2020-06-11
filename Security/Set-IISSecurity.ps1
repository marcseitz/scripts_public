<#
.SYNOPSIS
  Setting up the schannel for IIS security

.DESCRIPTION
  Setting up the schannel configurationfor IIS security

   - Protocols
   - Ciphers
   - Hashs
   - Key Exchanges
   - SSL Cipher Suite Order

.PARAMETER printDefaults
  Print the default config
  
.INPUTS
  none

.OUTPUTS
  only logging on console 

.NOTES

  Version:        3.0
  Author:         Steffen Hollstein 
  Creation Date:  29.06.2015
  Purpose/Change: Initial script development
  
  Editor:		Nenad Banovic
  Edit Date:	16.05.2018

.EXAMPLE
  Set-IISSecurity
  Setting up the security

.EXAMPLE
  Set-IISSecurity -printDefaults
  Print a list of the default configuration

#>

[cmdletbinding()]
param(
    [switch]$printDefaults
)


function Set-Parameter([string]$regPath,[array]$parameters)
{
    Foreach ($parameter in $parameters) {
        $keyName = $parameter.Split("|")[0]
        #$key = (get-item HKLM:\).OpenSubKey($regPath, $true).CreateSubKey($keyName)
        For ($i=1; $i -lt $parameter.Split("|").Count; $i++)
        {

            If (-not (Get-Item "HKLM:\$($regPath)" -ErrorAction SilentlyContinue))
            {
                New-Item -Path "HKLM:\$(Split-path $regPath -Parent)" -Name $(Split-path $regPath -Leaf) -Force -Confirm:$false | Out-Null
            }
            $key = (get-item HKLM:\).OpenSubKey($regPath, $true).CreateSubKey($keyName)
            $property = $parameter.Split("|")[$i].Split(";")[0]
            $value = $parameter.Split("|")[$i].Split(";")[1]
            $type = $parameter.Split("|")[$i].Split(";")[2]

            Write-Host "[Registry Keys]    : Set '$keyName' with '$property' to '$value'" -ForegroundColor Yellow
            $key.SetValue($property, $value, [Microsoft.Win32.RegistryValueKind]::$type)
            
            
        }
        $key.close()
        
    }
}


Function Set-CipherSuiteOrder ([string]$regPath,[string]$keyName, [string]$property, [string[]]$values)
{
	$cipherSuitesAsString = [string]::join(',', $values)
    Write-Host "[CipherSuiteOrder] : Set '$keyName' with '$cipherSuitesAsString' " -ForegroundColor Yellow
	New-Item 'HKLM:\SOFTWARE\Policies\Microsoft\Cryptography\Configuration\SSL\00010002' -ErrorAction SilentlyContinue
	New-ItemProperty -path 'HKLM:\SOFTWARE\Policies\Microsoft\Cryptography\Configuration\SSL\00010002' -name 'Functions' -value $cipherSuitesAsString -PropertyType 'String' -Force | Out-Null
}

function PrintArray([array]$array)
{
    Foreach ($item in $array)
    {
        Write-Host " - $item"
    }
}

function PrintDefault()
{
    Write-Host "Allow HTTP Trace = $allowHttpTrace"
    Write-Host "Insecure Encryptions"
    PrintArray $insecureEncryptions
    Write-Host "Secure Encryptions"
    PrintArray $secureEncryptions
    Write-Host "Insecure Ciphers"
    PrintArray $insecureCiphers
    Write-Host "Secure Ciphers"
    PrintArray $secureCiphers
    Write-Host "Insecure Hashs"
    PrintArray $insecureHashs
    Write-Host "Secure Hashs"
    PrintArray $secureHashs
    Write-Host "Secure Key Exchange Algorithms"
    PrintArray $secureKeyExchangeAlgorithms
    Write-Host "Insecure Renegotiation"
    PrintArray $insecureRenegotiation
    Write-Host "Cipher Suite Order"
    PrintArray $cipherSuiteOrder
}

$allowHttpTrace = $false

$schannelRegKey = "SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL"
$protocolsRegKey = [string]::Concat($schannelRegKey,"\","Protocols")
$ciphersRegKey = [string]::Concat($schannelRegKey,"\","Ciphers")
$hashsRegKey = [string]::Concat($schannelRegKey,"\","Hashes")
$keyExchangeRegKey = [string]::Concat($schannelRegKey,"\","KeyExchangeAlgorithms")
$pfsRegKey = "SOFTWARE\Policies\Microsoft\Cryptography\Configuration\SSL"


 $insecureEncryptions = @(
        'Multi-Protocol Unified Hello\Server|Enabled;0;DWORD|DisabledByDefault;-1;DWORD',
        'PCT 1.0\Server|Enabled;0;DWORD|DisabledByDefault;-1;DWORD',
        'SSL 2.0\Server|Enabled;0;DWORD|DisabledByDefault;-1;DWORD',
        'SSL 3.0\Server|Enabled;0;DWORD|DisabledByDefault;-1;DWORD', 
        'TLS 1.0\Server|Enabled;0;DWORD|DisabledByDefault;-1;DWORD',       
        'TLS 1.1\Server|Enabled;0;DWORD|DisabledByDefault;-1;DWORD',
        'SSL 2.0\Client|Enabled;0;DWORD|DisabledByDefault;-1;DWORD',
        'SSL 3.0\Client|Enabled;0;DWORD|DisabledByDefault;-1;DWORD'       
    )

    #enable secure or necessary encryptions 
    $secureEncryptions = @(
		'TLS 1.0\Client|Enabled;-1;DWORD|DisabledByDefault;0;DWORD',
		'TLS 1.1\Client|Enabled;-1;DWORD|DisabledByDefault;0;DWORD',
        'TLS 1.2\Client|Enabled;-1;DWORD|DisabledByDefault;0;DWORD',
        'TLS 1.2\Server|Enabled;-1;DWORD|DisabledByDefault;0;DWORD'
    )

    #disable insecure/weak ciphers
    $insecureCiphers = @(
      'DES 56/56|Enabled;0;DWORD',
      'NULL|Enabled;0;DWORD',
      'RC2 40/128|Enabled;0;DWORD',
      'RC2 56/128|Enabled;0;DWORD',
      'RC2 128/128|Enabled;0;DWORD',
      'RC4 40/128|Enabled;0;DWORD',
      'RC4 56/128|Enabled;0;DWORD',
      'RC4 64/128|Enabled;0;DWORD',
      'RC4 128/128|Enabled;0;DWORD'
    )

    $secureCiphers = @(
      'AES 128/128|Enabled;-1;DWORD',	  
      'Triple DES 168/168|Enabled;0;DWORD'
      'AES 256/256|Enabled;-1;DWORD'
    )

    $insecureHashs = @(
        'MD5|Enabled;0;DWORD'
    )

    $secureHashs= @(
        'SHA|Enabled;-1;DWORD',
        'SHA256|Enabled;-1;DWORD',
        'SHA384|Enabled;-1;DWORD',
        'SHA512|Enabled;-1;DWORD'
    )
	
    $secureKeyExchangeAlgorithms = @(
        'Diffie-Hellman|Enabled;-1;DWORD|ClientMinKeyBitLength;2048;DWORD|ServerMinKeyBitLength;2048;DWORD',
        'PKCS|Enabled;-1;DWORD',
        'ECDH|Enabled;-1;DWORD'
    )


    #Disable insecure renegotiation in SslStream, see https://support.microsoft.com/en-us/kb/980436
    $insecureRenegotiation = @(
        'Protocols|AllowInsecureRenegoClients;0;DWORD',
        'Protocols|DisableRenegoOnServer;1;DWORD'
    )

$cipherSuiteOrder = @(	
	'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384_P521',
	'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384_P384',
	'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256_P521',
	'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256_P384',
	'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256_P256',
	'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384_P521',
	'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384_P384',
	'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384_P256',
	'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384_P521',
	'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384_P384',
	'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384_P256',
	'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256_P521',
	'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256_P384',
	'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256_P256',
	'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256_P256',
	'TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256_P256'

	)
###BIZTALK
	#'TLS_RSA_WITH_AES_256_GCM_SHA384',
    #'TLS_RSA_WITH_AES_128_GCM_SHA256',
    #'TLS_RSA_WITH_AES_256_CBC_SHA256',
    #'TLS_RSA_WITH_AES_128_CBC_SHA256',
    #'TLS_RSA_WITH_AES_256_CBC_SHA',
    #'TLS_RSA_WITH_AES_128_CBC_SHA'
	#
if ($printDefaults)
{
    PrintDefault
    exit 0
}
Write-Host "[START] - Server Security Setup on " $env:computername "  " -BackgroundColor Green


# http trace
try
{
    $trace=Get-WebConfiguration -Filter "/system.webServer/security/requestFiltering/verbs/add[@verb='TRACE']" -ErrorAction SilentlyContinue
    if (-not $trace)
    {
        Write-Host "[IIS Security ]    : Set Configuration "-ForegroundColor Yellow
        [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Web.Administration") | Out-Null
        $serverManager = New-Object Microsoft.Web.Administration.ServerManager
        $config = $serverManager.GetApplicationHostConfiguration()
        $requestFilteringSection = $config.GetSection("system.webServer/security/requestFiltering");
        $verbColl = $requestFilteringSection.GetCollection("verbs");
        $addElement = $verbColl.CreateElement("add");
        $addElement["verb"] = "TRACE";
        $addElement["allowed"] = ([string]$allowHttpTrace).ToLower();
        $verbColl.Add($addElement) | Out-Null ;
        $serverManager.CommitChanges();
    }
}
catch
{
    Write-Warning "Could not set verb TRACE to $allowHttpTrace, maybe the section does not exist or the IIS role is not active!"
}
# Remove "Microsoft-HTTPAPI/2.0" from http response header  
New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Services\HTTP\Parameters' -name 'DisableServerHeader' -value "1" -PropertyType 'DWORD' -Force | Out-Null
Write-Host "[Registry Keys]    : Set 'Services\HTTP\Parameters' with 'DisableServerHeader' to '1'" -ForegroundColor Yellow


Set-Parameter $protocolsRegKey $insecureEncryptions
Set-Parameter $protocolsRegKey $secureEncryptions 
Set-Parameter $ciphersRegKey $insecureCiphers
Set-Parameter $ciphersRegKey $secureCiphers
Set-Parameter $hashsRegKey $insecureHashs
Set-Parameter $hashsRegKey $secureHashs
Set-Parameter $keyExchangeRegKey $secureKeyExchangeAlgorithms
Set-Parameter $schannelRegKey $insecureRenegotiation
Set-CipherSuiteOrder $pfsRegKey "00010002" "Functions" $cipherSuiteOrder

Write-Host "[DONE] ...   " -BackgroundColor Green
