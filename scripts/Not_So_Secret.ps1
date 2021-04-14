

$pw = ConvertTo-SecureString -String 'B!g_N0_N0' -AsPlainText -Force
$un = 'frodo'
$cred = New-Object -TypeName PSCredential -ArgumentList $un,$pw

$pw = $cred.GetNetworkCredential().Password

$Headers = @{
    Authorization='Bearer 0M0y0S0u0p0e0r0S0e0c0r0e0t0A0P0I0K0e0y0'
    Content = 'application/json'
}

<# Call commented out so that it does not pass an invalid API key
$APIData = Invoke-RestMethod -Method Get `
    -Uri "https://the-one-api.dev/v2/character" `
    -Headers $Headers
#>

For ($i=1; $i -lt 6000; $i++){
    Start-Sleep -Seconds 1
}
