from fastapi import APIRouter, HTTPException, Depends, UploadFile, File
from pydantic import BaseModel
from app.services.stt_service import stt_service
from app.routers.deps_supabase import get_current_user
import base64

router = APIRouter()

class STTResponse(BaseModel):
    text: str
    confidence: float
    duration: float

@router.post("/transcribe", response_model=STTResponse)
async def transcribe_audio(
    audio_file: UploadFile = File(...),
    language: str = "en",
    user = Depends(get_current_user)
):
    """
    Transcribe audio file to text using STT service
    """
    try:
        # Validate file type
        if not audio_file.content_type or not audio_file.content_type.startswith('audio/'):
            raise HTTPException(400, "File must be an audio file")
        
        # Read audio data
        audio_data = await audio_file.read()
        
        # Validate audio format
        if not stt_service.validate_audio_format(audio_data):
            raise HTTPException(400, "Unsupported audio format")
        
        # Get audio duration
        duration = stt_service.get_audio_duration(audio_data)
        
        # Transcribe audio
        text = await stt_service.transcribe_audio(audio_data, language)
        
        # Calculate confidence (simplified - in real implementation, this would come from the STT service)
        confidence = 0.85  # Placeholder confidence score
        
        return STTResponse(
            text=text,
            confidence=confidence,
            duration=duration
        )
        
    except ValueError as e:
        raise HTTPException(400, str(e))
    except Exception as e:
        raise HTTPException(500, f"Transcription failed: {str(e)}")

@router.post("/transcribe-base64")
async def transcribe_audio_base64(
    audio_data: str,
    language: str = "en",
    user = Depends(get_current_user)
):
    """
    Transcribe base64 encoded audio data to text
    """
    try:
        # Decode base64 audio data
        audio_bytes = base64.b64decode(audio_data)
        
        # Validate audio format
        if not stt_service.validate_audio_format(audio_bytes):
            raise HTTPException(400, "Unsupported audio format")
        
        # Get audio duration
        duration = stt_service.get_audio_duration(audio_bytes)
        
        # Transcribe audio
        text = await stt_service.transcribe_audio(audio_bytes, language)
        
        # Calculate confidence
        confidence = 0.85  # Placeholder confidence score
        
        return STTResponse(
            text=text,
            confidence=confidence,
            duration=duration
        )
        
    except ValueError as e:
        raise HTTPException(400, str(e))
    except Exception as e:
        raise HTTPException(500, f"Transcription failed: {str(e)}")

@router.get("/supported-formats")
async def get_supported_formats():
    """
    Get list of supported audio formats
    """
    return {
        "formats": stt_service.supported_formats,
        "max_size_mb": stt_service.max_size_bytes // (1024 * 1024)
    }
