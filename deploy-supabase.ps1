# CommCoach Backend - Supabase Deployment Script (Windows PowerShell)

Write-Host '🚀 Deploying CommCoach Backend to Supabase...' -ForegroundColor Green

# Check if .env file exists
if (-not (Test-Path 'backend\.env')) {
    Write-Host '❌ Error: backend\.env file not found!' -ForegroundColor Red
    Write-Host 'Please create backend\.env with your Supabase credentials' -ForegroundColor Yellow
    Write-Host 'See backend\env.example for reference' -ForegroundColor Yellow
    exit 1
}

# Load environment variables from .env file
$envContent = Get-Content 'backend\.env' | Where-Object { $_ -notmatch '^#' -and $_ -ne '' }
foreach ($line in $envContent) {
    if ($line -match '^([^=]+)=(.*)$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        [Environment]::SetEnvironmentVariable($name, $value, 'Process')
    }
}

# Check required environment variables
$requiredVars = @('SUPABASE_URL', 'SUPABASE_ANON_KEY', 'SUPABASE_SERVICE_ROLE_KEY', 'DATABASE_URL', 'GEMINI_API_KEY')
foreach ($var in $requiredVars) {
    if (-not [Environment]::GetEnvironmentVariable($var, 'Process')) {
        Write-Host "❌ Error: $var is not set in backend\.env" -ForegroundColor Red
        exit 1
    }
}

Write-Host '✅ Environment variables loaded' -ForegroundColor Green

# Run database migrations
Write-Host '📊 Running database migrations...' -ForegroundColor Blue
Set-Location backend
alembic upgrade head
Write-Host '✅ Database migrations completed' -ForegroundColor Green

# Build and run with Docker Compose
Write-Host '🐳 Building and starting containers...' -ForegroundColor Blue
Set-Location ..
docker-compose -f docker-compose.supabase.yml up --build -d

Write-Host '✅ Deployment completed!' -ForegroundColor Green
Write-Host ''
Write-Host '🌐 Your API is running at: http://localhost:8000' -ForegroundColor Cyan
Write-Host '📚 API Documentation: http://localhost:8000/docs' -ForegroundColor Cyan
Write-Host '🔍 Health Check: http://localhost:8000/health' -ForegroundColor Cyan
Write-Host ''
Write-Host 'To view logs: docker-compose -f docker-compose.supabase.yml logs -f' -ForegroundColor Yellow
Write-Host 'To stop: docker-compose -f docker-compose.supabase.yml down' -ForegroundColor Yellow