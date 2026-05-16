param(
    [Parameter(Mandatory = $true)]
    [string]$Host,

    [Parameter(Mandatory = $false)]
    [int]$Port = 5432,

    [Parameter(Mandatory = $false)]
    [string]$Username = "postgres",

    [Parameter(Mandatory = $false)]
    [string]$Database = "postgres",

    [Parameter(Mandatory = $false)]
    [string]$PsqlPath = "C:\Program Files\PostgreSQL\16\bin\psql.exe",

    [Parameter(Mandatory = $false)]
    [int]$QueryTimeoutSeconds = 30
)

$ErrorActionPreference = "Stop"

function Invoke-PgQuery {
    param([string]$Query)
    $env:PGPASSWORD = $script:plainPwd
    try {
        $result = & $PsqlPath --host=$Host --port=$Port --username=$Username --dbname=$Database --tuples-only --no-align --command=$Query 2>&1
        if ($LASTEXITCODE -ne 0) { throw "psql query failed: $result" }
        return $result.Trim()
    }
    finally {
        $env:PGPASSWORD = $null
    }
}

function New-HealthCheckResult {
    param(
        [string]$Metric,
        [string]$Status,      # pass / warn / fail
        [string]$Value,
        [string]$Threshold,
        [string]$Recommendation
    )
    return [PSCustomObject]@{
        Metric         = $Metric
        Status         = $Status
        Value          = $Value
        Threshold      = $Threshold
        Recommendation = $Recommendation
        Timestamp      = Get-Date -Format "o"
    }
}

# --- Auth ---
$secPwd = Read-Host -Prompt "Enter PostgreSQL password for $Username@$Host" -AsSecureString
$credential = New-Object System.Management.Automation.PSCredential($Username, $secPwd)
$plainPwd = $credential.GetNetworkCredential().Password

$results = [System.Collections.Generic.List[PSObject]]::new()

# --- 1. Connection count ---
$connCount = Invoke-PgQuery "SELECT count(*) FROM pg_stat_activity;"
$maxConn = Invoke-PgQuery "SHOW max_connections;"
$connPct = if ([int]$maxConn -gt 0) { [math]::Round([int]$connCount / [int]$maxConn * 100, 1) } else { 0 }
$connStatus = if ($connPct -ge 90) { "fail" } elseif ($connPct -ge 75) { "warn" } else { "pass" }
$results.Add((New-HealthCheckResult -Metric "Connection Usage" -Status $connStatus -Value "$connCount / $maxConn ($connPct%)" -Threshold "warn >75%, fail >90%" -Recommendation $(if ($connStatus -ne "pass") { "Increase max_connections or add PgBouncer" } else { "OK" })))

# --- 2. Active queries ---
$activeCount = Invoke-PgQuery "SELECT count(*) FROM pg_stat_activity WHERE state = 'active' AND query NOT LIKE '%pg_stat_activity%';"
$activeStatus = if ([int]$activeCount -ge 50) { "fail" } elseif ([int]$activeCount -ge 20) { "warn" } else { "pass" }
$results.Add((New-HealthCheckResult -Metric "Active Queries" -Status $activeStatus -Value "$activeCount" -Threshold "warn >20, fail >50" -Recommendation $(if ($activeStatus -ne "pass") { "Investigate query contention or scale readers" } else { "OK" })))

# --- 3. Long-running queries (>5 min) ---
$longQuery = Invoke-PgQuery @"
SELECT coalesce(count(*), 0)::text
FROM pg_stat_activity
WHERE state = 'active'
  AND now() - pg_stat_activity.query_start > interval '5 minutes'
  AND query NOT LIKE '%pg_stat_activity%';
"@
$longStatus = if ([int]$longQuery -ge 5) { "fail" } elseif ([int]$longQuery -ge 1) { "warn" } else { "pass" }
$results.Add((New-HealthCheckResult -Metric "Long-Running Queries (>5m)" -Status $longStatus -Value "$longQuery" -Threshold "warn >=1, fail >=5" -Recommendation $(if ($longStatus -ne "pass") { "Check pg_stat_activity for blocker queries; consider statement_timeout" } else { "OK" })))

# --- 4. Table bloat estimate ---
$bloatQuery = @"
SELECT
  coalesce(round(sum(pages_mixed), 2), 0)::text AS total_bloat_mb
