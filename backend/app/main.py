from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from slowapi.util import get_remote_address
from contextlib import asynccontextmanager
import logging, sys

from app.core.settings import settings
from app.routers import (
    health, debate_config, realtime, feedback, history, stt, tts, internet, personas, progress
)

logging.basicConfig(
    stream=sys.stdout,
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s :: %(message)s",
)

# Lifespan ensures state is populated *before* any middleware handles requests
@asynccontextmanager
async def lifespan(app: FastAPI):
    limiter = Limiter(key_func=get_remote_address)
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
    yield
    # teardown (nothing needed)

app = FastAPI(title="CommCoach API (Supabase + Gemini)", version="1.0.0", lifespan=lifespan)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.origins_list or ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Add SlowAPI middleware *after* lifespan has registered app.state.limiter
app.add_middleware(SlowAPIMiddleware)

# Routers
app.include_router(health.router, tags=["health"])
app.include_router(debate_config.router, tags=["session"])
app.include_router(realtime.router, prefix="/realtime", tags=["realtime"])
app.include_router(feedback.router, tags=["feedback"])
app.include_router(history.router, tags=["history"])
app.include_router(stt.router, prefix="/stt", tags=["speech-to-text"])
app.include_router(tts.router, prefix="/tts", tags=["text-to-speech"])
app.include_router(internet.router, prefix="/internet", tags=["internet"])
app.include_router(personas.router, prefix="/personas", tags=["personas"])
app.include_router(progress.router, prefix="/progress", tags=["progress"])

@app.get("/")
def root():
    return {"status": "ok", "service": "CommCoach API"}
