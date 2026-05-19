<#
.SYNOPSIS
    Searches ChromaDB memory via semantic search with keyword fallback, returns top N results.
#>
param(
    [CmdletBinding()]
    [string]$Query = "",
    [string]$Project = "",
    [int]$Limit = 5
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$HELPER = "{{CHROMA_HELPER_PATH}}"
$RESULTS = @()

if (-not [string]::IsNullOrEmpty($Query)) {
    try {
        $json = python $HELPER search "$Query" $Project 2>$null
        if ($json) {
            $parsed = $json | ConvertFrom-Json
            foreach ($e in $parsed) {
                $exists = $RESULTS | Where-Object { $_.Session -eq $e.session_id }
                if (-not $exists) {
                    $obj = New-Object PSObject -Property @{
                        Source = "ChromaDB"
                        Text = $e.text
                        Type = $e.type
                        Session = $e.session_id
                        Project = $e.project
                        Tags = $e.tags -join ", "
                        Score = [double]$e.similarity
                        Timestamp = $e.timestamp
                    }
                    $RESULTS += $obj
                }
            }
        }
    } catch {
        Write-Warning "ChromaDB search failed: $_"
    }
}

if ($RESULTS.Count -eq 0) {
    try {
        $json = python $HELPER recent $Limit 2>$null
        if ($json -and $json -ne "[]") {
            $parsed = $json | ConvertFrom-Json
            foreach ($e in $parsed) {
                $exists = $RESULTS | Where-Object { $_.Session -eq $e.session_id }
                if (-not $exists) {
                    $obj = New-Object PSObject -Property @{
                        Source = "Recent"
                        Text = $e.text
                        Type = $e.type
                        Session = $e.session_id
                        Project = $e.project
                        Tags = $e.tags -join ", "
                        Score = 0.001
                        Timestamp = $e.timestamp
                    }
                    $RESULTS += $obj
                }
            }
        }
    } catch {
        Write-Warning "Recent entries fallback failed: $_"
    }
}

$RESULTS = $RESULTS | Sort-Object Score -Descending | Select-Object -First $Limit

if ($RESULTS.Count -eq 0) {
    Write-Host "No memory data yet." -ForegroundColor Yellow
    return
}

Write-Host "Retrieved context from $($RESULTS.Count) entries:" -ForegroundColor Cyan
foreach ($r in $RESULTS) {
    $c = if ($r.Source -eq "ChromaDB") { "Green" } else { "DarkGray" }
    Write-Host ""
    Write-Host "[$($r.Source)] $($r.Session)" -ForegroundColor $c
    if ($r.Project) { Write-Host "  Project: $($r.Project)" -ForegroundColor DarkGray }
    if ($r.Tags) { Write-Host "  Tags: $($r.Tags)" -ForegroundColor DarkGray }
    $preview = if ($r.Text.Length -gt 200) { $r.Text.Substring(0, 200) + "..." } else { $r.Text }
    Write-Host "  $preview" -ForegroundColor White
}
