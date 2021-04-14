# PowerShell and DevOps Global Summit 2021
## April 27-29

#

# Give Super Powers Without Giving Away Super Secrets

You need to give the help desk access to special tooling without giving them special creds or API keys. But how? Today more than ever we are concerned about embedding privileged info in our scripts. But what if you’ve gotta have that to get the job done? In this session Ashley McGlone will demonstrate a solution he built for the real world using plain old out-of-the-box JEA (Just Enough Administration) to deliver the goods without giving away the goods.

### Mr. Ashley McGlone
### Technology Strategist, Tanium
### Twitter: [@GoateePFE](https://twitter.com/GoateePFE)
### Email: [ashley.mcglone@tanium.com](mailto:ashley.mcglone@tanium.com)

#

Welcome to PshSummit 2021!

This repo contains slides, scripts, and setup documentation for the solution demo in the session.
Also find a handy doc of links for more information on Tanium, a sponsor of this year's event.
Read below for the solution setup install and customization for your own environment.

#

## Problem

* People put passwords in scripts (along with other secrets, API keys, etc.)
* Bad actors like it when you do this
* InfoSec wants to find you and do things to you
* You are jeopardizing your company, your job, your livelihood when you do this
* JEA... this is the way...

## Use Case

* Help desk needs to look up data on users and computers from multiple sources.
* It is manual and takes too much time today.
* We don’t want to give them credentials or console access to all backend systems.
* We don’t want to add them to many security groups.
* We don’t want to distribute a script with embedded credentials.

## Solution

This sample solution uses PowerShell Just Enough Administration (JEA) to securely query three backend data systems. Each requires a credential or API key. All authentication secrets rest encrypted on the tools server. Support personel are a member of only one Active Directory group, granting them access to the constrained PowerShell session configuration. That constrained session only allows them to call the custom function for this task. They have no other access to the tools server or backend systems.

## Reference Reading

These links may help as you build out the solution:
* https://aka.ms/jeadocs
* https://github.com/PowerShell/JEA
* https://github.com/GoateePFE/PowerShellSummit2019/blob/master/Lab_03_JEA.md
* https://the-one-api.dev/documentation

## How It Works

* Operator launches a batch file that calls the PowerShell remoting constrained session configuration.

* Prompt operator for USERNAME:
  * Query Tanium for computer details where USERNAME is logged in.
    * Query AD for other COMPUTERNAME details
  * Query identity API for USERNAME passphrase

* All authentication secrets are sealed behind JEA:
  * Tanium credential
  * AD credential
  * Identity solution API key

## Solution Setup

*DISCLAIMERS*

*This solution is non-trivial (ie. involved, advanced, time-consuming). Once you learn the concepts of JEA, you can implement multiple secure solutions for you environment and be the hero. It is worth the time to learn it and apply it.*

* This solution demo _requires customization_ to work in your environment.
* JEA is a Windows technology and not supported on cross-platform PowerShell core.
* This solution uses the Tanium API as part of the demo. If you are not a Tanium customer, please adjust the server-side function and the sample batch script invocation to a scenario in your own environment. If you are a Tanium customer, request the TANREST PowerShell module from your account team.

