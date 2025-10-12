from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from app.core.db import SessionLocal
from app.models.models import Session as S
from app.routers.deps_supabase import get_current_user
from app.services.internet_service import internet_service
from app.services.persona_service import persona_service
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
    fetch_from_internet: bool = False
    persona_type: str | None = None
    prep_s: int = 60
    turn_s: int = 60
    rounds: int = 2

@router.post("/session/config")
async def create_session(req: ConfigReq, user = Depends(get_current_user)):
    mode = req.mode if req.mode in TOPICS else "general"
    topic = req.topic
    
    # Fetch topic from internet if requested
    if req.fetch_from_internet and not topic:
        try:
            if mode == "debate":
                topics = await internet_service.fetch_debate_topics("general", 1)
                topic = topics[0]["title"] if topics else None
            elif mode == "presentation":
                topics = await internet_service.fetch_presentation_topics("technology", 1)
                topic = topics[0]["title"] if topics else None
            elif mode == "interview":
                questions = await internet_service.fetch_interview_questions("software_engineer", 1)
                topic = questions[0]["question"] if questions else None
        except Exception as e:
            print(f"Internet fetch failed: {e}")
            # Fallback to local topics
    
    # Use random local topic if no topic provided and not fetching from internet
    if not topic and req.random_topic:
        topic = random.choice(TOPICS[mode]) if mode in TOPICS else random.choice(TOPICS["general"])
    
    if not topic:
        raise HTTPException(400, "Provide topic, set random_topic=true, or set fetch_from_internet=true.")
    
    # Get persona type (default to mode-based recommendation)
    persona_type = req.persona_type
    if not persona_type:
        persona_enum = persona_service.get_persona_for_mode(mode)
        persona_type = persona_enum.value
    
    sid = str(uuid.uuid4())
    with SessionLocal() as db:
        config = {
            "prep_s": req.prep_s, 
            "turn_s": req.turn_s, 
            "rounds": req.rounds,
            "persona_type": persona_type
        }
        s = S(id=sid, user_id=user["sub"], mode=mode, topic=topic,
              config=config,
              state="created", round_no=0, turn="user")
        db.add(s); db.commit()
    
    return {
        "session_id": sid, 
        "mode": mode, 
        "topic": topic, 
        "persona_type": persona_type,
        "config": s.config, 
        "state": "created"
    }
