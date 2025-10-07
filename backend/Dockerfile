# syntax=docker/dockerfile:1.7
FROM python:3.10-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
 && rm -rf /var/lib/apt/lists/*

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

WORKDIR /app
COPY requirements.txt .

# ✅ No cache mount; straightforward and compatible everywhere
RUN pip install --upgrade pip && \
    pip install --prefer-binary -r requirements.txt

COPY . .

EXPOSE 8000
# IMPORTANT: on Railway use $PORT (or swap in your start command if different)
CMD ["sh","-c","uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
