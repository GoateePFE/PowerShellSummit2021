cls

Get-WinEvent -LogName Microsoft-Windows-PowerShell/Operational -FilterXPath "*[System[(EventID=4104) and TimeCreated[timediff(@SystemTime) <= 300000]]] or *[System[(EventID=4103) and TimeCreated[timediff(@SystemTime) <= 300000]]]" |
    Where-Object {$_.Message -like "*SecureString*" -and $_.Message -notlike "*Get-WinEvent*" -and $_.Message -notlike "*Message*"} | 
    Select-Object -ExpandProperty Message

Write-Host -ForegroundColor Yellow @'
Get-WinEvent -LogName Microsoft-Windows-PowerShell/Operational -FilterXPath "*[System[(EventID=4104) and TimeCreated[timediff(@SystemTime) <= 300000]]] or *[System[(EventID=4103) and TimeCreated[timediff(@SystemTime) <= 300000]]]" |
    Where-Object {$_.Message -like "*SecureString*" -and $_.Message -notlike "*Get-WinEvent*" -and $_.Message -notlike "*Message*"} | 
    Select-Object -ExpandProperty Message
'@
