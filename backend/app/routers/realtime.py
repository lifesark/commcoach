from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from app.core.db import SessionLocal
from app.models.models import Session as S, Message
from app.services.llm_service import LLMService
from app.services.session_sm import start_round as sm_start_round, switch_turn as sm_switch, end_session as sm_end
import asyncio, contextlib, json
from datetime import datetime

router = APIRouter()
llm = LLMService()

async def ws_send(ws: WebSocket, typ: str, **payload):
    await ws.send_text(json.dumps({"type": typ, **payload}))

@router.websocket("/ws")
async def ws_endpoint(ws: WebSocket):
    await ws.accept()
    session_id = None

    try:
        while True:
            data = await ws.receive_json()
            typ = data.get("type")

            if typ == "attach_session":
                session_id = data.get("session_id")
                with contextlib.closing(SessionLocal()) as db:
                    s: S = db.query(S).filter(S.id == session_id).first()
                    if not s:
                        await ws_send(ws, "error", detail="Invalid session"); continue
                    await ws_send(ws, "session_attached", session_id=s.id, config=s.config, topic=s.topic, mode=s.mode)

            elif typ == "start_prep":
                await ws_send(ws, "prep_started", seconds=90)

            elif typ == "start_round":
                if not session_id:
                    await ws_send(ws, "error", detail="Attach session first"); continue
                with contextlib.closing(SessionLocal()) as db:
                    s: S = db.query(S).filter(S.id == session_id).first()
                    sm_start_round(s); db.commit()
                    await ws_send(ws, "round_started", round=s.round_no, turn=s.turn, turn_seconds=s.config.get("turn_s", 60))

            elif typ == "user_text":
                txt = (data.get("text") or "").trim() if isinstance(data.get("text"), str) else (data.get("text") or "")
                txt = txt.strip()
                if not txt or not session_id: continue

                with contextlib.closing(SessionLocal()) as db:
                    s: S = db.query(S).filter(S.id == session_id).first()
                    if not s or s.state != "live" or s.turn != "user":
                        await ws_send(ws, "error", detail="Not user's turn"); continue

                    db.add(Message(session_id=s.id, role="user", content=txt, time=datetime.utcnow())); db.commit()

                    await ws_send(ws, "ai_reply_start")
                    full = []
                    try:
                        for chunk in llm.stream(
                            s.mode, s.topic, s.round_no, s.config.get("rounds",3), "ai", s.config.get("turn_s",60), txt
                        ):
                            if not chunk: continue
                            full.append(chunk)
                            await ws_send(ws, "ai_token", token=chunk)
                            await asyncio.sleep(0)
                    except Exception:
                        pass

                    reply = "".join(full).strip() or llm.generate(
                        s.mode, s.topic, s.round_no, s.config.get("rounds",3), "ai", s.config.get("turn_s",60), txt
                    )

                    await ws_send(ws, "ai_reply_end", text=reply)
                    db.add(Message(session_id=s.id, role="ai", content=reply, time=datetime.utcnow()))
                    sm_switch(s); db.commit()
                    await ws_send(ws, "turn_switched", turn=s.turn)

            elif typ == "end":
                if session_id:
                    with contextlib.closing(SessionLocal()) as db:
                        s: S = db.query(S).filter(S.id == session_id).first()
                        if s:
                            sm_end(s); s.ended_at = datetime.utcnow(); db.commit()
                await ws_send(ws, "session_ended", summary="Saved")
                break

    except WebSocketDisconnect:
        pass
    except Exception as e:
        try: await ws_send(ws, "error", detail=str(e))
        except: pass
