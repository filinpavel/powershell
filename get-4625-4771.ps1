$dcs = (get-addomaincontroller -Filter * -Server ((Get-ADDomain).dnsroot)).name 
$xml = @"
<QueryList>
  <Query Id="0" Path="Security">
    <Select Path="Security">*[System[(EventID=4625 or EventID=4771)]]</Select>
  </Query>
</QueryList>
"@
foreach ($dc in $dcs) {
    try {
        get-winevent -computername $dc -FilterXml $xml -MaxEvents 3
    }
    catch [NoMatchingEventsFound]{
        Write-Host "No Events on $dc"
    }
    get-winevent -computername $dc -FilterXml $xml -MaxEvents 3
}