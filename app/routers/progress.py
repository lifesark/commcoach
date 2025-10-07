from fastapi import APIRouter, Depends, HTTPException
from typing import List, Dict
from app.services.progress_service import progress_service
from app.routers.deps_supabase import get_current_user

router = APIRouter()

@router.get("/dashboard")
async def get_user_dashboard(user = Depends(get_current_user)):
    """
    Get user's progress dashboard with stats, badges, and recent sessions
    """
    try:
        dashboard = progress_service.get_user_dashboard(user["sub"])
        return dashboard
    except Exception as e:
        raise HTTPException(500, f"Failed to get dashboard: {str(e)}")

@router.get("/leaderboard")
async def get_leaderboard(limit: int = 10):
    """
    Get top users leaderboard
    """
    try:
        leaderboard = progress_service.get_leaderboard(limit)
        return {"leaderboard": leaderboard}
    except Exception as e:
        raise HTTPException(500, f"Failed to get leaderboard: {str(e)}")

@router.get("/badges")
async def get_available_badges():
    """
    Get all available badges
    """
    try:
        badges = list(progress_service.badges.values())
        return {"badges": badges}
    except Exception as e:
        raise HTTPException(500, f"Failed to get badges: {str(e)}")

@router.get("/stats")
async def get_user_stats(user = Depends(get_current_user)):
    """
    Get detailed user statistics
    """
    try:
        progress = progress_service.get_or_create_progress(user["sub"])
        return {
            "total_sessions": progress.total_sessions,
            "total_xp": progress.total_xp,
            "current_level": progress.current_level,
            "current_streak": progress.current_streak,
            "longest_streak": progress.longest_streak,
            "badges_earned": len(progress.badges),
            "mode_stats": progress.stats
        }
    except Exception as e:
        raise HTTPException(500, f"Failed to get stats: {str(e)}")

@router.post("/update")
async def update_progress(
    session_id: str,
    feedback_data: Dict,
    user = Depends(get_current_user)
):
    """
    Update user progress after a session (called internally)
    """
    try:
        result = progress_service.update_progress(user["sub"], session_id, feedback_data)
        return result
    except Exception as e:
        raise HTTPException(500, f"Failed to update progress: {str(e)}")
