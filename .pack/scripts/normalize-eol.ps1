<#
.SYNOPSIS
    Normalize line endings to LF across the repository.
.DESCRIPTION
    Ensures consistent LF line endings for all text files.
    Skips .git, node_modules, and binary files.
#>
param([string]$Path = ".", [switch]$Check)

$extensions = @("*.md", "*.ps1", "*.sh", "*.py", "*.json", "*.yaml", "*.yml", "*.ts", "*.tsx", "*.js", "*.jsx", "*.css", "*.html")
$changed = 0
$total = 0

Get-ChildItem -Path $Path -Recurse -File | Where-Object {
    $_.Extension -match '\.(md|ps1|sh|py|json|yaml|yml|ts|tsx|js|jsx|css|html)$' -and
    $_.FullName -notmatch 'node_modules|\.git'
} | ForEach-Object {
    $total++
    $content = [System.IO.File]::ReadAllText($_.FullName)
    if ($content.Contains("`r`n")) {
        if (-not $Check) {
            $content = $content -replace "`r`n", "`n"
            [System.IO.File]::WriteAllText($_.FullName, $content, [System.Text.UTF8Encoding]::new($false))
        }
        $changed++
        Write-Host "  $($_.FullName)" -ForegroundColor DarkGray
    }
}

if ($Check) {
    if ($changed -gt 0) {
        Write-Host "FAIL: $changed/$total files have CRLF line endings" -ForegroundColor Red
        exit 1
    }
    Write-Host "PASS: All $total files have LF line endings" -ForegroundColor Green
} else {
    Write-Host "Normalized $changed/$total files to LF" -ForegroundColor $(if($changed -eq 0){'Green'}else{'Yellow'})
}
