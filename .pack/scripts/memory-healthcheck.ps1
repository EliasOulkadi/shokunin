param([switch]$CI)

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

# 1. Environment
Write-Host "[Environment]" -ForegroundColor Yellow
Check -Name "Python available" -ScriptBlock { python --version 2>&1 | Out-Null }

Check -Name "chromadb importable" -ScriptBlock {
    python -c "import chromadb; print('ok')" 2>&1
}

Check -Name "Data directory exists" -ScriptBlock {
    if (-not (Test-Path "$env:USERPROFILE\.shokunin\memory")) { throw "memory dir not found" }
}

# 2. chroma-helper
Write-Host "[chroma-helper]" -ForegroundColor Yellow
$testId = "healthcheck-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Check -Name "save entry" -ScriptBlock {
    $r = python "$env:USERPROFILE\.shokunin\scripts\chroma-helper.py" save "Healthcheck test" $testId "test" "healthcheck" "healthcheck" 2>&1
    if ($r -notmatch "stored") { throw "save failed: $r" }
}
Check -Name "search entry" -ScriptBlock {
    $r = python "$env:USERPROFILE\.shokunin\scripts\chroma-helper.py" search "Healthcheck test" "healthcheck" 100 2>&1
    if ($r -match $testId) { $true } else { throw "search didn't find test entry" }
}
Check -Name "count entries" -ScriptBlock {
    $r = python "$env:USERPROFILE\.shokunin\scripts\chroma-helper.py" count 2>&1
    if ($r -notmatch "count") { throw "count failed" }
}

# 3. MCP Server
Write-Host "[MCP Server]" -ForegroundColor Yellow
Check -Name "tools/list responds" -ScriptBlock {
    $req = '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
    $resp = $req | python "$env:USERPROFILE\.shokunin\memory\mcp-server.py" 2>&1
    if ($resp -notmatch "store_context") { throw "MCP did not list tools" }
}

Check -Name "store via MCP" -ScriptBlock {
    $sid = "mcp-test-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    $req = '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"store_context","arguments":{"text":"MCP healthcheck","session_id":"' + $sid + '","type":"test","tags":["healthcheck"]}}}'
    $resp = $req | python "$env:USERPROFILE\.shokunin\memory\mcp-server.py" 2>&1
    if ($resp -notmatch "stored") { throw "MCP store failed" }
}

Check -Name "search via MCP" -ScriptBlock {
    $req = '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"search_context","arguments":{"query":"MCP healthcheck"}}}'
    $resp = $req | python "$env:USERPROFILE\.shokunin\memory\mcp-server.py" 2>&1
    if ($resp -notmatch "mcp-test" -or $resp.Length -lt 50) { throw "MCP search returned empty" }
}

# 4. Script syntax
Write-Host "[Script Syntax]" -ForegroundColor Yellow
Get-ChildItem "$env:USERPROFILE\.shokunin\scripts" -Filter *.ps1 | ForEach-Object {
    Check -Name "$($_.Name) parses" -ScriptBlock {
        $e = $null
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $_.FullName -Raw), [ref]$e)
        if ($e.Count -gt 0) { throw "$($e.Count) parse errors" }
    }
}

# 5. Config validation
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

# 6. Session storage
Write-Host "[Storage]" -ForegroundColor Yellow
Check -Name "sessions dir writable" -ScriptBlock {
    $d = "$env:USERPROFILE\.shokunin\memory\sessions"
    New-Item -ItemType Directory -Path $d -Force | Out-Null
    "test" | Out-File -FilePath "$d\.write-test" -Force
    Remove-Item "$d\.write-test" -Force
}

Check -Name "current-session.json writable" -ScriptBlock {
    $info = @{ test = $true } | ConvertTo-Json
    $info | Out-File -FilePath "$env:USERPROFILE\.shokunin\current-session.json" -Encoding UTF8 -Force
}

# Summary
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
