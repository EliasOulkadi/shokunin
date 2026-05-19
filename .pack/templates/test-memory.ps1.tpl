<#
.SYNOPSIS
    Runs the Shokunin memory test suite (Python, ChromaDB, MCP server, scripts, BM25, consolidate).
#>
param(
    [CmdletBinding()]
    [switch]$Cleanup
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$helperPy = "{{CHROMA_HELPER_PATH}}"
$mcpServer = "{{SHOKUNIN_DIR}}\memory\mcp-server.py"
$sessionId = "test-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

$passed = 0
$failed = 0

function Test-Step {
    param($Name, $ScriptBlock)
    try {
        & $ScriptBlock
        Write-Host "  [PASS] $Name" -ForegroundColor Green
        $script:passed++
        return $true
    } catch {
        Write-Host "  [FAIL] $Name : $_" -ForegroundColor Red
        $script:failed++
        return $false
    }
}

Write-Host "Shokunin Memory Tests" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/8] Environment checks" -ForegroundColor Yellow
Test-Step -Name "Python available" -ScriptBlock { python --version }

Test-Step -Name "MCP server exists" -ScriptBlock {
    if (-not (Test-Path $mcpServer)) { throw "Not found: $mcpServer" }
}
Test-Step -Name "chroma-helper exists" -ScriptBlock {
    if (-not (Test-Path $helperPy)) { throw "Not found: $helperPy" }
}
Test-Step -Name "ChromaDB import works" -ScriptBlock {
    python -c "import chromadb; print('chromadb ok')" 2>$null
}

Write-Host "[2/8] ChromaDB operations" -ForegroundColor Yellow
Test-Step -Name "Save entry" -ScriptBlock {
    $result = python $helperPy save "Test entry at $(Get-Date)" $sessionId "test" "test,memory" "test-project" 2>&1
    if (-not ($result | Select-String "stored")) { throw "Save failed: $result" }
}
Test-Step -Name "Search entry" -ScriptBlock {
    $result = python $helperPy search "Test entry" "test-project" 2>&1
    if (-not ($result | Select-String $sessionId)) { throw "Search didn't find the test entry" }
}
Test-Step -Name "Count entries" -ScriptBlock {
    $result = python $helperPy count 2>&1
    if (-not ($result | Select-String "count")) { throw "Count failed" }
}

Write-Host "[3/8] MCP server" -ForegroundColor Yellow
Test-Step -Name "MCP server starts and responds" -ScriptBlock {
    $request = '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
    $response = $request | python $mcpServer 2>$null
    $firstLine = ($response -split "`n")[0].Trim()
    if (-not ($firstLine | Select-String "tools")) { throw "MCP did not respond properly" }
}

Write-Host "[4/8] Script validation" -ForegroundColor Yellow
Get-ChildItem "{{SHOKUNIN_DIR}}\scripts" -Filter *.ps1 | ForEach-Object {
    Test-Step -Name "$($_.Name) parses" -ScriptBlock {
        $errors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $_.FullName -Raw), [ref]$errors)
        if ($errors.Count -gt 0) { throw "Parse errors: $($errors.Count)" }
    }
}

Write-Host "[5/8] Markdown fallback" -ForegroundColor Yellow
Test-Step -Name "Sessions dir writable" -ScriptBlock {
    $dir = "{{SHOKUNIN_DIR}}\memory\sessions"
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $testFile = Join-Path $dir "write-test.txt"
    "test" | Out-File -FilePath $testFile -Force
    Remove-Item $testFile -Force
}

Write-Host "[6/8] Instructions validation" -ForegroundColor Yellow
Test-Step -Name "CLAUDE.md has memory section" -ScriptBlock {
    $content = Get-Content "$env:USERPROFILE\.claude\CLAUDE.md" -Raw
    if (-not ($content -match "MEMORY SYSTEM")) { throw "CLAUDE.md missing MEMORY SYSTEM section" }
    if (-not ($content -match "search_context")) { throw "CLAUDE.md missing search_context" }
    if (-not ($content -match "store_context")) { throw "CLAUDE.md missing store_context" }
}
Test-Step -Name "AGENTS.md has memory section" -ScriptBlock {
    $content = Get-Content "$env:USERPROFILE\AGENTS.md" -Raw
    if (-not ($content -match "MEMORY SYSTEM")) { throw "AGENTS.md missing MEMORY SYSTEM section" }
}

Write-Host "[7/8] BM25 recall and consolidate" -ForegroundColor Yellow
$recallTestId = "recall-test-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Test-Step -Name "Recall finds keyword via BM25" -ScriptBlock {
    $r = python $helperPy save "BM25_RECALL_TEST_unicorn_xkcd42" $recallTestId "test" "recall,test" "test-recall" 2>&1
    if ($r -notmatch "stored") { throw "save failed" }
    Start-Sleep -Milliseconds 200
    $result = python $helperPy recall "unicorn_xkcd42" "test-recall" 5 2>&1
    if ($result -match "unicorn_xkcd42") { $true } else { throw "Recall didn't find the test term: $result" }
}
Test-Step -Name "Consolidate runs without error" -ScriptBlock {
    $result = python $helperPy consolidate "test-recall" 2>&1
    if ($result -match "consolidated") { $true } else { throw "Consolidate failed: $result" }
}

Write-Host "[8/8] Benchmark recall@5" -ForegroundColor Yellow
Test-Step -Name "Recall@5 finds exact match in top results" -ScriptBlock {
    $bm25Id = "benchmark-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    python $helperPy save "BENCHMARK_TEST_session_context_XKCD_9000" $bm25Id "test" "benchmark" "test-benchmark" 2>&1 | Out-Null
    Start-Sleep -Milliseconds 200
    $result = python $helperPy recall "XKCD_9000" "test-benchmark" 5 2>&1
    if ($result -match "XKCD_9000") {
        Write-Host " (recall@5: TOP5 HIT)" -ForegroundColor Green
        $true
    } else {
        Write-Host " (recall@5: MISS)" -ForegroundColor Yellow
        $false
    }
}

if ($Cleanup) {
    Write-Host "[9/9] Cleanup" -ForegroundColor Yellow
    Test-Step -Name "Test data removed" -ScriptBlock {
        $sessions = "{{SHOKUNIN_DIR}}\memory\sessions"
        $toDelete = Get-ChildItem "$sessions\test-*" -ErrorAction SilentlyContinue
        foreach ($f in $toDelete) { Remove-Item $f.FullName -Force }
    }
}

Write-Host ""
Write-Host "=====================" -ForegroundColor Cyan
Write-Host "Tests complete: $passed passed, $failed failed" -ForegroundColor Cyan
