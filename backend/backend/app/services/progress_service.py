from typing import Dict, List, Optional
from datetime import datetime, timedelta
from app.core.db import SessionLocal
from app.models.models import UserProgress, Session, Feedback
from sqlalchemy import func, desc
import json

class ProgressService:
    def __init__(self):
        self.xp_per_session = 100  # Base XP per session
        self.xp_per_level = 1000  # XP needed to level up
        self.badges = self._initialize_badges()

    def _initialize_badges(self) -> Dict[str, Dict]:
        """Initialize available badges"""
        return {
            "first_session": {
                "name": "Getting Started",
                "description": "Complete your first practice session",
                "icon": "🎯",
                "xp_reward": 50
            },
            "streak_3": {
                "name": "On Fire",
                "description": "Practice for 3 days in a row",
                "icon": "🔥",
                "xp_reward": 100
            },
            "streak_7": {
                "name": "Consistent",
                "description": "Practice for 7 days in a row",
                "icon": "⭐",
                "xp_reward": 250
            },
            "streak_30": {
                "name": "Dedicated",
                "description": "Practice for 30 days in a row",
                "icon": "🏆",
                "xp_reward": 1000
            },
            "level_5": {
                "name": "Rising Star",
                "description": "Reach level 5",
                "icon": "🌟",
                "xp_reward": 0
            },
            "level_10": {
                "name": "Expert",
                "description": "Reach level 10",
                "icon": "💎",
                "xp_reward": 0
            },
            "debate_master": {
                "name": "Debate Master",
                "description": "Complete 10 debate sessions",
                "icon": "⚔️",
                "xp_reward": 200
            },
            "interview_pro": {
                "name": "Interview Pro",
                "description": "Complete 10 interview sessions",
                "icon": "💼",
                "xp_reward": 200
            },
            "presentation_guru": {
                "name": "Presentation Guru",
                "description": "Complete 10 presentation sessions",
                "icon": "🎤",
                "xp_reward": 200
            },
            "high_score": {
                "name": "High Achiever",
                "description": "Score 90+ overall in a session",
                "icon": "🎯",
                "xp_reward": 150
            },
            "perfect_session": {
                "name": "Perfect Session",
                "description": "Score 95+ in all categories",
                "icon": "💯",
                "xp_reward": 300
            }
        }

    def get_or_create_progress(self, user_id: str) -> UserProgress:
        """Get user progress or create if doesn't exist"""
        with SessionLocal() as db:
            progress = db.query(UserProgress).filter(UserProgress.user_id == user_id).first()
            if not progress:
                progress = UserProgress(
                    user_id=user_id,
                    total_sessions=0,
                    total_xp=0,
                    current_level=1,
                    current_streak=0,
                    longest_streak=0,
                    badges=[],
                    stats={}
                )
                db.add(progress)
                db.commit()
            return progress

    def update_progress(self, user_id: str, session_id: str, feedback_data: Dict) -> Dict:
        """Update user progress after a session"""
        with SessionLocal() as db:
            progress = self.get_or_create_progress(user_id)
            
            # Calculate XP for this session
            session_xp = self._calculate_session_xp(feedback_data)
            
            # Update basic stats
            progress.total_sessions += 1
            progress.total_xp += session_xp
            
            # Update streak
            self._update_streak(progress)
            
            # Check for level up
            new_level = self._calculate_level(progress.total_xp)
            leveled_up = new_level > progress.current_level
            progress.current_level = new_level
            
            # Update mode-specific stats
            session = db.query(Session).filter(Session.id == session_id).first()
            if session:
                self._update_mode_stats(progress, session.mode, feedback_data)
            
            # Check for new badges
            new_badges = self._check_badges(progress, feedback_data)
            if new_badges:
                progress.badges.extend(new_badges)
                # Add XP for new badges
                for badge_id in new_badges:
                    progress.total_xp += self.badges[badge_id]["xp_reward"]
            
            progress.updated_at = datetime.utcnow()
            db.commit()
            
            return {
                "session_xp": session_xp,
                "total_xp": progress.total_xp,
                "level": progress.current_level,
                "streak": progress.current_streak,
                "new_badges": new_badges,
                "leveled_up": leveled_up
            }

    def _calculate_session_xp(self, feedback_data: Dict) -> int:
        """Calculate XP for a session based on performance"""
        overall_score = feedback_data.get("overall", 0)
        
        # Base XP
        base_xp = self.xp_per_session
        
        # Performance multiplier
        if overall_score >= 95:
            multiplier = 1.5
        elif overall_score >= 90:
            multiplier = 1.3
        elif overall_score >= 80:
            multiplier = 1.1
        elif overall_score >= 70:
            multiplier = 1.0
        else:
            multiplier = 0.8
        
        return int(base_xp * multiplier)

    def _update_streak(self, progress: UserProgress):
        """Update user streak"""
        today = datetime.utcnow().date()
        
        if progress.last_session_date:
            last_date = progress.last_session_date.date()
            if last_date == today:
                # Already practiced today, no change
                return
            elif last_date == today - timedelta(days=1):
                # Consecutive day, increment streak
                progress.current_streak += 1
            else:
                # Streak broken, reset
                progress.current_streak = 1
        else:
            # First session
            progress.current_streak = 1
        
        # Update longest streak
        if progress.current_streak > progress.longest_streak:
            progress.longest_streak = progress.current_streak
        
        progress.last_session_date = datetime.utcnow()

    def _calculate_level(self, total_xp: int) -> int:
        """Calculate user level based on total XP"""
        return min(100, (total_xp // self.xp_per_level) + 1)

    def _update_mode_stats(self, progress: UserProgress, mode: str, feedback_data: Dict):
        """Update mode-specific statistics"""
        if not progress.stats:
            progress.stats = {}
        
        if mode not in progress.stats:
            progress.stats[mode] = {
                "sessions": 0,
                "total_score": 0,
                "best_score": 0,
                "average_score": 0
            }
        
        mode_stats = progress.stats[mode]
        mode_stats["sessions"] += 1
        mode_stats["total_score"] += feedback_data.get("overall", 0)
        mode_stats["best_score"] = max(mode_stats["best_score"], feedback_data.get("overall", 0))
        mode_stats["average_score"] = mode_stats["total_score"] / mode_stats["sessions"]

    def _check_badges(self, progress: UserProgress, feedback_data: Dict) -> List[str]:
        """Check for new badges earned"""
        new_badges = []
        current_badges = set(progress.badges)
        
        # First session badge
        if progress.total_sessions == 1 and "first_session" not in current_badges:
            new_badges.append("first_session")
        
        # Streak badges
        if progress.current_streak >= 3 and "streak_3" not in current_badges:
            new_badges.append("streak_3")
        if progress.current_streak >= 7 and "streak_7" not in current_badges:
            new_badges.append("streak_7")
        if progress.current_streak >= 30 and "streak_30" not in current_badges:
            new_badges.append("streak_30")
        
        # Level badges
        if progress.current_level >= 5 and "level_5" not in current_badges:
            new_badges.append("level_5")
        if progress.current_level >= 10 and "level_10" not in current_badges:
            new_badges.append("level_10")
        
        # Mode-specific badges
        for mode, stats in progress.stats.items():
            if mode == "debate" and stats["sessions"] >= 10 and "debate_master" not in current_badges:
                new_badges.append("debate_master")
            elif mode == "interview" and stats["sessions"] >= 10 and "interview_pro" not in current_badges:
                new_badges.append("interview_pro")
            elif mode == "presentation" and stats["sessions"] >= 10 and "presentation_guru" not in current_badges:
                new_badges.append("presentation_guru")
        
        # Performance badges
        overall_score = feedback_data.get("overall", 0)
        if overall_score >= 90 and "high_score" not in current_badges:
            new_badges.append("high_score")
        
        # Perfect session badge
        if (feedback_data.get("clarity", 0) >= 95 and 
            feedback_data.get("structure", 0) >= 95 and 
            feedback_data.get("persuasiveness", 0) >= 95 and 
            feedback_data.get("fluency", 0) >= 95 and 
            "perfect_session" not in current_badges):
            new_badges.append("perfect_session")
        
        return new_badges

    def get_user_dashboard(self, user_id: str) -> Dict:
        """Get user dashboard data"""
        with SessionLocal() as db:
            progress = self.get_or_create_progress(user_id)
            
            # Get recent sessions
            recent_sessions = (db.query(Session)
                             .filter(Session.user_id == user_id)
                             .order_by(desc(Session.started_at))
                             .limit(10)
                             .all())
            
            # Get leaderboard position (simplified)
            total_users = db.query(UserProgress).count()
            users_ahead = db.query(UserProgress).filter(UserProgress.total_xp > progress.total_xp).count()
            leaderboard_position = users_ahead + 1 if users_ahead < total_users else total_users
            
            return {
                "user_id": user_id,
                "level": progress.current_level,
                "total_xp": progress.total_xp,
                "xp_to_next_level": self.xp_per_level - (progress.total_xp % self.xp_per_level),
                "current_streak": progress.current_streak,
                "longest_streak": progress.longest_streak,
                "total_sessions": progress.total_sessions,
                "badges": [self.badges[badge_id] for badge_id in progress.badges],
                "stats": progress.stats,
                "recent_sessions": [
                    {
                        "id": s.id,
                        "mode": s.mode,
                        "topic": s.topic,
                        "started_at": s.started_at.isoformat(),
                        "ended_at": s.ended_at.isoformat() if s.ended_at else None
                    }
                    for s in recent_sessions
                ],
                "leaderboard_position": leaderboard_position,
                "total_users": total_users
            }

    def get_leaderboard(self, limit: int = 10) -> List[Dict]:
        """Get top users leaderboard"""
        with SessionLocal() as db:
            top_users = (db.query(UserProgress)
                        .order_by(desc(UserProgress.total_xp))
                        .limit(limit)
                        .all())
            
            return [
                {
                    "user_id": user.user_id,
                    "level": user.current_level,
                    "total_xp": user.total_xp,
                    "current_streak": user.current_streak,
                    "total_sessions": user.total_sessions,
                    "badge_count": len(user.badges)
                }
                for user in top_users
            ]

# Global instance
progress_service = ProgressService()
