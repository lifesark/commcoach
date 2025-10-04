from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Optional
from app.services.internet_service import internet_service
from app.routers.deps_supabase import get_current_user

router = APIRouter()

class TopicRequest(BaseModel):
    category: str = "general"
    count: int = 5

class PresentationTopicRequest(BaseModel):
    industry: str = "technology"
    count: int = 5

class InterviewQuestionsRequest(BaseModel):
    role: str = "software_engineer"
    count: int = 10

class FactsRequest(BaseModel):
    topic: str
    context: str = "debate"

@router.post("/topics/debate")
async def fetch_debate_topics(
    req: TopicRequest,
    user = Depends(get_current_user)
):
    """
    Fetch current debate topics from news and Wikipedia
    """
    try:
        topics = await internet_service.fetch_debate_topics(
            category=req.category,
            count=req.count
        )
        return {"topics": topics}
    except Exception as e:
        raise HTTPException(500, f"Failed to fetch debate topics: {str(e)}")

@router.post("/topics/presentation")
async def fetch_presentation_topics(
    req: PresentationTopicRequest,
    user = Depends(get_current_user)
):
    """
    Fetch presentation topics with relevant facts and examples
    """
    try:
        topics = await internet_service.fetch_presentation_topics(
            industry=req.industry,
            count=req.count
        )
        return {"topics": topics}
    except Exception as e:
        raise HTTPException(500, f"Failed to fetch presentation topics: {str(e)}")

@router.post("/questions/interview")
async def fetch_interview_questions(
    req: InterviewQuestionsRequest,
    user = Depends(get_current_user)
):
    """
    Fetch relevant interview questions based on role
    """
    try:
        questions = await internet_service.fetch_interview_questions(
            role=req.role,
            count=req.count
        )
        return {"questions": questions}
    except Exception as e:
        raise HTTPException(500, f"Failed to fetch interview questions: {str(e)}")

@router.post("/facts")
async def fetch_facts_and_examples(
    req: FactsRequest,
    user = Depends(get_current_user)
):
    """
    Fetch relevant facts and examples for a given topic
    """
    try:
        facts = await internet_service.fetch_facts_and_examples(
            topic=req.topic,
            context=req.context
        )
        return facts
    except Exception as e:
        raise HTTPException(500, f"Failed to fetch facts: {str(e)}")

@router.get("/categories")
async def get_available_categories():
    """
    Get list of available categories for topics
    """
    return {
        "categories": [
            "technology",
            "politics",
            "business",
            "science",
            "health",
            "education",
            "environment",
            "sports",
            "entertainment",
            "general"
        ]
    }

@router.get("/roles")
async def get_available_roles():
    """
    Get list of available roles for interview questions
    """
    return {
        "roles": [
            "software_engineer",
            "product_manager",
            "data_scientist",
            "marketing_manager",
            "sales_representative",
            "project_manager",
            "designer",
            "analyst",
            "consultant",
            "general"
        ]
    }
