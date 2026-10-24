$uri = "http://127.0.0.1:64778/Wcd2wPRc4W8=/"
$vmBody = '{"jsonrpc":"2.0","id":"1","method":"getVM"}'
$vmRes = Invoke-RestMethod -Uri $uri -Method Post -Body $vmBody -ContentType "application/json"
$isolateId = $vmRes.result.isolates[0].id
Write-Output "IsolateId: $isolateId"

$reassembleBody = "{`"jsonrpc`":`"2.0`",`"id`":`"2`",`"method`":`"ext.flutter.reassemble`",`"params`":{`"isolateId`":`"$isolateId`"}}"
$res = Invoke-RestMethod -Uri $uri -Method Post -Body $reassembleBody -ContentType "application/json"
Write-Output "Reassemble response: $($res | ConvertTo-Json -Compress)"
