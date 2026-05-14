param([string]$Query, [string]$Project)
$memDir = "$env:USERPROFILE\.shokunin\memory\sessions"
if (!(Test-Path $memDir)) { Write-Host "No hay sesiones guardadas."; return }
if ($Project) { $results = Get-ChildItem "$memDir\*$Project*.md" -ErrorAction SilentlyContinue }
else { $results = Get-ChildItem "$memDir\*.md" -ErrorAction SilentlyContinue }
if (!$results) { Write-Host "No se encontraron resultados."; return }
$total = 0
$results | Sort-Object LastWriteTime -Descending | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $matches = [regex]::Matches($content, $Query, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($matches.Count -gt 0) {
        $preview = $content.Substring(0, [Math]::Min(200, $content.Length))
        Write-Host "`n=== $($_.Name) ($($matches.Count) coincidencias) ==="
        Write-Host $preview
        $total++
    }
}
if ($total -eq 0) { Write-Host "No se encontraron resultados para: $Query" }
