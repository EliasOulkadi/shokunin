param(
    [string]$Query = "",
    [string]$Project = "",
    [int]$Limit = 5
)

$helperPy = "$env:USERPROFILE\.shokunin\scripts\chroma-helper.py"
$sessionDir = "$env:USERPROFILE\.shokunin\memory\sessions"

$results = @()

if ($Query -ne "") {
    try {
        $json = python $helperPy search "$Query" $Project 2>$null
        if ($json) {
            $parsed = $json | ConvertFrom-Json
            foreach ($entry in $parsed) {
                $results += [PSCustomObject]@{
                    Source = "ChromaDB"
                    Text = $entry.text
                    Type = $entry.type
                    Session = $entry.session_id
                    Project = $entry.project
                    Tags = $entry.tags -join ", "
                    Score = $entry.similarity
                    Timestamp = $entry.timestamp
                }
            }
        }
    } catch {}
}

if (Test-Path $sessionDir) {
    $files = Get-ChildItem "$sessionDir\*.md" -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        $content = Get-Content $file.FullName -Raw
        if ($Query -ne "" -and $content -match $Query) {
            $exists = $results | Where-Object { $_.Session -eq $file.BaseName }
            if (-not $exists) {
                $lines = $content -split "`n"
                $firstLine = ($lines | Where-Object { $_.Trim() -ne "" } | Select-Object -First 1).Trim()
                $results += [PSCustomObject]@{
                    Source = "Markdown"
                    Text = $firstLine
                    Type = ""
                    Session = $file.BaseName
                    Project = ""
                    Tags = ""
                    Score = 0.5
                    Timestamp = $file.LastWriteTime.ToString("yyyy-MM-ddTHH:mm:ss")
                }
            }
        }
    }
}

$results = $results | Sort-Object Score -Descending | Select-Object -First $Limit

if ($results.Count -eq 0) {
    Write-Host "No memory results found." -ForegroundColor Yellow
} else {
    Write-Host "Found $($results.Count) results:" -ForegroundColor Cyan
    foreach ($r in $results) {
        $sourceColor = if ($r.Source -eq "ChromaDB") { "Green" } else { "DarkYellow" }
        Write-Host ""
        Write-Host "[$($r.Source)] $($r.Session)" -ForegroundColor $sourceColor
        if ($r.Type) { Write-Host "  Type: $($r.Type)" -ForegroundColor DarkGray }
        if ($r.Tags) { Write-Host "  Tags: $($r.Tags)" -ForegroundColor DarkGray }
        $preview = $r.Text
        if ($preview.Length -gt 200) { $preview = $preview.Substring(0, 200) + "..." }
        Write-Host "  $preview" -ForegroundColor White
    }
}
