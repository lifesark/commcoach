from fastapi import APIRouter
from pydantic import BaseModel
from app.services.tts_service import TTSService

router = APIRouter()
tts = TTSService.from_env()

class TTSRequest(BaseModel):
    text: str
    voice: str | None = None

class TTSResponse(BaseModel):
    audio_b64: str

@router.post("/speak", response_model=TTSResponse)
async def speak(req: TTSRequest):
    audio_b64 = await tts.synthesize(req.text, voice=req.voice)
    return TTSResponse(audio_b64=audio_b64)
