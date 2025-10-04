from pydantic_settings import BaseSettings
from pydantic import Field
from typing import List

class Settings(BaseSettings):
    COMMCOACH_ENV: str = Field("prod", env="COMMCOACH_ENV")
    API_ORIGINS: str = Field("*", env="API_ORIGINS")

    # DB
    DATABASE_URL: str = Field(..., env="DATABASE_URL")

    # Supabase
    SUPABASE_URL: str = Field(..., env="SUPABASE_URL")
    SUPABASE_ANON_KEY: str = Field(..., env="SUPABASE_ANON_KEY")
    SUPABASE_SERVICE_ROLE_KEY: str = Field(..., env="SUPABASE_SERVICE_ROLE_KEY")
    SUPABASE_JWKS_CACHE_SECONDS: int = Field(86400, env="SUPABASE_JWKS_CACHE_SECONDS")

    # LLM: Gemini
    GEMINI_API_KEY: str = Field(..., env="GEMINI_API_KEY")
    GEMINI_MODEL: str = Field("gemini-1.5-pro-latest", env="GEMINI_MODEL")
    
    # Voice Processing
    GEMINI_STT_ENABLED: bool = Field(True, env="GEMINI_STT_ENABLED")
    GEMINI_TTS_ENABLED: bool = Field(True, env="GEMINI_TTS_ENABLED")
    PLAYHT_API_KEY: str = Field("", env="PLAYHT_API_KEY")
    PLAYHT_USER_ID: str = Field("", env="PLAYHT_USER_ID")
    
    # Internet APIs
    NEWS_API_KEY: str = Field("", env="NEWS_API_KEY")
    WIKIPEDIA_ENABLED: bool = Field(True, env="WIKIPEDIA_ENABLED")
    
    # Audio Processing
    MAX_AUDIO_SIZE_MB: int = Field(10, env="MAX_AUDIO_SIZE_MB")
    SUPPORTED_AUDIO_FORMATS: str = Field("wav,mp3,m4a,ogg", env="SUPPORTED_AUDIO_FORMATS")

    @property
    def origins_list(self) -> List[str]:
        return [o.strip() for o in self.API_ORIGINS.split(",") if o.strip()]

    class Config:
        env_file = ".env"
        extra = "ignore"  # Ignore extra fields to prevent validation errors

settings = Settings()
