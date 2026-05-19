<#
.SYNOPSIS
    Runs a full healthcheck for the Shokunin memory system (Python, ChromaDB, MCP, scripts, config).
#>
param(
    [CmdletBinding()]
    [switch]$CI
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$PASS = 0
$FAIL = 0
$WARN = 0

function Check {
    param($Name, $ScriptBlock)
    try {
        & $ScriptBlock
        Write-Host "  PASS  $Name" -ForegroundColor Green
        $script:PASS++
        return $true
    } catch {
        Write-Host "  FAIL  $Name : $_" -ForegroundColor Red
        $script:FAIL++
        return $false
    }
}

function Warn {
    param($Name, $Message)
    Write-Host "  WARN  $Name : $Message" -ForegroundColor Yellow
    $script:WARN++
}

Write-Host "`nShokunin Memory Healthcheck" -ForegroundColor Cyan
Write-Host "==========================================`n" -ForegroundColor Cyan

Write-Host "[Environment]" -ForegroundColor Yellow
Check -Name "Python available" -ScriptBlock { python --version 2>&1 | Out-Null }

Check -Name "chromadb importable" -ScriptBlock {
    python -c "import chromadb; print('ok')" 2>&1
}

Check -Name "Data directory exists" -ScriptBlock {
    if (-not (Test-Path "{{SHOKUNIN_DIR}}\memory")) { throw "memory dir not found" }
}

Write-Host "[chroma-helper]" -ForegroundColor Yellow
$testId = "healthcheck-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Check -Name "save entry" -ScriptBlock {
    $r = python "{{CHROMA_HELPER_PATH}}" save "Healthcheck test" $testId "test" "healthcheck" "healthcheck" 2>&1
    if ($r -notmatch "stored") { throw "save failed: $r" }
}
Check -Name "search entry" -ScriptBlock {
    $r = python "{{CHROMA_HELPER_PATH}}" search "Healthcheck test" "healthcheck" 100 2>&1
    if ($r -match $testId) { $true } else { throw "search didn't find test entry" }
}
Check -Name "count entries" -ScriptBlock {
    $r = python "{{CHROMA_HELPER_PATH}}" count 2>&1
    if ($r -notmatch "count") { throw "count failed" }
}

Write-Host "[MCP Server]" -ForegroundColor Yellow
Check -Name "tools/list responds" -ScriptBlock {
    $req = '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
    $resp = $req | python "{{SHOKUNIN_DIR}}\memory\mcp-server.py" 2>&1
    if ($resp -notmatch "store_context") { throw "MCP did not list tools" }
}

Check -Name "store via MCP" -ScriptBlock {
    $sid = "mcp-test-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    $req = '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"store_context","arguments":{"text":"MCP healthcheck","session_id":"' + $sid + '","type":"test","tags":["healthcheck"]}}}'
    $resp = $req | python "{{SHOKUNIN_DIR}}\memory\mcp-server.py" 2>&1
    if ($resp -notmatch "stored") { throw "MCP store failed" }
}

Check -Name "search via MCP" -ScriptBlock {
    $req = '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"search_context","arguments":{"query":"MCP healthcheck"}}}'
    $resp = $req | python "{{SHOKUNIN_DIR}}\memory\mcp-server.py" 2>&1
    if ($resp -notmatch "mcp-test" -or $resp.Length -lt 50) { throw "MCP search returned empty" }
}

Write-Host "[Script Syntax]" -ForegroundColor Yellow
Get-ChildItem "{{SHOKUNIN_DIR}}\scripts" -Filter *.ps1 | ForEach-Object {
    Check -Name "$($_.Name) parses" -ScriptBlock {
        $e = $null
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $_.FullName -Raw), [ref]$e)
        if ($e.Count -gt 0) { throw "$($e.Count) parse errors" }
    }
}

Write-Host "[Configuration]" -ForegroundColor Yellow
Check -Name "opencode.json valid JSON" -ScriptBlock {
    $j = Get-Content "$env:USERPROFILE\.config\opencode\opencode.json" -Raw | ConvertFrom-Json
    if (-not $j.mcp.memory) { throw "missing memory MCP" }
}

Check -Name "CLAUDE.md has memory section" -ScriptBlock {
    $cm = Get-Content "$env:USERPROFILE\.claude\CLAUDE.md" -Raw
    if ($cm -notmatch "MEMORY SYSTEM") { throw "missing MEMORY SYSTEM section" }
    if ($cm -notmatch "SHOKUNIN_SESSION_ID") { throw "missing env var docs" }
}

Check -Name "AGENTS.md has memory section" -ScriptBlock {
    $am = Get-Content "$env:USERPROFILE\AGENTS.md" -Raw
    if ($am -notmatch "MEMORY SYSTEM") { throw "missing MEMORY SYSTEM section" }
}

Write-Host "[Storage]" -ForegroundColor Yellow
Check -Name "sessions dir writable" -ScriptBlock {
    $d = "{{SHOKUNIN_DIR}}\memory\sessions"
    New-Item -ItemType Directory -Path $d -Force | Out-Null
    "test" | Out-File -FilePath "$d\.write-test" -Force
    Remove-Item "$d\.write-test" -Force
}

Check -Name "current-session.json exists" -ScriptBlock {
    if (-not (Test-Path "{{SHOKUNIN_DIR}}\current-session.json")) { throw "not found" }
}

Write-Host "[Cleanup]" -ForegroundColor Yellow
Check -Name "Remove test entries" -ScriptBlock {
    $h = "{{CHROMA_HELPER_PATH}}"
    $r = python $h search "Healthcheck test" "healthcheck" 100 2>&1
    if ($r -match '"session_id":') {
        python $h delete "healthcheck" 2>&1 | Out-Null
    }
    $s = "{{SHOKUNIN_DIR}}\memory\sessions"
    Get-ChildItem "$s\healthcheck-*" -ErrorAction SilentlyContinue | Remove-Item -Force
    Get-ChildItem "$s\mcp-test-*" -ErrorAction SilentlyContinue | Remove-Item -Force
    $true
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
if ($FAIL -eq 0) {
    Write-Host "  ALL PASSED ($PASS passed, $WARN warnings)" -ForegroundColor Green
    if ($CI) { exit 0 }
} else {
    Write-Host "  $FAIL FAILED, $PASS passed, $WARN warnings" -ForegroundColor Red
    if ($CI) { exit 1 }
}
Write-Host "==========================================" -ForegroundColor Cyan
