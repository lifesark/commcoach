# Supabase Backend Deployment Guide

## 1. Supabase Project Setup

### Create a new Supabase project:
1. Go to [supabase.com](https://supabase.com)
2. Create a new project
3. Note down your project URL and API keys from Settings → API

### Get your database connection string:
1. Go to Settings → Database
2. Copy the connection string (replace `[YOUR-PASSWORD]` with your actual password)

## 2. Database Migration

### Run migrations on Supabase:
```bash
# Set your Supabase database URL
export DATABASE_URL="postgresql://postgres:[YOUR-PASSWORD]@db.[YOUR-PROJECT-REF].supabase.co:5432/postgres"

# Run migrations
cd backend
alembic upgrade head
```

## 3. Environment Configuration

Create a `.env` file in the backend directory with:

```env
# Environment
COMMCOACH_ENV=production
API_ORIGINS=https://your-frontend-domain.com

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

# Other API keys...
```

## 4. Deployment Options

### Option A: Supabase Edge Functions (Recommended)
Deploy your FastAPI backend as Supabase Edge Functions for serverless execution.

### Option B: External Hosting
Deploy to platforms like:
- Railway
- Render
- DigitalOcean App Platform
- AWS/GCP/Azure

### Option C: Docker with Supabase
Use the existing Docker setup but connect to Supabase database.

## 5. Benefits of Using Supabase

- **Managed PostgreSQL**: No database maintenance
- **Real-time subscriptions**: Built-in WebSocket support
- **Authentication**: JWT-based auth with multiple providers
- **Storage**: File storage for audio files
- **Edge Functions**: Serverless backend deployment
- **Dashboard**: Database management interface
- **API Generation**: Auto-generated REST and GraphQL APIs
