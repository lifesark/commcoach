from supabase import create_client, Client
from app.core.settings import settings
from datetime import datetime
import json

def supa_client() -> Client:
    return create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_ROLE_KEY)

def put_json(bucket: str, path: str, obj: dict, upsert: bool = True):
    client = supa_client()
    data = json.dumps(obj, ensure_ascii=False, indent=2).encode("utf-8")
    return client.storage.from_(bucket).upload(path=path, file=data, file_options={"contentType":"application/json","upsert": upsert})

def transcript_path(user_id: str, session_id: str) -> str:
    dt = datetime.utcnow().strftime("%Y%m%d")
    return f"{user_id or 'anon'}/{dt}/{session_id}.json"
