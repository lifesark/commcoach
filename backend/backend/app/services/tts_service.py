import base64
import io
import tempfile
import asyncio
from typing import Optional
from app.core.settings import settings
import google.generativeai as genai
import httpx
import json

class TTSService:
    def __init__(self):
        if settings.GEMINI_TTS_ENABLED:
            genai.configure(api_key=settings.GEMINI_API_KEY)
        self.playht_enabled = bool(settings.PLAYHT_API_KEY and settings.PLAYHT_USER_ID)

    async def synthesize_speech(self, text: str, voice: str = "default", language: str = "en") -> str:
        """
        Convert text to speech and return base64 encoded audio
        """
        if settings.GEMINI_TTS_ENABLED:
            return await self._synthesize_with_gemini(text, voice, language)
        elif self.playht_enabled:
            return await self._synthesize_with_playht(text, voice, language)
        else:
            raise ValueError("No TTS service available")

    async def _synthesize_with_gemini(self, text: str, voice: str, language: str) -> str:
        """
        Use Gemini TTS for speech synthesis
        """
        try:
            # For now, we'll use a simple approach since Gemini TTS API might not be directly available
            # This is a placeholder implementation - you may need to adjust based on actual Gemini TTS API
            model = genai.GenerativeModel('gemini-1.5-pro-latest')
            
            # Generate audio using Gemini (this is a placeholder - actual implementation may vary)
            response = model.generate_content([
                f"Generate speech for this text in {language}: {text}"
            ])
            
            # For now, return a placeholder base64 audio
            # In a real implementation, you would process the response to get actual audio
            return self._create_placeholder_audio(text)
            
        except Exception as e:
            raise ValueError(f"Gemini TTS failed: {str(e)}")

    async def _synthesize_with_playht(self, text: str, voice: str, language: str) -> str:
        """
        Use PlayHT API for speech synthesis
        """
        if not self.playht_enabled:
            raise ValueError("PlayHT not configured")
        
        try:
            async with httpx.AsyncClient() as client:
                # PlayHT API endpoint
                url = "https://api.play.ht/api/v2/tts"
                
                headers = {
                    "Authorization": f"Bearer {settings.PLAYHT_API_KEY}",
                    "X-USER-ID": settings.PLAYHT_USER_ID,
                    "Content-Type": "application/json"
                }
                
                data = {
                    "text": text,
                    "voice": voice,
                    "language": language,
                    "output_format": "mp3",
                    "sample_rate": 24000
                }
                
                response = await client.post(url, headers=headers, json=data)
                response.raise_for_status()
                
                result = response.json()
                
                # Get the audio URL
                audio_url = result.get("output_url")
                if not audio_url:
                    raise ValueError("No audio URL in response")
                
                # Download the audio
                audio_response = await client.get(audio_url)
                audio_response.raise_for_status()
                
                # Convert to base64
                audio_data = audio_response.content
                return base64.b64encode(audio_data).decode('utf-8')
                
        except Exception as e:
            raise ValueError(f"PlayHT TTS failed: {str(e)}")

    def _create_placeholder_audio(self, text: str) -> str:
        """
        Create a placeholder audio file for testing
        This should be replaced with actual TTS implementation
        """
        # Create a simple WAV file with silence
        import wave
        import struct
        
        # Create a simple sine wave as placeholder
        sample_rate = 22050
        duration = min(len(text) * 0.1, 10)  # Roughly 0.1 seconds per character, max 10 seconds
        frequency = 440  # A4 note
        
        frames = []
        for i in range(int(sample_rate * duration)):
            value = int(32767 * 0.1 * (1 if i % 100 < 50 else -1))  # Simple square wave
            frames.append(struct.pack('<h', value))
        
        # Create WAV data
        wav_buffer = io.BytesIO()
        with wave.open(wav_buffer, 'wb') as wav_file:
            wav_file.setnchannels(1)  # Mono
            wav_file.setsampwidth(2)  # 16-bit
            wav_file.setframerate(sample_rate)
            wav_file.writeframes(b''.join(frames))
        
        wav_data = wav_buffer.getvalue()
        return base64.b64encode(wav_data).decode('utf-8')

    def get_available_voices(self) -> list:
        """
        Get list of available voices
        """
        voices = [
            {"id": "default", "name": "Default", "language": "en"},
            {"id": "friendly", "name": "Friendly Mentor", "language": "en"},
            {"id": "professional", "name": "Professional", "language": "en"},
            {"id": "energetic", "name": "Energetic", "language": "en"},
        ]
        
        if self.playht_enabled:
            # Add PlayHT voices
            voices.extend([
                {"id": "playht-male", "name": "Male Voice", "language": "en"},
                {"id": "playht-female", "name": "Female Voice", "language": "en"},
            ])
        
        return voices

# Global instance
tts_service = TTSService()
