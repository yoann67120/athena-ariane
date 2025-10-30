param(
  [string]$Url = "http://localhost:5075/health",   # test sur /health pour l’instant
  [string]$Secret = (Get-Content "C:\Ariane-Agent\Bridge\.env" | Select-String "HMAC_SECRET=" | ForEach-Object { $_.ToString().Split("=")[1].Trim() }),
  [string]$Action = "status",
  [string]$Param = ""
)

function New-HmacSignature {
  param([string]$Secret,[string]$Body,[string]$Timestamp)
  $enc  = [System.Text.Encoding]::UTF8
  $key  = $enc.GetBytes($Secret)
  $msg  = $enc.GetBytes("$Timestamp." + $Body)
  $hmac = [System.Security.Cryptography.HMACSHA256]::new()
  $hmac.Key = $key
  $hash = $hmac.ComputeHash($msg)
  -join ($hash | ForEach-Object { $_.ToString("x2") })
}

$payload = @{ action = $Action; param = $Param } | ConvertTo-Json -Compress
$ts  = [int][double]::Parse((Get-Date -UFormat %s))
$sig = New-HmacSignature -Secret $Secret -Body $payload -Timestamp $ts

Write-Host "→ POST $Url ($Action)"
try {
  $res = Invoke-RestMethod -Uri $Url -Method Get
  $res | ConvertTo-Json -Depth 5
} catch {
  Write-Host "❌ Erreur : $($_.Exception.Message)"
}
