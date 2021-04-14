break
<#
break keyword at top in case you accidentally press F5 instead of F8

PowerShell Just Enough Administration (JEA) training and samples here:
https://github.com/GoateePFE/PowerShell2019

#>


#region ==== Setup JEA Module =================================================

# Create a folder for the module
$modulePath = Join-Path $env:ProgramFiles "WindowsPowerShell\Modules\GoateeJEA"

# Create an empty script module and module manifest.
New-Item -ItemType File -Path (Join-Path $modulePath "GoateeJEAFunctions.psm1") -Force
New-ModuleManifest -Path (Join-Path $modulePath "GoateeJEA.psd1") -RootModule "GoateeJEAFunctions.psm1"
# Put Goatee funtions into this GoateeJEAFunctions.psm1 module"

# Create the RoleCapabilities folder and copy in the PSRC file
$rcFolder = Join-Path $modulePath "RoleCapabilities"
New-Item -ItemType Directory $rcFolder
Set-Location $rcFolder

# Observe the folder structure for JEA
cls; Get-ChildItem $modulePath -Recurse

#endregion ====================================================================


#region ==== Set up JEA with role capabilities ================================

$rc_GoateeTools = @{
    Description             = 'Goatee PowerShell Remoting Tools'
    VisibleFunctions        = 'Get-ComputerOfUserDetails'
}
New-PSRoleCapabilityFile -Path .\GoateeTools.psrc @rc_GoateeTools

$pssc = @{
    SessionType         = 'RestrictedRemoteServer'
    LanguageMode        = 'NoLanguage'
    ExecutionPolicy     = 'RemoteSigned'
    RunAsVirtualAccount = $true
    RoleDefinitions     = @{
        "Goatee\Goatee_Tools_Users" = @{ RoleCapabilities = 'GoateeTools' }
    }
}
New-PSSessionConfigurationFile -Path .\JEAConfig.pssc @pssc

Test-PSSessionConfigurationFile -Path .\JEAConfig.pssc

Register-PSSessionConfiguration -Path .\JEAConfig.pssc -Name GoateeTools

explorer.exe $modulePath

# View the new session configuration
Get-PSSessionConfiguration

# Now replace the blank GoateeJEAFunctions.psm1 file with the one supplied

#endregion ====================================================================


#region ==== Secrets ==========================================================
<#

Service Account User
- Tanium console user
- Requires Tanium permission [Read Sensor] to content set [Incident Response]
- Permission to query AD

Group
Goatee_Tools_Users
- Session configuration access

This assumes we're querying one domain with the hostname (not FQDN).
#>

# Script working directory
Set-Location 'C:\Tools\GoateeJEA'

# Create an encryption key stored locally on disk.
# This will be used to encrypt the secrets used in the script.
#    NOTE: Typically this is done with a USER/COMPUTER combo and encrypted in that context without a key file
#          with syntax like this: Get-Credential | Export-CliXML -Path cred.xml [https://www.jaapbrasser.com/quickly-and-securely-storing-your-credentials-powershell/]
#          In this case JEA user context is a Virtual Account or GMSA. I've not tried it, but I'm guessing it
#          is either impossible or well nigh difficult to create your keys in that user context. If you get it
#          to work let me know. I simply didn't have time to lab it.
# *** WARNING ***
# Anyone with admin access to the tools server can decrypt these credentials.
# Secure this location.
# Explore more secure ways to manage these secrets on the tools server.

$Key = New-Object Byte[] 32
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
$Key | Out-File sauce.dat

# Password used for service account user to access Active Directory and Tanium
# Edit the user name of the account in the GoateeJEAFunctions.psm1 file
(Get-Credential -Message 'Enter the password of the AD service account to access AD and Tanium' -UserName 'Password-Only').Password | 
    ConvertFrom-SecureString -Key (Get-Content sauce.dat) | Set-Content cred.dat

# LOTR API Key
# Get yours here: https://the-one-api.dev/sign-up
Read-Host -Prompt "Enter API key" -AsSecureString | 
    ConvertFrom-SecureString -Key (Get-Content sauce.dat) | Set-Content apikey.dat

#endregion ====================================================================



#region ==== Test JEA =========================================================

$Domain = $env:USERDOMAIN

Get-PSSessionCapability -ConfigurationName 'GoateeTools' -Username "$Domain\Goatee_Tools_User"

# Test everything
# Must run in a session with a user who is a member of the role definition group defined above
$UserName = Read-Host -Prompt 'User name to find logged in'
Invoke-Command -ComputerName localhost -ConfigurationName GoateeTools -ScriptBlock {
    Get-ComputerOfUserDetails -UserName $using:UserName
}

#endregion ====================================================================



#region ==== Scope capabilities ===============================================

# Constrained Language Mode
Get-Help New-PSRoleCapabilityFile
Get-Help about_Language_Modes

# Identify the modules to import and the command types
Get-Command -Name 'Sort-Object','Format-Table','Format-List' | Format-Table -AutoSize
Get-Command -Name 'Get-SmbShare','Get-ChildItem' | Format-Table -AutoSize
Get-Command -Name 'Get-Disk','Get-Volume','Get-Partition' | Format-Table -AutoSize
Get-Command -Name 'Get-NetAdapter','Test-NetConnection' | Format-Table -AutoSize
Get-Command -Name ping,ipconfig,whoami | Format-Table -AutoSize

#endregion ====================================================================



#region ==== Undo =============================================================

Unregister-PSSessionConfiguration -Name GoateeTools

$modulePath = Join-Path $env:ProgramFiles "WindowsPowerShell\Modules\GoateeJEA"
Remove-Item -Path $modulePath -Recurse -Force

#endregion ====================================================================

