# syntax=docker/dockerfile:1.7
FROM python:3.10-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libpq-dev && rm -rf /var/lib/apt/lists/*

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# requirements live in backend/
COPY backend/requirements.txt ./requirements.txt
RUN pip install --upgrade pip && \
    pip install --prefer-binary -r requirements.txt

# copy only backend code into image
COPY backend/ ./

EXPOSE 8000
CMD ["sh","-c","uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
