# --- PATCH UNIVERSAL TIMESTAMP PARSER (UTC COMPATIBLE) ---
try {
    $clientTime = [DateTime]::Parse($payload.timestamp, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AssumeUniversal)
    $serverTime = [DateTime]::UtcNow
    $delta = [Math]::Abs(($serverTime - $clientTime).TotalSeconds)
    if ($delta -gt 300) {
        Write-Host "⏰ Décalage temporel trop grand ($delta s) → rejet." -ForegroundColor Yellow
        return @{ error = "timestamp_out_of_range"; delta = $delta }
    }
} catch {
    Write-Host "⚠️ Erreur lecture timestamp : $_" -ForegroundColor Red
}
# ---------------------------------------------------------
param(
  [Parameter(Mandatory=$true)][string]$Action,
  [string]$Body = "{}",
  [string]$Url = "http://127.0.0.1:5075/bridge",
  [string]$SecretPath = "C:\\Ariane-Agent\\secrets\\bridge_hmac.key"
)

function Get-HmacSignature {
  param([string]$Action,[string]$Json,[string]$Nonce,[long]$Ts,[byte[]]$Key)

  # 🔧 Nettoyage + tri alphabétique des clés JSON pour correspondre à Python
  $parsed = $Json | ConvertFrom-Json
  $ordered = $parsed.PSObject.Properties.Name | Sort-Object | ForEach-Object {
    '"' + $_ + '":' + (ConvertTo-Json $parsed.$_ -Compress)
  }
  $payload = '{' + ($ordered -join ',') + '}'

  # 🔗 Construction du message (identique à Python)
  $message = [System.Text.Encoding]::UTF8.GetBytes("$Action|$Ts|$Nonce|$payload")

  # 🔒 Calcul HMAC SHA256
  $hmac = New-Object System.Security.Cryptography.HMACSHA256
  $hmac.Key = $Key
  $hash = $hmac.ComputeHash($message)
    \ = 300
  ($hash | ForEach-Object { $_.ToString('x2') }) -join ''
}

$key = [System.IO.File]::ReadAllBytes($SecretPath)
$nonce = [guid]::NewGuid().ToString()
$ts = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$signature = Get-HmacSignature -Action $Action -Json $Body -Nonce $nonce -Ts $ts -Key $key

$headers = @{ 'X-HMAC'=$signature; 'X-Nonce'=$nonce; 'X-Timestamp'=$ts }

Write-Host "🔐 Signature : $signature"
Write-Host "🔁 Nonce     : $nonce"

try {
  $resp = Invoke-RestMethod -Uri $Url -Method Post -Headers $headers `
           -Body (@{action=$Action; payload=($Body | ConvertFrom-Json)} | ConvertTo-Json -Depth 10 -Compress) `
           -ContentType 'application/json'
  $resp | ConvertTo-Json -Depth 10
} catch {
  Write-Error $_
}



