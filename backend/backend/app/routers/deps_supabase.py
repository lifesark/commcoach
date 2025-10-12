from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.core.settings import settings
import requests, json
import jwt
from jwt import algorithms
from cachetools import TTLCache

bearer = HTTPBearer(auto_error=False)
_jwks_cache = TTLCache(maxsize=2, ttl=settings.SUPABASE_JWKS_CACHE_SECONDS)

def _get_jwks():
    if "jwks" in _jwks_cache:
        return _jwks_cache["jwks"]
    url = f"{settings.SUPABASE_URL}/auth/v1/keys"
    resp = requests.get(url, timeout=10)
    resp.raise_for_status()
    jwks = resp.json()
    _jwks_cache["jwks"] = jwks
    return jwks

def _public_key_for(token):
    headers = jwt.get_unverified_header(token)
    kid = headers.get("kid")
    jwks = _get_jwks()
    for key in jwks["keys"]:
        if key.get("kid") == kid:
            return algorithms.RSAAlgorithm.from_jwk(json.dumps(key))
    raise HTTPException(status_code=401, detail="No matching JWKS key")

def get_current_user(creds: HTTPAuthorizationCredentials = Depends(bearer)):
    if not creds:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing token")
    token = creds.credentials
    try:
        pub = _public_key_for(token)
        claims = jwt.decode(token, pub, algorithms=["RS256"], audience=None, options={"verify_aud": False})
        return {"sub": claims.get("sub"), "email": claims.get("email")}
    except jwt.PyJWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
