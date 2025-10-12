from fastapi import APIRouter, HTTPException, Depends
from json import dumps
from app.core.db import SessionLocal
from app.models.models import Session as S, Message, Feedback
from app.services.feedback_service import analyze
from app.services.storage import put_json, transcript_path
from app.services.progress_service import progress_service
from app.routers.deps_supabase import get_current_user

router = APIRouter()

@router.post("/feedback/session/{session_id}")
def compute_feedback(session_id: str, user = Depends(get_current_user)):
    with SessionLocal() as db:
        s = db.query(S).filter(S.id==session_id).first()
        if not s: raise HTTPException(404, "Session not found")
        if s.user_id and s.user_id != user["sub"]: raise HTTPException(403, "Forbidden")

        msgs = db.query(Message).filter(Message.session_id==session_id).order_by(Message.time).all()
        payload = [{"role": m.role, "content": m.content, "time": m.time.isoformat()} for m in msgs]
        fb = analyze(payload, s.mode, s.config)

        rec = Feedback(
            session_id=session_id,
            clarity=fb["clarity"], structure=fb["structure"], persuasiveness=fb["persuasiveness"],
            fluency=fb["fluency"], time_score=fb["time"], overall=fb["overall"], tips=dumps(fb["tips"])
        )
        db.add(rec); db.commit()

        # Update user progress
        try:
            progress_update = progress_service.update_progress(user["sub"], session_id, fb)
            fb["progress_update"] = progress_update
        except Exception as e:
            print(f"Progress update failed: {e}")
            # Don't fail the feedback if progress update fails

        try:
            path = transcript_path(user.get("sub"), session_id)
            put_json("transcripts", path, {"session": session_id, "mode": s.mode, "topic": s.topic,
                                           "messages": payload, "feedback": fb})
        except Exception:
            pass

        return fb
