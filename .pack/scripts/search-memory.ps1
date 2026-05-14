param(
    [string]$Query = "",
    [string]$Project = "",
    [int]$Limit = 5
)

$HELPER = "$env:USERPROFILE\.shokunin\scripts\chroma-helper.py"
$RESULTS = @()

function Add-Result($Source, $Text, $Type, $Session, $Project, $Tags, $Score, $Timestamp) {
    $exists = $RESULTS | Where-Object { $_.Session -eq $Session }
    if (-not $exists) {
        $RESULTS += [PSCustomObject]@{
            Source = $Source; Text = $Text; Type = $Type; Session = $Session
            Project = $Project; Tags = $Tags; Score = $Score; Timestamp = $Timestamp
        }
    }
}

# 1. ChromaDB semantic search
if (-not [string]::IsNullOrEmpty($Query)) {
    try {
        $json = python $HELPER search "$Query" $Project 2>$null
        if ($json) {
            $parsed = $json | ConvertFrom-Json
            foreach ($e in $parsed) {
                Add-Result "ChromaDB" $e.text $e.type $e.session_id $e.project ($e.tags -join ", ") [double]$e.similarity $e.timestamp
            }
        }
    } catch {}
}

# 2. If no results, show recent entries as context
if ($RESULTS.Count -eq 0) {
    try {
        $json = python $HELPER search "session_end OR checkpoint OR decision" "" $Limit 2>$null
        if (-not $json -or $json -eq "[]") { $json = python $HELPER search "shokunin" "" $Limit 2>$null }
        if ($json -and $json -ne "[]") {
            $parsed = $json | ConvertFrom-Json
            foreach ($e in $parsed) {
                Add-Result "Recent" $e.text $e.type $e.session_id $e.project ($e.tags -join ", ") 0 $e.timestamp
            }
        }
    } catch {}
}

$RESULTS = $RESULTS | Sort-Object { if ($_.Source -eq "Recent") { 0 } else { $_.Score } } -Descending | Select-Object -First $Limit

if ($RESULTS.Count -eq 0) {
    Write-Host "No hay datos en memoria aun." -ForegroundColor Yellow
    return
}

Write-Host "Recupere contexto de $($RESULTS.Count) entradas:" -ForegroundColor Cyan
foreach ($r in $RESULTS) {
    $c = if ($r.Source -eq "ChromaDB") { "Green" } else { "DarkGray" }
    Write-Host ""
    Write-Host "[$($r.Source)] $($r.Session)" -ForegroundColor $c
    if ($r.Project) { Write-Host "  Proyecto: $($r.Project)" -ForegroundColor DarkGray }
    if ($r.Tags) { Write-Host "  Tags: $($r.Tags)" -ForegroundColor DarkGray }
    $preview = if ($r.Text.Length -gt 200) { $r.Text.Substring(0, 200) + "..." } else { $r.Text }
    Write-Host "  $preview" -ForegroundColor White
}
