from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi.middleware import SlowAPIMiddleware
import logging, sys

from app.core.settings import settings
from app.routers import health, debate_config, realtime, feedback, history, stt, tts, internet, personas, progress

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
app.include_router(stt.router, prefix="/stt", tags=["speech-to-text"])
app.include_router(tts.router, prefix="/tts", tags=["text-to-speech"])
app.include_router(internet.router, prefix="/internet", tags=["internet"])
app.include_router(personas.router, prefix="/personas", tags=["personas"])
app.include_router(progress.router, prefix="/progress", tags=["progress"])

@app.get("/")
def root():
    return {"status":"ok","service":"CommCoach API"}
