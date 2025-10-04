from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import desc
from app.core.db import SessionLocal
from app.models.models import Session as S, Message, Feedback
from app.routers.deps_supabase import get_current_user

router = APIRouter()

@router.get("/history")
def list_history(limit: int = 20, user = Depends(get_current_user)):
    with SessionLocal() as db:
        rows = (db.query(S)
                  .filter(S.user_id == user["sub"])
                  .order_by(desc(S.started_at))
                  .limit(limit).all())
        return [{"id": s.id, "mode": s.mode, "topic": s.topic, "started_at": s.started_at, "ended_at": s.ended_at}
                for s in rows]

@router.get("/history/{session_id}")
def get_session(session_id: str, user = Depends(get_current_user)):
    with SessionLocal() as db:
        s = db.query(S).filter(S.id==session_id).first()
        if not s: raise HTTPException(404, "Not found")
        if s.user_id != user["sub"]: raise HTTPException(403, "Forbidden")

        msgs = db.query(Message).filter(Message.session_id==s.id).order_by(Message.time).all()
        fb = db.query(Feedback).filter(Feedback.session_id==s.id).first()
        return {
            "id": s.id, "mode": s.mode, "topic": s.topic, "config": s.config,
            "messages": [{"role": m.role, "content": m.content, "time": m.time.isoformat()} for m in msgs],
            "feedback": ({
                "clarity": fb.clarity, "structure": fb.structure, "persuasiveness": fb.persuasiveness,
                "fluency": fb.fluency, "time": fb.time_score, "overall": fb.overall, "tips": fb.tips
            } if fb else None)
        }
