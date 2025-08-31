param(
    [Parameter (Mandatory)][string]$server,
    [Parameter (Mandatory)][string]$user,
    [string]$fingerprint="api user"
)

function Get-Authorization([string]$server,[String]$user,[String]$fingerprint){
    Invoke-RestMethod `
        -SkipCertificateCheck `
        -Method 'POST' `
        -Uri "https://$server/api/ptaf/v4/auth/refresh_tokens" `
        -Headers @{"Content-Type"="application/json"} `
        -Body $(@{ username=$user; password=$(Read-Host "password" -MaskInput); fingerprint=$fingerprint} | ConvertTo-Json)
}

function Get-Auth([string]$server,[String]$refresh_token,[String]$tenant,[String]$fingerprint){
    Invoke-RestMethod `
        -SkipCertificateCheck `
        -Method 'POST' `
        -Uri "https://$server/api/ptaf/v4/auth/access_tokens" `
        -Headers @{"Content-Type"="application/json"} `
        -Body $(@{ refresh_token=$refresh_token; tenant_id=$tenant; fingerprint=$fingerprint} | ConvertTo-Json)
}

function Get-Tenants([string]$server,[String]$token){
    Invoke-RestMethod -Method 'GET' -Uri "https://$server/api/ptaf/v4/auth/tenants" -SkipCertificateCheck -Headers @{"Authorization"="Bearer $token";"Content-Type"="application/json"}
}

function Get-Tenant([string]$server,[String]$token){
    Invoke-RestMethod -Method 'GET' -Uri "https://$server/api/ptaf/v4/auth/current_tenant" -SkipCertificateCheck -Headers @{"Authorization"="Bearer $token";"Content-Type"="application/json"}
}

function Get-Actions([string]$server,[String]$token){
    Invoke-RestMethod -Method 'GET' -Uri "https://$server/api/ptaf/v4/config/actions" -SkipCertificateCheck -Headers @{"Authorization"="Bearer $token";"Content-Type"="application/json"}
}

function Get-Policies([string]$server,[String]$token){
    Invoke-RestMethod -Method 'GET' -Uri "https://$server/api/ptaf/v4/config/policies" -SkipCertificateCheck -Headers @{"Authorization"="Bearer $token";"Content-Type"="application/json"}
}

function Get-Rules([string]$server,[String]$token, [String]$policy){
    Invoke-RestMethod -Method 'GET' -Uri "https://$server/api/ptaf/v4/config/policies/$policy/rules" -SkipCertificateCheck -Headers @{"Authorization"="Bearer $token";"Content-Type"="application/json"}
}

function Get-Rule([string]$server,[String]$token,[String]$policy,[String]$rule){
    Invoke-RestMethod -Method 'GET' -Uri "https://$server/api/ptaf/v4/config/policies/$policy/rules/$rule" -SkipCertificateCheck -Headers @{"Authorization"="Bearer $token";"Content-Type"="application/json"}
}

$tokens=Get-Authorization -server $server -user $user -fingerprint $fingerprint
if($tokens){
    $date=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    $tenants=$(Get-Tenants -server $server -token $tokens.access_token).items
    
    Write-Output $($tenants | ForEach-Object {$index=0} {$_; $index++} | FT -Property @{Label="№";Expression={$index}},id,name,is_active,is_default,administrator,description)
    $tokens=$(Get-Auth -server $server -refresh_token $tokens.refresh_token -tenant $($($tenants[$(Read-Host "select tenant (index)")]).id) -fingerprint $fingerprint)
    $tenant=$(Get-Tenant -server $server -token $tokens.access_token)

    $actions=$(Get-Actions -server $server -token $tokens.access_token).items
    $policies=$(Get-Policies -server $server -token $tokens.access_token).items
    Write-Output $($policies | ForEach-Object {$index=0} {$_; $index++} | FT -Property @{Label="№";Expression={$index}},id,name,type,template_id)
    $policy=$policies[$(Read-Host "select policy (index)")]

    $rules=$(Get-Rules -server $server -token $tokens.access_token -policy $policy.id).items | ForEach-Object {
        Get-Rule -server $server -token $tokens.access_token -policy $policy.id -rule $_.id
    }

    [PSCustomObject]@{
        date=$date
        tenant=$tenant
        policy=$policy
        actions=$actions
        rules=$rules
    } | ConvertTo-JSON -Depth 10 | Out-File "$($policy.id).json"
}
