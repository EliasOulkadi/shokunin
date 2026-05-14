param(
    [string]$Query = "",
    [string]$Project = "",
    [int]$Limit = 5
)

$HELPER = "$env:USERPROFILE\.shokunin\scripts\chroma-helper.py"
$RESULTS = @()

# 1. Try ChromaDB semantic search
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
    } catch {}
}

# 2. Fallback to recent entries if nothing found
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
                        Score = 0
                        Timestamp = $e.timestamp
                    }
                    $RESULTS += $obj
                }
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
