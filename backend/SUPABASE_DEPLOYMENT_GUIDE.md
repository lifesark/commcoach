# CommCoach Backend - Supabase Deployment Guide

## Overview

This guide shows you how to deploy your CommCoach backend to use Supabase as your primary backend service. Your backend is already well-configured for Supabase integration.

## Prerequisites

- Docker and Docker Compose installed
- Supabase account and project
- Python 3.10+ (for local development)

## Step 1: Set Up Supabase Project

### 1.1 Create Supabase Project
1. Go to [supabase.com](https://supabase.com)
2. Create a new project
3. Wait for the project to be ready (2-3 minutes)

### 1.2 Get Your Credentials
1. Go to **Settings** → **API**
2. Copy the following:
   - Project URL (`SUPABASE_URL`)
   - Anon public key (`SUPABASE_ANON_KEY`)
   - Service role key (`SUPABASE_SERVICE_ROLE_KEY`)

### 1.3 Get Database Connection String
1. Go to **Settings** → **Database**
2. Copy the connection string
3. Replace `[YOUR-PASSWORD]` with your actual database password

## Step 2: Configure Environment

### 2.1 Create Environment File
Create `backend/.env` with your Supabase credentials:

```env
# Environment
COMMCOACH_ENV=production
API_ORIGINS=https://your-frontend-domain.com,http://localhost:3000

# Database - Supabase PostgreSQL
DATABASE_URL=postgresql://postgres:[YOUR-PASSWORD]@db.[YOUR-PROJECT-REF].supabase.co:5432/postgres

# Supabase Configuration
SUPABASE_URL=https://[YOUR-PROJECT-REF].supabase.co
SUPABASE_ANON_KEY=[YOUR-ANON-KEY]
SUPABASE_SERVICE_ROLE_KEY=[YOUR-SERVICE-ROLE-KEY]
SUPABASE_JWKS_CACHE_SECONDS=86400

# Gemini AI Configuration
GEMINI_API_KEY=[YOUR-GEMINI-API-KEY]
GEMINI_MODEL=gemini-1.5-pro-latest
GEMINI_STT_ENABLED=true
GEMINI_TTS_ENABLED=true

# PlayHT TTS (Optional)
PLAYHT_API_KEY=[YOUR-PLAYHT-API-KEY]
PLAYHT_USER_ID=[YOUR-PLAYHT-USER-ID]

# Internet APIs
NEWS_API_KEY=f7a67b3f1e5e4b6c83a4ace3a7370d8f
WIKIPEDIA_ENABLED=true

# Audio Processing
MAX_AUDIO_SIZE_MB=10
SUPPORTED_AUDIO_FORMATS=wav,mp3,m4a,ogg
```

## Step 3: Deploy Backend

### Option A: Using Docker Compose (Recommended)

#### Windows:
```powershell
.\deploy-supabase.ps1
```

#### Linux/Mac:
```bash
./deploy-supabase.sh
```

#### Manual Docker Compose:
```bash
docker-compose -f docker-compose.supabase.yml up --build -d
```

### Option B: Local Development
```bash
cd backend
pip install -r requirements.txt
alembic upgrade head
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## Step 4: Verify Deployment

### 4.1 Check API Health
```bash
curl http://localhost:8000/health
```

### 4.2 View API Documentation
Open http://localhost:8000/docs in your browser

### 4.3 Test Database Connection
```bash
curl http://localhost:8000/ready
```

## Step 5: Production Deployment

### Option A: Railway
1. Connect your GitHub repository to Railway
2. Set environment variables in Railway dashboard
3. Deploy automatically on git push

### Option B: Render
1. Create a new Web Service on Render
2. Connect your GitHub repository
3. Set environment variables
4. Deploy

### Option C: DigitalOcean App Platform
1. Create a new app on DigitalOcean
2. Connect your GitHub repository
3. Configure environment variables
4. Deploy

## Benefits of Using Supabase

### 🗄️ **Managed PostgreSQL Database**
- No database maintenance required
- Automatic backups and scaling
- Built-in connection pooling

### 🔐 **Authentication & Authorization**
- JWT-based authentication
- Multiple auth providers (Google, GitHub, etc.)
- Row-level security (RLS)

### 📡 **Real-time Features**
- WebSocket subscriptions
- Real-time database changes
- Live updates for your app

### 📁 **File Storage**
- Store audio files and user data
- CDN integration
- Automatic image optimization

### ⚡ **Edge Functions**
- Serverless backend functions
- Global edge deployment
- Automatic scaling

### 📊 **Dashboard & Management**
- Database management interface
- API documentation
- Analytics and monitoring

## Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Supabase       │    │   External APIs │
│   (Flutter)     │◄──►│   Backend        │◄──►│   (Gemini, etc) │
│                 │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌──────────────────┐
                       │   Supabase       │
                       │   PostgreSQL     │
                       │   Database       │
                       └──────────────────┘
```

## Troubleshooting

### Common Issues

1. **Database Connection Failed**
   - Check your `DATABASE_URL` format
   - Verify your database password
   - Ensure your IP is whitelisted in Supabase

2. **Authentication Errors**
   - Verify your Supabase keys
   - Check JWT token format
   - Ensure CORS is properly configured

3. **Migration Issues**
   - Run `alembic upgrade head` manually
   - Check database permissions
   - Verify schema compatibility

### Getting Help

- Check the logs: `docker-compose -f docker-compose.supabase.yml logs -f`
- Supabase documentation: https://supabase.com/docs
- CommCoach API docs: http://localhost:8000/docs

## Next Steps

1. Set up your Supabase project
2. Configure environment variables
3. Deploy using the provided scripts
4. Test the integration
5. Deploy to production hosting

Your backend is now ready to run with Supabase! 🚀
