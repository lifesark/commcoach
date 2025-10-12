# app/main.py
from __future__ import annotations

import os
import sys
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
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
from app.core.db import engine  # reuse your SQLAlchemy engine
from sqlalchemy import text

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

# ── Simple readiness state container (you can expand as needed)
_ready = {"ok": True, "reason": "booting"}


# ── Lifespan: create limiter BEFORE middleware so app.state.limiter exists
@asynccontextmanager
async def lifespan(app: FastAPI):
    limiter = Limiter(key_func=get_remote_address)
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

    # Any other startup checks can go here
    db_url = os.getenv("DATABASE_URL")
    log.info(f"Startup: DATABASE_URL is {'SET' if db_url else 'NOT SET'}")

    if not db_url:
        _ready["ok"] = False
        _ready["reason"] = "DATABASE_URL is not set"
        log.warning("DATABASE_URL not set; /ready will be false until provided.")
    else:
        # Try to connect to verify the database is accessible
        try:
            log.info("Testing database connection during startup...")
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            _ready["ok"] = True
            _ready["reason"] = "configured"
            log.info("Database connection successful - app is ready")
        except Exception as e:
            _ready["ok"] = False
            _ready["reason"] = f"Database connection failed: {e.__class__.__name__}"
            log.error(f"Database connection failed during startup: {e}")

    yield
    # ── teardown if needed
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

# ── Routers (do NOT include a separate 'health' router to avoid path conflicts)
app.include_router(debate_config.router, tags=["session"])
app.include_router(realtime.router, prefix="/realtime", tags=["realtime"])
app.include_router(feedback.router, tags=["feedback"])
app.include_router(history.router, tags=["history"])
app.include_router(stt.router, prefix="/stt", tags=["speech-to-text"])
app.include_router(tts.router, prefix="/tts", tags=["text-to-speech"])
app.include_router(internet.router, prefix="/internet", tags=["internet"])
app.include_router(personas.router, prefix="/personas", tags=["personas"])
app.include_router(progress.router, prefix="/progress", tags=["progress"])


# ── Health & Ready
@app.get("/", tags=["default"])
def root():
    return {"status": "ok", "service": "CommCoach API"}


@app.get("/health", tags=["health"])
def health():
    """
    Lightweight liveness probe - just checks if the app is running.
    Always returns 200 OK if the server is up.
    """
    return {"status": "ok", "service": "CommCoach API"}


@app.get("/ready", tags=["health"])
def ready():
    """
    Readiness probe:
      - verifies basic configuration
      - checks database connectivity
    Returns detailed status and reason when not ready.
    """
    # Log current state for debugging
    log.info(f"Ready check: _ready state = {_ready}")
    log.info(f"DATABASE_URL present: {bool(os.getenv('DATABASE_URL'))}")

    if not _ready.get("ok", False):
        reason = _ready.get("reason", "unknown")
        log.warning(f"Not ready (initial check): {reason}")
        return {"ready": False, "reason": reason}

    # Double-check DATABASE_URL is still set (shouldn't change, but be defensive)
    db_url = os.getenv("DATABASE_URL")
    if not db_url:
        log.warning("DATABASE_URL is not set (runtime check)")
        return {"ready": False, "reason": "DATABASE_URL is not set"}

    # Probe DB (quick health check)
    try:
        log.info("Attempting database connection check...")
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        log.info("Database connection successful")
        return {"ready": True, "reason": "all checks passed"}
    except Exception as e:
        # Be informative but avoid leaking secrets
        error_msg = f"db check failed: {e.__class__.__name__}"
        log.error(f"Database connection failed: {e}")
        return {"ready": False, "reason": error_msg}


if __name__ == "__main__":
    import uvicorn

    port = int(os.getenv("PORT", 8000))
    # Bind to 0.0.0.0 for container/remote access; use localhost for strictly local
    uvicorn.run("app.main:app", host="0.0.0.0", port=port, reload=os.getenv("RELOAD", "1") == "1")