from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from app.core.db import SessionLocal
from app.models.models import Session as S
from app.routers.deps_supabase import get_current_user
import uuid, random

router = APIRouter()

TOPICS = {
  "debate": [
    "Social media does more harm than good",
    "AI will create more jobs than it replaces",
    "Universities should be free",
  ],
  "interview": [
    "Tell me about a challenging project",
    "Why should we hire you?",
  ],
  "presentation": [
    "Pitch a product to reduce food waste",
  ],
  "general": [
    "Is remote work better than office work?",
  ],
}

class ConfigReq(BaseModel):
    mode: str
    topic: str | None = None
    random_topic: bool = False
    prep_s: int = 60
    turn_s: int = 60
    rounds: int = 2

@router.post("/session/config")
def create_session(req: ConfigReq, user = Depends(get_current_user)):
    mode = req.mode if req.mode in TOPICS else "general"
    topic = req.topic or (random.choice(TOPICS[mode]) if req.random_topic else None)
    if topic is None:
        raise HTTPException(400, "Provide topic or set random_topic=true.")
    sid = str(uuid.uuid4())
    with SessionLocal() as db:
        s = S(id=sid, user_id=user["sub"], mode=mode, topic=topic,
              config={"prep_s": req.prep_s, "turn_s": req.turn_s, "rounds": req.rounds},
              state="created", round_no=0, turn="user")
        db.add(s); db.commit()
    return {"session_id": sid, "mode": mode, "topic": topic, "config": s.config, "state": "created"}
