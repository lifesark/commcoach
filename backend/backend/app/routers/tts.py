from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from app.services.tts_service import tts_service
from app.routers.deps_supabase import get_current_user

router = APIRouter()

class TTSRequest(BaseModel):
    text: str
    voice: str | None = None
    language: str = "en"

class TTSResponse(BaseModel):
    audio_b64: str
    voice_used: str
    duration: float

@router.post("/speak", response_model=TTSResponse)
async def speak(req: TTSRequest, user = Depends(get_current_user)):
    """
    Convert text to speech and return base64 encoded audio
    """
    try:
        audio_b64 = await tts_service.synthesize_speech(
            text=req.text,
            voice=req.voice or "default",
            language=req.language
        )
        
        # Calculate estimated duration (rough estimate: 150 words per minute)
        word_count = len(req.text.split())
        estimated_duration = (word_count / 150) * 60  # Convert to seconds
        
        return TTSResponse(
            audio_b64=audio_b64,
            voice_used=req.voice or "default",
            duration=estimated_duration
        )
        
    except ValueError as e:
        raise HTTPException(400, str(e))
    except Exception as e:
        raise HTTPException(500, f"TTS synthesis failed: {str(e)}")

@router.get("/voices")
async def get_available_voices():
    """
    Get list of available voices
    """
    return {
        "voices": tts_service.get_available_voices()
    }
