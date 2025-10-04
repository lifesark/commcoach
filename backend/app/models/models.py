from sqlalchemy import Column, String, Integer, DateTime, Text, ForeignKey, JSON, Index
from sqlalchemy.orm import relationship
from datetime import datetime
from app.core.db import Base

class Session(Base):
    __tablename__ = "sessions"
    id = Column(String, primary_key=True)        # uuid string
    user_id = Column(String, index=True)         # Supabase auth.uid()
    mode = Column(String, default="debate")
    topic = Column(String, nullable=True)
    config = Column(JSON, default=dict)          # {prep_s, turn_s, rounds}
    state = Column(String, default="created")    # created|prep|live|ended
    round_no = Column(Integer, default=0)
    turn = Column(String, default="user")        # user|ai
    started_at = Column(DateTime, default=datetime.utcnow)
    ended_at = Column(DateTime, nullable=True)

    messages = relationship("Message", back_populates="session", cascade="all, delete-orphan")

Index("idx_sessions_user_started", Session.user_id, Session.started_at)

class Message(Base):
    __tablename__ = "messages"
    id = Column(Integer, primary_key=True)
    session_id = Column(String, ForeignKey("sessions.id", ondelete="CASCADE"))
    role = Column(String)          # "user" | "ai" | "system"
    content = Column(Text)
    time = Column(DateTime, default=datetime.utcnow)
    session = relationship("Session", back_populates="messages")

class Feedback(Base):
    __tablename__ = "feedback"
    id = Column(Integer, primary_key=True)
    session_id = Column(String, ForeignKey("sessions.id", ondelete="CASCADE"), index=True)
    clarity = Column(Integer)
    structure = Column(Integer)
    persuasiveness = Column(Integer)
    fluency = Column(Integer)
    time_score = Column(Integer)
    overall = Column(Integer)
    tips = Column(Text)  # JSON string
    created_at = Column(DateTime, default=datetime.utcnow)
