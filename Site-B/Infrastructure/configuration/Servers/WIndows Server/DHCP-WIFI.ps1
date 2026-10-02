# Executer localement sur Windows DHCP 172.16.1.131, dans une console elevee.
# Cree une etendue INACTIVE ; ne supprime pas l'ancienne etendue automatiquement.
#Requires -Modules DhcpServer
$ErrorActionPreference = 'Stop'
$siteBScope = '172.16.1.64'
$siteBExistingScopes = @(Get-DhcpServerv4Scope -ErrorAction Stop)
if ($siteBExistingScopes | Where-Object { $_.ScopeId.ToString() -eq $siteBScope }) {
    throw "L'etendue Site B existe deja : comparer et sauvegarder avant modification."
}
Add-DhcpServerv4Scope -Name 'SITE-B-WIFI' -StartRange '172.16.1.67' -EndRange '172.16.1.94' -SubnetMask '255.255.255.224' -LeaseDuration ([TimeSpan]::FromHours(8)) -State InActive
Set-DhcpServerv4OptionValue -ScopeId $siteBScope -Router '172.16.1.65' -DnsServer '172.16.1.131'
# Option DNS domain : renseigner le domaine reel si requis, pas une valeur fictive.
# Apres retrait de l'ancienne etendue et verification AP1 .66 / relais SW1 .65 :
# Set-DhcpServerv4Scope -ScopeId '172.16.1.64' -State Active
