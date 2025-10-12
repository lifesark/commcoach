#!/bin/bash

# CommCoach Backend - Supabase Deployment Script

set -e

echo "🚀 Deploying CommCoach Backend to Supabase..."

# Check if .env file exists
if [ ! -f "backend/.env" ]; then
    echo "❌ Error: backend/.env file not found!"
    echo "Please create backend/.env with your Supabase credentials"
    echo "See backend/env.example for reference"
    exit 1
fi

# Load environment variables
export $(cat backend/.env | grep -v '^#' | xargs)

# Check required environment variables
required_vars=("SUPABASE_URL" "SUPABASE_ANON_KEY" "SUPABASE_SERVICE_ROLE_KEY" "DATABASE_URL" "GEMINI_API_KEY")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Error: $var is not set in backend/.env"
        exit 1
    fi
done

echo "✅ Environment variables loaded"

# Run database migrations
echo "📊 Running database migrations..."
cd backend
alembic upgrade head
echo "✅ Database migrations completed"

# Build and run with Docker Compose
echo "🐳 Building and starting containers..."
cd ..
docker-compose -f docker-compose.supabase.yml up --build -d

echo "✅ Deployment completed!"
echo ""
echo "🌐 Your API is running at: http://localhost:8000"
echo "📚 API Documentation: http://localhost:8000/docs"
echo "🔍 Health Check: http://localhost:8000/health"
echo ""
echo "To view logs: docker-compose -f docker-compose.supabase.yml logs -f"
echo "To stop: docker-compose -f docker-compose.supabase.yml down"
