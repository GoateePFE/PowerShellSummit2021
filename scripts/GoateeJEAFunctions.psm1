<#
For a given username
-From AD get their last password reset date
-From LOTR API get users "passphrase" for security (ie. random movie quote)
-From AD check that a computer account exists
-From Tanium get last logged in machines with IP, FQDN, OS, OS release ID, disk free, serial number, etc.

Requires
- RSAT for Active Directory
- Tanium TanREST module
#>

Function Get-ComputerOfUserDetails {
Param(
    [string]$UserName
)
    ### EDIT THESE VALUES ###
    $WorkingDirectory = 'C:\Tools\GoateeJEA'       #Location of script files
    $ServiceAccount   = 'Goatee_Tools_User'        #ID for both AD & Tanium, just the user name
    $TaniumServer     = '192.168.1.31'
    #########################

    $ErrorActionPreference = 'Stop'

    # Adjust this to the script working directory where the script and credentials are stored
    Set-Location $WorkingDirectory

    # Could adjust this section to use Azure Key Vault instead
    
    # Also see for options:
    # https://docs.microsoft.com/en-us/archive/blogs/ashleymcglone/how-to-run-a-powershell-script-against-multiple-active-directory-domains-with-different-credentials

    # Credential used to query AD and Tanium
    # $ServiceAccount is the user name Tanium console login used to query Tanium and also used to query AD
    # DO NOT include the AD domain prefix, just the username
    # The password is encrypted in the file from the setup procedure
    $ServiceAccount = 'Goatee_Tools_User'         #ID for both AD & Tanium, just the user name
    $PasswordSecure = Get-Content cred.dat | ConvertTo-SecureString -Key (Get-Content sauce.dat)
    $cred = New-Object System.Management.Automation.PsCredential($ServiceAccount,$PasswordSecure)
    # API key
    $APIKeySecure = Get-Content apikey.dat | ConvertTo-SecureString -Key (Get-Content sauce.dat)
    $APIKeyText   = (New-Object System.Management.Automation.PsCredential('APIKey',$APIKeySecure)).GetNetworkCredential().Password

    cls
    "`nLooking for computers where [$UserName] is logged in..."
    $TaniumData = Get-TaniumComputerLastUser -UserName $UserName -cred $cred
    If ($TaniumData -eq 'Error' -or $TaniumData -eq $null) {

        "`nUser [$UserName] is not currently logged into a computer."

    } Else {

        $Hostname = ($TaniumData.'Computer Name' -split '\.')[0]
        $ADData   = Test-ADComputer -EndpointName $Hostname -cred $cred -Detailed

        $UserNameMinusDomain = ($TaniumData.'Last Logged In User' -split '\\')[1]
        $LOTRData            = Get-UserSecurityPassphrase -Username $UserNameMinusDomain -APIKey $APIKeyText

        "`nUser name is: $($TaniumData.'Last Logged In User')"

        "`nUser security passphrase is:"
        $LOTRData

        "`nComputer(s) where user is logged in:"
        $TaniumData | Format-List 'Last Logged In User','Computer Name','Operating System','Windows OS Release ID','IPv4 Address'
        
        "Computer account is in AD : " + $ADData[0]
        If ($ADData[0]) {
            "OU Path                   : " + $ADData[1]
            "Computer password date    : " + $ADData[2]
        }
    }
}

Function Test-ADComputer {
Param(
    [string]$EndpointName,
    [PSCredential]$cred,
    [switch]$Detailed
)

    # Does this computer exist in AD?
    Try {
        Import-Module ActiveDirectory
        $ADComputer = Get-ADComputer -Identity $EndpointName -Server dc1.goatee.lab -Credential $cred -Properties Name, PasswordLastSet, DistinguishedName
        If ($ADComputer.Name -eq $EndpointName) {
            $IsInAD = @($true,$ADComputer.DistinguishedName,$ADComputer.PasswordLastSet)
        } Else {
            $IsInAD = @($false)
        }
    }
    Catch {
        $IsInAD = @('Error')
    }

    $IsInAD
}

Function Get-TaniumComputerLastUser {
Param(
    [string]$UserName = 'foo',
    [PSCredential]$cred
)

    # Is this computer in Tanium?
    # Who is the last logged on user?
    # Requires TanRest module from Tanium account team
    Import-Module TanRest

    Try {
        $WebSession = New-TaniumWebSession -ServerURI "https://$($TaniumServer)/" -DisableCertificateValidation -Credential $cred -WarningAction SilentlyContinue

        $TaniumResult = (@{ text = "Get Computer Name and Last Logged In User?maxAge=60 and IPv4 Address and Operating System and Windows OS Release ID from all machines with Last Logged In User ends with $UserName" } | 
        New-TaniumCoreParseQuestions -WebSession $WebSession)[0] | 
        New-TaniumCoreQuestions |
        Wait-TaniumCoreQuestionResultInfos -WarningAction SilentlyContinue | 
        Get-TaniumCoreQuestionResults | 
        Format-TaniumCoreQuestionResults

        $TaniumResult
    }
    Catch {
        'Error'
    }

}

# For cleaning up the strings from the LOTR API
Function Clear-StringExtraSpaces {
Param($String)
    While ($String -like '*  *') {
        $String = $String -replace '  ',' '
    }
    $String
}

Function Get-UserSecurityPassphrase {
    Param(
        [string]$UserName,
        [string]$APIKey
    )

    $Headers = @{
        Authorization="Bearer $APIKey"
        Content = 'application/json'
    }
    $LOTRChar = Invoke-RestMethod -Method Get -Uri "https://the-one-api.dev/v2/character?name=/$UserName/i" -Headers $Headers
    $LOTRQuoteOfChar = Invoke-RestMethod -Method Get -Uri "https://the-one-api.dev/v2/quote?character=$($LOTRChar.docs[0]._id)" -Headers $headers
    Clear-StringExtraSpaces -String ($LOTRQuoteOfChar.docs.dialog | Get-Random -ErrorAction SilentlyContinue)
}

Export-ModuleMember -Function *
