import firebase_admin
from firebase_admin import credentials, firestore
from typing import Optional
import os
from .config import get_settings

_db: Optional[firestore.Client] = None


def init_firebase() -> Optional[firestore.Client]:
    global _db
    if _db is not None:
        return _db

    settings = get_settings()

    try:
        if not firebase_admin._apps:
            cred_path = settings.firebase_credentials_path
            if cred_path and os.path.exists(cred_path):
                cred = credentials.Certificate(cred_path)
                firebase_admin.initialize_app(cred)
            else:
                # Use application default credentials (works on GCP / Render with env vars)
                firebase_admin.initialize_app()

        _db = firestore.client()
        return _db
    except Exception as e:
        print(f"Firebase init failed (non-fatal for demo mode): {e}")
        return None


def get_db() -> Optional[firestore.Client]:
    return _db
