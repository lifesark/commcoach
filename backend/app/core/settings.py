from pydantic import BaseSettings, Field
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

    @property
    def origins_list(self) -> List[str]:
        return [o.strip() for o in self.API_ORIGINS.split(",") if o.strip()]

    class Config:
        env_file = ".env"

settings = Settings()
