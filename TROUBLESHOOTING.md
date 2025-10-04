# CommCoach Supabase Deployment - Troubleshooting Guide

## Common Issues and Solutions

### 1. Docker Desktop Not Running
**Error:** `unable to get image 'commcoach-api': error during connect: Get "http://%2F%2F.%2Fpipe%2FdockerDesktopLinuxEngine/v1.51/images/commcoach-api/json": open //./pipe/dockerDesktopLinuxEngine: The system cannot find the file specified.`

**Solution:**
1. Start Docker Desktop
2. Wait for it to fully initialize (green icon in system tray)
3. Try the deployment again

### 2. Missing Environment Variables
**Error:** `The "NEWS_API_KEY" variable is not set. Defaulting to a blank string.`

**Solution:**
1. Edit `docker.env` file with your actual credentials
2. Replace placeholder values with real values:
   ```env
   DATABASE_URL=postgresql://postgres:YOUR_ACTUAL_PASSWORD@db.YOUR_PROJECT_REF.supabase.co:5432/postgres
   SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
   SUPABASE_ANON_KEY=YOUR_ACTUAL_ANON_KEY
   SUPABASE_SERVICE_ROLE_KEY=YOUR_ACTUAL_SERVICE_ROLE_KEY
   GEMINI_API_KEY=YOUR_ACTUAL_GEMINI_KEY
   ```

### 3. Docker Compose Version Warning
**Error:** `the attribute 'version' is obsolete`

**Solution:** ✅ Fixed - Removed the obsolete version attribute

### 4. Database Connection Issues
**Error:** Database connection failed

**Solutions:**
1. Check your Supabase database password
2. Verify the DATABASE_URL format
3. Ensure your IP is whitelisted in Supabase (Settings → Database → Network Restrictions)

### 5. Build Failures
**Error:** Build context issues

**Solutions:**
1. Ensure you're in the project root directory
2. Check that `backend/Dockerfile` exists
3. Verify all required files are present

## Step-by-Step Fix Process

### Step 1: Start Docker Desktop
```powershell
# Check if Docker is running
docker --version
docker ps
```

### Step 2: Configure Environment
```powershell
# Copy the example file
Copy-Item docker.env docker.env.backup

# Edit docker.env with your actual credentials
notepad docker.env
```

### Step 3: Test Docker Compose
```powershell
# Test the configuration
docker-compose -f docker-compose.supabase.yml config

# Build and run
docker-compose -f docker-compose.supabase.yml up --build -d
```

### Step 4: Check Logs
```powershell
# View logs
docker-compose -f docker-compose.supabase.yml logs -f

# Check specific service
docker-compose -f docker-compose.supabase.yml logs api
```

## Quick Fix Commands

```powershell
# Stop all containers
docker-compose -f docker-compose.supabase.yml down

# Remove all containers and images
docker-compose -f docker-compose.supabase.yml down --rmi all

# Rebuild from scratch
docker-compose -f docker-compose.supabase.yml up --build --force-recreate -d
```

## Getting Help

1. Check Docker Desktop is running
2. Verify all environment variables are set
3. Check the logs for specific error messages
4. Ensure your Supabase project is active and accessible
