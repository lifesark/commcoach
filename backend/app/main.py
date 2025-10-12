# app/main.py
from __future__ import annotations

import os
import sys
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware

# ── Rate limiting (SlowAPI)
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from slowapi.util import get_remote_address

# ── Settings / DB
from dotenv import load_dotenv

load_dotenv()

from app.core.settings import settings
from sqlalchemy import create_engine, text
from sqlalchemy.exc import SQLAlchemyError

# ── Routers (keep these as they exist in your project)
from app.routers import (
    debate_config,
    realtime,
    feedback,
    history,
    stt,
    tts,
    internet,
    personas,
    progress,
)

# ── Logging
logging.basicConfig(
    stream=sys.stdout,
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s :: %(message)s",
)
log = logging.getLogger("commcoach.main")


async def test_db_connection(url: str) -> tuple[bool, str]:
    """
    Test database connectivity during startup.
    Returns (success: bool, message: str)
    """
    try:
        log.info("Creating test database engine...")
        engine = create_engine(url, pool_pre_ping=True)
        log.info("Attempting database connection...")
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        log.info("Database connection test successful")
        engine.dispose()
        return True, "Database connection verified"
    except SQLAlchemyError as e:
        error_msg = f"Database connection failed: {e.__class__.__name__}"
        log.error(f"{error_msg}: {str(e)[:200]}")
        return False, error_msg
    except Exception as e:
        error_msg = f"Unexpected error during DB test: {e.__class__.__name__}"
        log.error(f"{error_msg}: {str(e)[:200]}")
        return False, error_msg


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan: startup and shutdown events"""

    # ── Initialize rate limiter
    limiter = Limiter(key_func=get_remote_address)
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

    # ── Initialize readiness state
    app.state.ready = False
    app.state.ready_reason = "initializing"

    # ── Check DATABASE_URL
    db_url = os.getenv("DATABASE_URL")
    if not db_url:
        log.warning("Startup: DATABASE_URL is NOT SET")
        app.state.ready = False
        app.state.ready_reason = "DATABASE_URL is not set"
    else:
        log.info("Startup: DATABASE_URL is SET")

        # ── Test database connection
        success, message = await test_db_connection(db_url)
        app.state.ready = success
        app.state.ready_reason = message

        if success:
            log.info("✓ Application is READY")
        else:
            log.warning(f"✗ Application NOT ready: {message}")

    yield

    # ── Teardown
    log.info("Application shutdown")


app = FastAPI(
    title="CommCoach API (Supabase + Gemini)",
    version="1.0.0",
    lifespan=lifespan,
)

# ── CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=(settings.origins_list or ["*"]),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── SlowAPI middleware (must come AFTER lifespan has set app.state.limiter)
app.add_middleware(SlowAPIMiddleware)

# ── Routers
app.include_router(debate_config.router, tags=["session"])
app.include_router(realtime.router, prefix="/realtime", tags=["realtime"])
app.include_router(feedback.router, tags=["feedback"])
app.include_router(history.router, tags=["history"])
app.include_router(stt.router, prefix="/stt", tags=["speech-to-text"])
app.include_router(tts.router, prefix="/tts", tags=["text-to-speech"])
app.include_router(internet.router, prefix="/internet", tags=["internet"])
app.include_router(personas.router, prefix="/personas", tags=["personas"])
app.include_router(progress.router, prefix="/progress", tags=["progress"])


# ── Health & Readiness Endpoints
@app.get("/", tags=["default"])
def root():
    """Root endpoint"""
    return {"status": "ok", "service": "CommCoach API"}


@app.get("/health", tags=["health"])
def health():
    """
    Liveness probe - checks if the application is running.
    Returns 200 OK if the server process is alive.
    """
    return {"status": "ok", "service": "CommCoach API"}


@app.get("/ready", tags=["health"])
def ready(request: Request):
    """
    Readiness probe - checks if the application is ready to serve traffic.
    Verifies database connectivity and required configuration.
    """
    is_ready = getattr(request.app.state, "ready", False)
    reason = getattr(request.app.state, "ready_reason", "unknown")

    log.info(f"Readiness check: ready={is_ready}, reason={reason}")

    return {
        "ready": is_ready,
        "reason": reason
    }


if __name__ == "__main__":
    import uvicorn

    port = int(os.getenv("PORT", 8000))
    reload = os.getenv("RELOAD", "1") == "1"

    log.info(f"Starting server on port {port} (reload={reload})")
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=port,
        reload=reload
    )