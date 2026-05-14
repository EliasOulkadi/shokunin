param([string]$RawText, [string]$SessionId)

function Strip-ANSI {
    param([string]$Text)
    # Remove ANSI escape sequences using regex
    $Text = $Text -replace '\x1B\[[0-9;]*[a-zA-Z]', ''
    $Text = $Text -replace '\x1B\][0-9;]*[a-zA-Z]', ''
    return $Text.Replace("`r`n", "`n")
}

$cleanText = Strip-ANSI -Text $RawText
$allLines = $cleanText.Split("`n")
$lines = @()
foreach ($line in $allLines) {
    if ($line.Trim().Length -gt 0) {
        $lines += $line
    }
}

$sections = @()
$buffer = New-Object System.Collections.ArrayList

foreach ($line in $lines) {
    [void]$buffer.Add($line.Trim())
}

if ($buffer.Count -gt 0) {
    $sections += $buffer -join " "
}

$decisions = @()
$commands = @()

foreach ($s in $sections) {
    if ($s.Length -gt 20) {
        if ($s -like "*decid*" -or $s -like "*usar*" -or $s -like "*cre*" -or $s -like "*implement*") {
            $trunc = $s.Substring(0, [Math]::Min(200, $s.Length))
            $decisions += $trunc
        }
        $matchResult = [regex]::Match($s, "(npm|pip|git|docker|python|node) ")
        if ($matchResult.Success) {
            $trunc = $s.Substring(0, [Math]::Min(100, $s.Length))
            $commands += $trunc
        }
    }
}

$decisions = $decisions | Select-Object -Unique | Select-Object -First 5
$commands = $commands | Select-Object -Unique | Select-Object -First 10

$today = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$output = "# Session: $SessionId`n- Date: $today`n`n"

if ($decisions.Count -gt 0) {
    $output += "## Decisions`n"
    foreach ($d in $decisions) { $output += "- $d`n" }
    $output += "`n"
}
if ($commands.Count -gt 0) {
    $output += "## Commands`n"
    foreach ($c in $commands) { $output += "- $c`n" }
    $output += "`n"
}
$output += "## Conversation Log`n"
foreach ($s in $sections) { $output += "> $s`n" }

$outputPath = "$env:USERPROFILE\.shokunin\memory\sessions\$SessionId-parsed.md"
$output | Out-File -FilePath $outputPath -Encoding UTF8

return $output
