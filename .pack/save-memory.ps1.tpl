<#
.SYNOPSIS
    Saves an entry to ChromaDB memory (fallback to markdown file if ChromaDB unavailable).
#>
param(
    [CmdletBinding()]
    [string]$Text,
    [string[]]$Tags = @(),
    [string]$Project = "",
    [string]$SessionId = "",
    [string]$Type = "general"
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$HELPER_PY = "{{CHROMA_HELPER_PATH}}"
$LOG_DIR = "{{SHOKUNIN_DIR}}\memory\sessions"
$MAX_RETRIES = 2

if ([string]::IsNullOrEmpty($SessionId)) {
    $SessionId = "manual-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
}
if ([string]::IsNullOrEmpty($Text)) {
    Write-Host "Nothing to save (empty text)" -ForegroundColor Yellow
    return
}

$tagsStr = ($Tags -join ",")

$saved = $false
for ($attempt = 0; $attempt -le $MAX_RETRIES; $attempt++) {
    try {
        $result = python $HELPER_PY save "$Text" $SessionId $Type $tagsStr $Project 2>&1
        if ($result -match "stored") {
            $saved = $true
            break
        }
    } catch {
        if ($attempt -lt $MAX_RETRIES) { Start-Sleep -Milliseconds 500 }
    }
}

if ($saved) {
    Write-Host "Memory saved (ChromaDB + md)" -ForegroundColor Green
    return
}

try {
    New-Item -ItemType Directory -Path $LOG_DIR -Force | Out-Null
    $file = "$LOG_DIR\manual-$(Get-Date -Format 'yyyy-MM-dd_HHmmss').md"
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
} catch {
    Write-Host "FAILED to save memory: $_" -ForegroundColor Red
}