FROM (
  SELECT
    schemaname,
    tablename,
    (avg_leaf_density - 1) * relpages * 8 / 1024.0 AS pages_mixed
  FROM pg_stat_user_tables
  JOIN pg_class ON relname = tablename AND relnamespace = schemaname::regnamespace
  CROSS JOIN LATERAL (
    SELECT avg_leaf_density
    FROM pg_stat_bgwriter, LATERAL (SELECT 0.9 AS avg_leaf_density) AS density
  ) AS stats
  WHERE avg_leaf_density IS NOT NULL
) AS bloat
HAVING coalesce(round(sum(pages_mixed), 2), 0) > 0;
"@
$bloatMb = Invoke-PgQuery $bloatQuery
$bloatVal = if ($bloatMb -match '^[\d.]+$') { [math]::Round([double]$bloatMb, 1) } else { 0 }
$bloatStatus = if ($bloatVal -ge 1000) { "fail" } elseif ($bloatVal -ge 100) { "warn" } else { "pass" }
$results.Add((New-HealthCheckResult -Metric "Table Bloat Estimate" -Status $bloatStatus -Value "${bloatVal}MB" -Threshold "warn >100MB, fail >1GB" -Recommendation $(if ($bloatStatus -ne "pass") { "Run VACUUM (or VERBOSE ANALYZE); consider pg_repack for severe bloat" } else { "OK" })))

# --- 5. Unused indexes ---
$unusedIdx = Invoke-PgQuery @"
SELECT coalesce(count(*), 0)::text
FROM pg_stat_user_indexes
JOIN pg_index USING (indexrelid)
WHERE idx_scan = 0
  AND NOT indisunique
  AND NOT indisprimary;
"@
$unusedVal = [int]$unusedIdx
$unusedStatus = if ($unusedVal -ge 20) { "fail" } elseif ($unusedVal -ge 5) { "warn" } else { "pass" }
$results.Add((New-HealthCheckResult -Metric "Unused Indexes" -Status $unusedStatus -Value "$unusedVal" -Threshold "warn >=5, fail >=20" -Recommendation $(if ($unusedStatus -ne "pass") { "Review and DROP unused indexes to reduce write overhead" } else { "OK" })))

# --- 6. Cache hit ratio ---
$cacheHit = Invoke-PgQuery @"
SELECT round(coalesce(blks_hit::numeric / nullif(blks_hit + blks_read, 0) * 100, 0), 2)::text
FROM pg_stat_database
WHERE datname = current_database();
"@
$cacheHitVal = if ($cacheHit -match '^[\d.]+$') { [double]$cacheHit } else { 0 }
$cacheStatus = if ($cacheHitVal -lt 95) { "fail" } elseif ($cacheHitVal -lt 99) { "warn" } else { "pass" }
$results.Add((New-HealthCheckResult -Metric "Cache Hit Ratio (shared_buffers)" -Status $cacheStatus -Value "${cacheHitVal}%" -Threshold "warn <99%, fail <95%" -Recommendation $(if ($cacheStatus -ne "pass") { "Increase shared_buffers or optimize query patterns" } else { "OK" })))

# --- 7. Dead tuple percentage ---
$deadTup = Invoke-PgQuery @"
SELECT round(coalesce(sum(n_dead_tup)::numeric / nullif(sum(n_live_tup + n_dead_tup), 0) * 100, 0), 2)::text
FROM pg_stat_user_tables;
"@
$deadTupVal = if ($deadTup -match '^[\d.]+$') { [double]$deadTup } else { 0 }
$deadStatus = if ($deadTupVal -ge 50) { "fail" } elseif ($deadTupVal -ge 20) { "warn" } else { "pass" }
$results.Add((New-HealthCheckResult -Metric "Dead Tuple Ratio" -Status $deadStatus -Value "${deadTupVal}%" -Threshold "warn >20%, fail >50%" -Recommendation $(if ($deadStatus -ne "pass") { "Tune autovacuum: lower autovacuum_vacuum_scale_factor, increase autovacuum_naptime" } else { "OK" })))

# --- Output ---
$report = [PSCustomObject]@{
    Server     = "$Host`:$Port"
    Database   = $Database
    Timestamp  = Get-Date -Format "o"
    Summary    = [PSCustomObject]@{
        TotalChecks = $results.Count
        Passed      = ($results | Where-Object { $_.Status -eq "pass" }).Count
        Warnings    = ($results | Where-Object { $_.Status -eq "warn" }).Count
        Failures    = ($results | Where-Object { $_.Status -eq "fail" }).Count
    }
    Checks     = $results
}

$reportJson = $report | ConvertTo-Json -Depth 3
Write-Host "`n=== PostgreSQL Health Report ===" -ForegroundColor Cyan
$results | Format-Table -Property Metric, Status, Value, Recommendation -AutoSize | Out-Host

if ($report.Summary.Failures -gt 0) {
    Write-Host "HEALTH: FAIL ($($report.Summary.Failures) checks failing)" -ForegroundColor Red
    exit 2
}
if ($report.Summary.Warnings -gt 0) {
    Write-Host "HEALTH: WARN ($($report.Summary.Warnings) checks warning)" -ForegroundColor Yellow
    exit 1
}
Write-Host "HEALTH: PASS" -ForegroundColor Green
exit 0
