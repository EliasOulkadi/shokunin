param(
    [string]$Text,
    [string[]]$Tags = @(),
    [string]$Project = "",
    [string]$SessionId = "",
    [string]$Type = "general"
)

$helperPy = "$env:USERPROFILE\.shokunin\scripts\chroma-helper.py"

if ([string]::IsNullOrEmpty($SessionId)) {
    $SessionId = "manual-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
}

$tagsStr = ($Tags -join ",")

try {
    $result = python $helperPy save "$Text" $SessionId $Type $tagsStr $Project 2>&1
    Write-Host "Memory saved (ChromaDB + md)" -ForegroundColor Green
} catch {
    $logDir = "$env:USERPROFILE\.shokunin\memory\sessions"
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    $file = "$logDir\manual-$(Get-Date -Format 'yyyy-MM-dd_HHmmss').md"
    $content = @"
# Session: $SessionId
- Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
- Type: $Type
- Project: $Project
- Tags: $($Tags -join ', ')

$Text
"@
    $content | Out-File -FilePath $file -Encoding UTF8
    Write-Host "Saved to: $file" -ForegroundColor Yellow
}
