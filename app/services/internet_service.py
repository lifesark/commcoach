import asyncio
import httpx
from typing import List, Dict, Optional
from app.core.settings import settings
import wikipedia
import json
from datetime import datetime, timedelta

class InternetService:
    def __init__(self):
        self.news_api_key = settings.NEWS_API_KEY
        self.wikipedia_enabled = settings.WIKIPEDIA_ENABLED
        
        # Configure Wikipedia
        if self.wikipedia_enabled:
            wikipedia.set_lang("en")
            wikipedia.set_rate_limiting(True)

    async def fetch_debate_topics(self, category: str = "general", count: int = 5) -> List[Dict]:
        """
        Fetch current debate topics from news and Wikipedia
        """
        topics = []
        
        # Get topics from news
        if self.news_api_key:
            news_topics = await self._fetch_news_topics(category, count)
            topics.extend(news_topics)
        
        # Get topics from Wikipedia if needed
        if len(topics) < count and self.wikipedia_enabled:
            wiki_topics = await self._fetch_wikipedia_topics(category, count - len(topics))
            topics.extend(wiki_topics)
        
        return topics[:count]

    async def fetch_presentation_topics(self, industry: str = "technology", count: int = 5) -> List[Dict]:
        """
        Fetch presentation topics with relevant facts and examples
        """
        topics = []
        
        # Get current tech/industry news
        if self.news_api_key:
            news_topics = await self._fetch_news_topics(industry, count)
            topics.extend(news_topics)
        
        # Get Wikipedia topics if needed
        if len(topics) < count and self.wikipedia_enabled:
            wiki_topics = await self._fetch_wikipedia_topics(industry, count - len(topics))
            topics.extend(wiki_topics)
        
        return topics[:count]

    async def fetch_interview_questions(self, role: str = "software_engineer", count: int = 10) -> List[Dict]:
        """
        Fetch relevant interview questions based on role
        """
        questions = []
        
        # Role-specific questions
        role_questions = {
            "software_engineer": [
                "Tell me about a challenging technical problem you solved",
                "How do you approach debugging complex issues?",
                "Describe your experience with version control and collaboration",
                "What's your process for code review and quality assurance?",
                "How do you stay updated with new technologies?"
            ],
            "product_manager": [
                "How do you prioritize features in a product roadmap?",
                "Describe a time you had to make a difficult product decision",
                "How do you gather and analyze user feedback?",
                "What's your approach to stakeholder management?",
                "How do you measure product success?"
            ],
            "data_scientist": [
                "Walk me through your data analysis process",
                "How do you handle missing or incomplete data?",
                "Describe a time you found unexpected insights in data",
                "What's your experience with machine learning models?",
                "How do you communicate technical findings to non-technical stakeholders?"
            ]
        }
        
        base_questions = role_questions.get(role, role_questions["software_engineer"])
        questions.extend([{"question": q, "category": "technical", "difficulty": "medium"} for q in base_questions])
        
        # Add behavioral questions
        behavioral_questions = [
            "Tell me about a time you failed and what you learned",
            "Describe a situation where you had to work with a difficult team member",
            "How do you handle tight deadlines and competing priorities?",
            "Give me an example of a time you had to learn something new quickly",
            "Describe a project you're particularly proud of"
        ]
        
        questions.extend([{"question": q, "category": "behavioral", "difficulty": "medium"} for q in behavioral_questions])
        
        return questions[:count]

    async def fetch_facts_and_examples(self, topic: str, context: str = "debate") -> Dict:
        """
        Fetch relevant facts and examples for a given topic
        """
        facts = {
            "topic": topic,
            "context": context,
            "facts": [],
            "examples": [],
            "statistics": [],
            "sources": []
        }
        
        # Get Wikipedia information
        if self.wikipedia_enabled:
            wiki_info = await self._fetch_wikipedia_facts(topic)
            facts.update(wiki_info)
        
        # Get news information
        if self.news_api_key:
            news_info = await self._fetch_news_facts(topic)
            facts["facts"].extend(news_info.get("facts", []))
            facts["examples"].extend(news_info.get("examples", []))
            facts["sources"].extend(news_info.get("sources", []))
        
        return facts

    async def _fetch_news_topics(self, category: str, count: int) -> List[Dict]:
        """
        Fetch topics from news API
        """
        if not self.news_api_key:
            return []
        
        try:
            async with httpx.AsyncClient() as client:
                url = "https://newsapi.org/v2/everything"
                params = {
                    "apiKey": self.news_api_key,
                    "q": category,
                    "sortBy": "publishedAt",
                    "pageSize": count,
                    "language": "en"
                }
                
                response = await client.get(url, params=params)
                response.raise_for_status()
                
                data = response.json()
                articles = data.get("articles", [])
                
                topics = []
                for article in articles:
                    if article.get("title") and article.get("description"):
                        topics.append({
                            "title": article["title"],
                            "description": article["description"],
                            "source": article.get("source", {}).get("name", "Unknown"),
                            "url": article.get("url", ""),
                            "published_at": article.get("publishedAt", ""),
                            "category": "news"
                        })
                
                return topics
                
        except Exception as e:
            print(f"News API error: {e}")
            return []

    async def _fetch_wikipedia_topics(self, category: str, count: int) -> List[Dict]:
        """
        Fetch topics from Wikipedia
        """
        if not self.wikipedia_enabled:
            return []
        
        try:
            # Search for articles related to the category
            search_results = wikipedia.search(category, results=count)
            
            topics = []
            for title in search_results:
                try:
                    page = wikipedia.page(title)
                    topics.append({
                        "title": title,
                        "description": page.summary[:200] + "..." if len(page.summary) > 200 else page.summary,
                        "source": "Wikipedia",
                        "url": page.url,
                        "category": "wikipedia"
                    })
                except:
                    continue
            
            return topics
            
        except Exception as e:
            print(f"Wikipedia error: {e}")
            return []

    async def _fetch_wikipedia_facts(self, topic: str) -> Dict:
        """
        Fetch facts from Wikipedia for a topic
        """
        if not self.wikipedia_enabled:
            return {"facts": [], "examples": [], "sources": []}
        
        try:
            page = wikipedia.page(topic)
            
            # Extract key facts from summary
            summary = page.summary
            facts = []
            
            # Look for numbers and statistics
            import re
            numbers = re.findall(r'\d+(?:\.\d+)?%?', summary)
            if numbers:
                facts.append(f"Key statistics: {', '.join(numbers[:3])}")
            
            # Extract examples (sentences with "for example" or "such as")
            examples = []
            sentences = summary.split('.')
            for sentence in sentences:
                if any(phrase in sentence.lower() for phrase in ['for example', 'such as', 'including']):
                    examples.append(sentence.strip())
            
            return {
                "facts": [summary[:300] + "..." if len(summary) > 300 else summary],
                "examples": examples[:3],
                "sources": [{"name": "Wikipedia", "url": page.url}]
            }
            
        except Exception as e:
            print(f"Wikipedia facts error: {e}")
            return {"facts": [], "examples": [], "sources": []}

    async def _fetch_news_facts(self, topic: str) -> Dict:
        """
        Fetch facts from news API for a topic
        """
        if not self.news_api_key:
            return {"facts": [], "examples": [], "sources": []}
        
        try:
            async with httpx.AsyncClient() as client:
                url = "https://newsapi.org/v2/everything"
                params = {
                    "apiKey": self.news_api_key,
                    "q": topic,
                    "sortBy": "relevancy",
                    "pageSize": 5,
                    "language": "en"
                }
                
                response = await client.get(url, params=params)
                response.raise_for_status()
                
                data = response.json()
                articles = data.get("articles", [])
                
                facts = []
                examples = []
                sources = []
                
                for article in articles:
                    if article.get("description"):
                        facts.append(article["description"])
                    if article.get("content"):
                        examples.append(article["content"][:200] + "...")
                    if article.get("source"):
                        sources.append({
                            "name": article["source"].get("name", "Unknown"),
                            "url": article.get("url", "")
                        })
                
                return {
                    "facts": facts[:3],
                    "examples": examples[:3],
                    "sources": sources[:3]
                }
                
        except Exception as e:
            print(f"News facts error: {e}")
            return {"facts": [], "examples": [], "sources": []}

# Global instance
internet_service = InternetService()
