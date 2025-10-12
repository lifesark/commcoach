from fastapi import APIRouter, Depends, HTTPException
from app.services.persona_service import persona_service, PersonaType
from app.routers.deps_supabase import get_current_user

router = APIRouter()

@router.get("/personas")
async def get_all_personas(user = Depends(get_current_user)):
    """
    Get all available AI personas
    """
    return {
        "personas": persona_service.get_all_personas()
    }

@router.get("/personas/{persona_type}")
async def get_persona_details(persona_type: str, user = Depends(get_current_user)):
    """
    Get detailed information about a specific persona
    """
    try:
        persona_enum = PersonaType(persona_type)
        persona = persona_service.get_persona(persona_enum)
        return persona
    except ValueError:
        raise HTTPException(404, f"Persona type '{persona_type}' not found")

@router.get("/personas/mode/{mode}")
async def get_persona_for_mode(mode: str, user = Depends(get_current_user)):
    """
    Get recommended persona for a specific practice mode
    """
    try:
        persona_enum = persona_service.get_persona_for_mode(mode)
        persona = persona_service.get_persona(persona_enum)
        return {
            "mode": mode,
            "recommended_persona": persona_enum.value,
            "persona": persona
        }
    except Exception as e:
        raise HTTPException(400, f"Invalid mode: {mode}")

@router.get("/modes")
async def get_available_modes():
    """
    Get list of available practice modes
    """
    return {
        "modes": [
            "debate",
            "interview", 
            "presentation",
            "casual",
            "general"
        ]
    }
