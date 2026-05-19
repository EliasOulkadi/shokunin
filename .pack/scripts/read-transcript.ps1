<#
.SYNOPSIS
    Parses a raw session transcript and extracts decisions, commands, and conversation log to markdown.
#>
param(
    [CmdletBinding()]
    [string]$RawText,
    [string]$SessionId
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$MAX_PREVIEW_LENGTH = 200
$MAX_COMMAND_LENGTH = 100

function Strip-ANSI {
    param([string]$Text)
    $Text = $Text -replace '\x1B\[[0-9;]*[a-zA-Z]', ''
    $Text = $Text -replace '\x1B\][0-9;]*[a-zA-Z]', ''
    return $Text.Replace("`r`n", "`n")
}

function Get-SessionDate {
    Get-Date -Format "yyyy-MM-dd HH:mm:ss"
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
    if ($s.Length -le 20) { continue }
    $lower = $s.ToLower()
    if (($lower -like "*decid*" -or $lower -like "*implement*") -and ($lower -notlike "*create*" -or $lower -like "*decided*")) {
        $trunc = $s.Substring(0, [Math]::Min($MAX_PREVIEW_LENGTH, $s.Length))
        $decisions += $trunc
    }
    $matchResult = [regex]::Match($s, "(npm|npx|pip|git|docker|python|python3|node|yarn|cargo|go) ")
    if ($matchResult.Success) {
        $trunc = $s.Substring(0, [Math]::Min($MAX_COMMAND_LENGTH, $s.Length))
        $commands += $trunc
    }
}

$decisions = $decisions | Select-Object -Unique | Select-Object -First 5
$commands = $commands | Select-Object -Unique | Select-Object -First 10

$today = Get-SessionDate
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
