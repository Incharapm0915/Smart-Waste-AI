from pydantic_settings import BaseSettings
from functools import lru_cache
from typing import Optional


class Settings(BaseSettings):
    # App
    app_name: str = "Smart Waste AI API"
    app_version: str = "1.0.0"
    debug: bool = False
    environment: str = "production"

    # CORS
    allowed_origins: list[str] = ["*"]

    # Groq
    groq_api_key: str = ""
    groq_model: str = "llama3-8b-8192"
    groq_fast_model: str = "llama3-70b-8192"

    # Firebase
    firebase_credentials_path: Optional[str] = None
    firebase_project_id: str = ""

    # OCR
    tesseract_path: Optional[str] = None

    # Rate limiting
    max_requests_per_minute: int = 30
    max_image_size_mb: int = 10

    # Hugging Face
    hf_model_name: str = "facebook/detr-resnet-50"
    use_local_model: bool = False

    class Config:
        env_file = ".env"
        case_sensitive = False


@lru_cache()
def get_settings() -> Settings:
    return Settings()
