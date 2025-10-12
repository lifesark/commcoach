from fastapi import APIRouter
from sqlalchemy import text
from app.core.db import SessionLocal

router = APIRouter()

@router.get("/health")
def health():
    return {"status":"ok","service":"CommCoach API"}

@router.get("/ready")
def ready():
    try:
        with SessionLocal() as db:
            db.execute(text("SELECT 1"))
        return {"ready": True}
    except Exception:
        return {"ready": False}
