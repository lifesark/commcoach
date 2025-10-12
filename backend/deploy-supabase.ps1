# CommCoach Backend - Supabase Deployment Script (Windows PowerShell)
# Robust, fail-fast, PS 5.1 compatible.

[CmdletBinding()]
param(
  [switch]$SkipConnectivityChecks
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Fail($m) { Write-Host "ERROR: $m" -ForegroundColor Red; exit 1 }
function Step($m) { Write-Host ">> $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "OK: $m" -ForegroundColor Green }
function Info($m) { Write-Host "$m" -ForegroundColor Gray }

Write-Host 'Deploying CommCoach Backend to Supabase...' -ForegroundColor Green

# 1) Ensure backend\.env exists
if (-not (Test-Path 'backend\.env')) {
  Write-Host 'ERROR: backend\.env file not found!' -ForegroundColor Red
  Write-Host 'Please create backend\.env with your Supabase credentials' -ForegroundColor Yellow
  Write-Host 'See backend\env.example for reference' -ForegroundColor Yellow
  exit 1
}

# 2) Load .env (supports quoted values and values containing '=')
Step "Loading environment variables"
$envLines = Get-Content 'backend\.env' | Where-Object { $_ -notmatch '^\s*#' -and $_.Trim() -ne '' }
foreach ($line in $envLines) {
  if ($line -match '^\s*([^=\s]+)\s*=\s*(.*)\s*$') {
    $name  = $matches[1].Trim()
    $value = $matches[2]
    if ($value -match '^\s*"(.*)"\s*$') { $value = $matches[1] }
    elseif ($value -match "^\s*'(.*)'\s*$") { $value = $matches[1] }
    [Environment]::SetEnvironmentVariable($name, $value, 'Process')
  }
}
Ok "Environment variables loaded"

# 3) Validate required variables
$requiredVars = @('SUPABASE_URL','SUPABASE_ANON_KEY','SUPABASE_SERVICE_ROLE_KEY','DATABASE_URL','GEMINI_API_KEY')
$missing = @()
foreach ($var in $requiredVars) {
  if (-not [Environment]::GetEnvironmentVariable($var, 'Process')) { $missing += $var }
}
if ($missing.Count) { Fail ("Missing variables in backend\.env: " + ($missing -join ', ')) }

# 4) Ensure sslmode on DATABASE_URL; parse host:port; warn if direct DB host
$DATABASE_URL = $env:DATABASE_URL
if ($DATABASE_URL -notmatch 'sslmode=') {
  if ($DATABASE_URL -match '\?') {
    $DATABASE_URL = "${DATABASE_URL}&sslmode=require"
  } else {
    $DATABASE_URL = "${DATABASE_URL}?sslmode=require"
  }
  [Environment]::SetEnvironmentVariable('DATABASE_URL', $DATABASE_URL, 'Process')
  Info "Appended sslmode=require to DATABASE_URL"
}

function Parse-DbHostPort([string]$Url) {
  if ($Url -notmatch '^[a-z0-9+]+://') { return @{Host=$null;Port=$null} }
  $noScheme = $Url -replace '^[a-z0-9+]+://',''
  $afterAt  = ($noScheme -split '@',2)[-1]
  $hostPort = ($afterAt -split '/',2)[0]
  if ($hostPort -match '^\[([^\]]+)\]:(\d+)$') { return @{Host=$matches[1];Port=[int]$matches[2]} }
  elseif ($hostPort -match '^([^:]+):(\d+)$')   { return @{Host=$matches[1];Port=[int]$matches[2]} }
  else { return @{Host=$hostPort;Port=5432} }
}

$hp = Parse-DbHostPort $DATABASE_URL
$DB_HOST = $hp.Host
$DB_PORT = $hp.Port

if ($DB_HOST -like 'db.*.supabase.co') {
  Write-Host "WARNING: Detected direct Supabase DB host (${DB_HOST})." -ForegroundColor Yellow
  Write-Host "         If you see IPv6/DNS issues, switch to the pooler:" -ForegroundColor Yellow
  Write-Host "         postgresql+psycopg2://postgres.<PROJECT_REF>:<DB_PASSWORD>@aws-0-<REGION>.pooler.supabase.com:5432/postgres?sslmode=require" -ForegroundColor DarkYellow
}

# 5) Optional connectivity checks (simplified: TCP only)
if (-not $SkipConnectivityChecks -and $DB_HOST) {
  Step ("Checking DB TCP reachability: {0}:{1}" -f $DB_HOST, $DB_PORT)
  try {
    $tnc = Test-NetConnection -ComputerName $DB_HOST -Port $DB_PORT -WarningAction SilentlyContinue
    if (-not $tnc.TcpTestSucceeded) {
      Fail ("Cannot reach {0}:{1}" -f $DB_HOST, $DB_PORT)
    }
    Ok "DB endpoint reachable"
  } catch {
    Fail ("Connectivity check failed: {0}" -f $_.Exception.Message)
  }
}



# 6) Run Alembic migrations (once, fail-fast), with safe path restore
Step "Running database migrations"
Push-Location backend
try {
  & alembic upgrade head
  if ($LASTEXITCODE -ne 0) { throw ("Alembic exited with code {0}" -f $LASTEXITCODE) }
  Ok "Database migrations completed"
} catch {
  Fail ("Alembic failed: {0}" -f $_.Exception.Message)
} finally {
  Pop-Location
}

# 7) Build & start with Docker Compose
Step "Building and starting containers"
& docker-compose -f docker-compose.supabase.yml up --build -d
if ($LASTEXITCODE -ne 0) { Fail ("docker-compose exited with code {0}" -f $LASTEXITCODE) }

Ok "Deployment completed!"
""
Write-Host 'Your API is running at: http://localhost:8000' -ForegroundColor Cyan
Write-Host 'API Documentation:  http://localhost:8000/docs' -ForegroundColor Cyan
Write-Host 'Health Check:      http://localhost:8000/health' -ForegroundColor Cyan
""
Write-Host 'To view logs: docker-compose -f docker-compose.supabase.yml logs -f' -ForegroundColor Yellow
Write-Host 'To stop:      docker-compose -f docker-compose.supabase.yml down' -ForegroundColor Yellow