Prerequisites:
* All of these steps happen on a Windows Active Directory domain-joined system with Windows PowerShell 5.1.
* PowerShell remoting must be enabled (default on Windows Server operating systems).
* This system must have the RSAT for Active Directory installed with the Active Directory PowerShell module.
* If you are a Tanium customer, contact your account team to get a copy of the PowerShell TANREST module. Place this module in the path `C:\Program Files\WindowsPowerShell\Modules\TanRest`.
* You will need an Active Directory user account with read access to Tanium and Active Directory. For this demo it is `Goatee_Tools_User`.
* You will need an Active Directory group to control JEA access. Add your service desk user accounts to this group only. For this demo the group is `Goatee_Tools_Users`.
* For fun this demo uses the Lord of the Rings API. Get your own API key here: [https://the-one-api.dev/sign-up](https://the-one-api.dev/sign-up)
* In my lab I have a couple machines set to autologin with LOTR character names. Here is a quick script to generate lab logins to use:
```
$ou = New-ADOrganizationalUnit LOTR -PassThru
$pw = 'P@ssw0rd' | ConvertTo-SecureString -AsPlainText -Force
'Gimli','Gandalf','Smeagol','Gollum','Galadriel','Frodo','Sam','Pippin','Merry','Legolas','Aragorn' | %{
    New-ADUser -Path $ou.DistinguishedName -AccountPassword $pw -Name $_ -Enabled $true -PassThru
}
```

Configuration:
1. Create a secure working directory where this code will reside. The default demo directory is `C:\Tools\GoateeJEA`. For ease-of-use start with this.
1. Place the files from this repo into that path.
1. Edit `SetupThePowerShellRemotingEndpoint.ps1` to adjust the `domain\group` in this script to set the AD group of help desk folks who need access.
```
"Goatee\Goatee_Tools_Users" = @{ RoleCapabilities = 'GoateeTools' }
```
4. Create your own environment-specific functions in the sample file `GoateeJEAFunctions.psm1`. Edit the service account name on this line for your environment:
```
$ServiceAccount = 'Goatee_Tools_User' 
```
5. For any function names you want exposed to the user, add those to the `VisibleFunctions` list as an array of strings:
```
 $rc_GoateeTools = @{
    Description             = 'Goatee PowerShell Remoting Tools'
    VisibleFunctions        = 'Get-ComputerOfUserDetails','Do-MyCustomFunction'
} 
```
6. Select and run this section of the script: `Setup JEA Module`
1. In the same session with the variables still in memory select and run this section of the script: `Set up JEA with role capabilities`
1. In the `Secrets` section of the script adjust for your own credentials and API keys. Select and run this section of the script. Answer the prompts with the account and secret information called out in the prerequisites.
1. The new JEA module folder will have an empty module functions file. Replace the blank `GoateeJEAFunctions.psm1` file with the one you copied and edited in the working directory. Copy from `C:\Tools\GoateeJEA\` to `C:\Program Files\WindowsPowerShell\Modules\GoateeJEA\`.

Testing
* Edit the tools server FQDN and use an account in the `Goatee_Tools_Users` AD group to test this functionality (works both locally and remotely):
```
Invoke-Command -ComputerName TOOLS.SERVER.FQDN -ConfigurationName GoateeTools -ScriptBlock {Get-ComputerOfUserDetails -EndpointName COMPUTER-NAME-GOES-HERE-NO-FQDN}
```
* Modify this remoting session to your own purposes. For example, you could open a persistent constrained session and store it in a variable. Then you could reference that session for multiple calls. Finally, close the session when finished.

Production
* Edit the tools server FQDN and place this into a batch file for ease-of-use for the service desk:
```
cls
powershell.exe -Command "& {$UserName = Read-Host -Prompt """`n`n**** AUTHORIZED USE ONLY  ****`n**** SHIRE SUPPORT CENTER ****`nUser name to find logged in"""; Invoke-Command -ComputerName TOOLS.SERVER.FQDN -ConfigurationName GoateeTools -ScriptBlock {Get-ComputerOfUserDetails -UserName $using:UserName}}"
```
* **NOTE:** Read the `about_Remote_Variables` PowerShell help topic to understand how the special variable prefix `$using` is required here to pass values.


## Some Previous PowerShell Presentation by Ashley McGlone

* 2020 - PowerShell 24 Hour - [Don't Shut Out The Shell](https://www.youtube.com/watch?v=y8SxQokIwiI&t=7s)
* 2019 - PowerShell & DevOps Global Summit - [Hands on Lab: Hunting PowerShell Badness](https://www.youtube.com/watch?v=IXYs-ZON-Zg)
* 2018 - PowerShell & DevOps Global Summit - [Finally! Create, Permission, and Publish an AD CS Certificate Template with PowerShell](https://www.youtube.com/watch?v=1qWF44Plbrk)
* 2017 - `404 Recording Not Found`
* 2016 - PowerShell & DevOps Global Summit - [Active Directory Forensics with PowerShell](https://www.youtube.com/watch?v=VrDjiVbZZE8)
* 2016 - PowerShell & DevOps Global Summit - [Active Directory DSC](https://www.youtube.com/watch?v=hPoE_TsyuX8)
* 2015 - PowerShell & DevOps Global Summit - [PowerShell DSC and Active Directory Better Together (a.k.a. DSC for AD and AD for DSC)](https://www.youtube.com/watch?v=Tgj7hR_eErw)
* 2015 - PowerShell & DevOps Global Summit - [Managing PowerShell in the Enterprise Using Group Policy](https://www.youtube.com/watch?v=NRnGP1RRNsM)
* 2014 - PowerShell Saturday 007 Charlotte - [From Cmdlets to Scripts to PowerShell Hero - Part 1](https://www.youtube.com/watch?v=CSFlys1P5_E)
* 2014 - PowerShell Saturday 007 Charlotte - [From Cmdlets to Scripts to PowerShell Hero - Part 2](https://www.youtube.com/watch?v=vl6QCjK-LfM)
* 2013 - PowerShell Saturday 005 Atlanta - [Moving from command line tools to PowerShell for Active Directory](https://www.youtube.com/watch?v=yTI-kIje3bk)
* [Using PowerShell for Active Directory](https://www.youtube.com/playlist?list=PLIoX3-mcY80jhSJkcfQ2bdv32_LHCt-sA) - Archive of Microsoft Virtual Academy course after the platform was decommissioned
