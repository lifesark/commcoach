from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi.middleware import SlowAPIMiddleware
import logging, sys

from app.core.settings import settings
from app.routers import health, debate_config, realtime, feedback, history

logging.basicConfig(
    stream=sys.stdout,
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s :: %(message)s",
)

app = FastAPI(title="CommCoach API (Supabase + Gemini)", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.origins_list or ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_middleware(SlowAPIMiddleware)

app.include_router(health.router, tags=["health"])
app.include_router(debate_config.router, tags=["session"])
app.include_router(realtime.router, prefix="/realtime", tags=["realtime"])
app.include_router(feedback.router, tags=["feedback"])
app.include_router(history.router, tags=["history"])

@app.get("/")
def root():
    return {"status":"ok","service":"CommCoach API"}
