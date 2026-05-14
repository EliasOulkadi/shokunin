param(
    [string]$Query = "",
    [string]$Project = "",
    [int]$Limit = 5
)

$HELPER_PY = "$env:USERPROFILE\.shokunin\scripts\chroma-helper.py"
$SESSION_DIR = "$env:USERPROFILE\.shokunin\memory\sessions"
$RESULTS = @()
$EMPTY_SCORE = 0.5

if ([string]::IsNullOrEmpty($Query)) {
    Write-Host "Usage: search-memory.ps1 -Query 'what you want to find' [-Project 'name'] [-Limit N]" -ForegroundColor Cyan
    return
}

try {
    $json = python $HELPER_PY search "$Query" $Project 2>$null
    if ($json) {
        $parsed = $json | ConvertFrom-Json
        foreach ($entry in $parsed) {
            $RESULTS += [PSCustomObject]@{
                Source = "ChromaDB"
                Text = $entry.text
                Type = $entry.type
                Session = $entry.session_id
                Project = $entry.project
                Tags = $entry.tags -join ", "
                Score = [double]$entry.similarity
                Timestamp = $entry.timestamp
            }
        }
    }
} catch {
    Write-Host "ChromaDB search failed, trying markdown fallback..." -ForegroundColor DarkGray
}

if (Test-Path $SESSION_DIR) {
    $files = Get-ChildItem "$SESSION_DIR\*.md" -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        try {
            $content = Get-Content $file.FullName -Raw
            if ($content -match $Query) {
                $existing = $RESULTS | Where-Object { $_.Session -eq $file.BaseName }
                if (-not $existing) {
                    $firstLine = ($content -split "`n" | Where-Object { $_.Trim() -ne "" } | Select-Object -First 1).Trim()
                    $RESULTS += [PSCustomObject]@{
                        Source = "Markdown"
                        Text = $firstLine
                        Type = ""
                        Session = $file.BaseName
                        Project = ""
                        Tags = ""
                        Score = $EMPTY_SCORE
                        Timestamp = $file.LastWriteTime.ToString("yyyy-MM-ddTHH:mm:ss")
                    }
                }
            }
        } catch {
            Write-Host "  (skipping unreadable: $($file.Name))" -ForegroundColor DarkGray
        }
    }
}

$RESULTS = $RESULTS | Sort-Object Score -Descending | Select-Object -First $Limit

if ($RESULTS.Count -eq 0) {
    Write-Host "No memory results found for: $Query" -ForegroundColor Yellow
    return
}

Write-Host "Found $($RESULTS.Count) results:" -ForegroundColor Cyan
foreach ($r in $RESULTS) {
    $sourceColor = if ($r.Source -eq "ChromaDB") { "Green" } else { "DarkYellow" }
    Write-Host ""
    Write-Host "[$($r.Source)] $($r.Session)" -ForegroundColor $sourceColor
    if ($r.Type) { Write-Host "  Type: $($r.Type)" -ForegroundColor DarkGray }
    if ($r.Tags) { Write-Host "  Tags: $($r.Tags)" -ForegroundColor DarkGray }
    if ($r.Score) { Write-Host "  Score: $($r.Score)" -ForegroundColor DarkGray }
    $preview = $r.Text
    if ($preview.Length -gt 200) { $preview = $preview.Substring(0, 200) + "..." }
    Write-Host "  $preview" -ForegroundColor White
}
