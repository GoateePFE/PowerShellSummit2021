cls
powershell.exe -Command "& {$UserName = Read-Host -Prompt """`n`n**** AUTHORIZED USE ONLY  ****`n**** SHIRE SUPPORT CENTER ****`nUser name to find logged in"""; Invoke-Command -ComputerName WS2019-1.goatee.lab -ConfigurationName GoateeTools -ScriptBlock {Get-ComputerOfUserDetails -UserName $using:UserName}}"
