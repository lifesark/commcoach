import base64
import io
import tempfile
from typing import Optional
from app.core.settings import settings
import google.generativeai as genai
import pydub
from pydub import AudioSegment
import wave
import soundfile as sf

class STTService:
    def __init__(self):
        if settings.GEMINI_STT_ENABLED:
            genai.configure(api_key=settings.GEMINI_API_KEY)
        self.supported_formats = settings.SUPPORTED_AUDIO_FORMATS.split(",")
        self.max_size_bytes = settings.MAX_AUDIO_SIZE_MB * 1024 * 1024

    async def transcribe_audio(self, audio_data: bytes, language: str = "en") -> str:
        """
        Transcribe audio data to text using Gemini STT
        """
        if not settings.GEMINI_STT_ENABLED:
            raise ValueError("Gemini STT is not enabled")
        
        # Validate audio size
        if len(audio_data) > self.max_size_bytes:
            raise ValueError(f"Audio file too large. Max size: {settings.MAX_AUDIO_SIZE_MB}MB")
        
        try:
            # Convert audio to WAV format if needed
            audio_wav = self._convert_to_wav(audio_data)
            
            # Use Gemini STT
            model = genai.GenerativeModel('gemini-1.5-pro-latest')
            
            # Create a temporary file for the audio
            with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as temp_file:
                temp_file.write(audio_wav)
                temp_file_path = temp_file.name
            
            try:
                # Upload the audio file to Gemini
                audio_file = genai.upload_file(temp_file_path)
                
                # Generate content with the audio
                response = model.generate_content([
                    "Transcribe this audio to text. Return only the transcribed text without any additional commentary:",
                    audio_file
                ])
                
                return response.text.strip() if response.text else ""
                
            finally:
                # Clean up temporary file
                import os
                try:
                    os.unlink(temp_file_path)
                except:
                    pass
                    
        except Exception as e:
            raise ValueError(f"STT transcription failed: {str(e)}")

    def _convert_to_wav(self, audio_data: bytes) -> bytes:
        """
        Convert audio data to WAV format for Gemini STT
        """
        try:
            # Try to load as audio segment
            audio = AudioSegment.from_file(io.BytesIO(audio_data))
            
            # Convert to WAV format (16kHz, mono, 16-bit)
            audio = audio.set_frame_rate(16000).set_channels(1).set_sample_width(2)
            
            # Export to bytes
            wav_buffer = io.BytesIO()
            audio.export(wav_buffer, format="wav")
            return wav_buffer.getvalue()
            
        except Exception as e:
            # If conversion fails, try to use the original data
            # (it might already be in the correct format)
            return audio_data

    def validate_audio_format(self, audio_data: bytes) -> bool:
        """
        Validate if the audio format is supported
        """
        try:
            # Try to load the audio to validate format
            AudioSegment.from_file(io.BytesIO(audio_data))
            return True
        except:
            return False

    def get_audio_duration(self, audio_data: bytes) -> float:
        """
        Get the duration of audio in seconds
        """
        try:
            audio = AudioSegment.from_file(io.BytesIO(audio_data))
            return len(audio) / 1000.0  # Convert milliseconds to seconds
        except:
            return 0.0

# Global instance
stt_service = STTService()
