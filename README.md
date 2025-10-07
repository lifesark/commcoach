# CommCoach Backend API

A comprehensive voice-first communication coaching platform built with FastAPI, Supabase, and Gemini AI.

## Features

### Core Functionality
- **Real-time Voice Communication**: WebSocket-based voice conversations with AI personas
- **Multiple Practice Modes**: Debate, Interview, Presentation, Casual Conversation
- **AI Personas**: 6 different coaching personalities (Friendly Mentor, Socratic Judge, Hiring Manager, etc.)
- **Advanced Feedback System**: Sophisticated scoring for clarity, structure, persuasiveness, and fluency
- **Progress Tracking**: XP, levels, streaks, badges, and leaderboards
- **Internet Integration**: Dynamic topic fetching from Wikipedia and News APIs

### Voice Processing
- **Speech-to-Text (STT)**: Gemini STT integration with audio format validation
- **Text-to-Speech (TTS)**: Multiple voice options with PlayHT support
- **Audio Processing**: Support for WAV, MP3, M4A, OGG formats

### AI & LLM
- **Gemini Integration**: Advanced language model for natural conversations
- **Persona System**: Context-aware AI responses based on practice mode
- **Streaming Responses**: Real-time token streaming for better UX

## Tech Stack

- **Backend**: FastAPI, SQLAlchemy, Alembic
- **Database**: PostgreSQL (via Supabase)
- **Authentication**: Supabase Auth with JWT
- **AI/LLM**: Google Gemini API
- **Voice**: Gemini STT/TTS, PlayHT TTS
- **Internet APIs**: Wikipedia, NewsAPI
- **Real-time**: WebSockets
- **Storage**: Supabase Storage

## API Endpoints

### Authentication
- All endpoints require Supabase JWT authentication
- User context available via `get_current_user` dependency

### Core Endpoints

#### Sessions
- `POST /session/config` - Create new practice session
- `GET /history` - Get user session history
- `GET /history/{session_id}` - Get specific session details

#### Real-time Communication
- `WebSocket /realtime/ws` - Real-time voice/text conversation
- Supports persona selection and streaming responses

#### Voice Processing
- `POST /stt/transcribe` - Upload audio file for transcription
- `POST /stt/transcribe-base64` - Transcribe base64 audio data
- `POST /tts/speak` - Convert text to speech
- `GET /tts/voices` - Get available voices

#### Feedback & Analysis
- `POST /feedback/session/{session_id}` - Generate session feedback
- Enhanced scoring with personalized tips

#### Progress Tracking
- `GET /progress/dashboard` - User progress dashboard
- `GET /progress/leaderboard` - Global leaderboard
- `GET /progress/badges` - Available badges
- `GET /progress/stats` - Detailed user statistics

#### AI Personas
- `GET /personas` - List all available personas
- `GET /personas/{persona_type}` - Get persona details
- `GET /personas/mode/{mode}` - Get recommended persona for mode

#### Internet Integration
- `POST /internet/topics/debate` - Fetch debate topics
- `POST /internet/topics/presentation` - Fetch presentation topics
- `POST /internet/questions/interview` - Fetch interview questions
- `POST /internet/facts` - Get facts and examples for topics

## Environment Variables

Create a `.env` file in the backend directory:

```env
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/commcoach

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
SUPABASE_JWKS_CACHE_SECONDS=86400

# Gemini AI
GEMINI_API_KEY=your-gemini-api-key
GEMINI_MODEL=gemini-1.5-pro-latest
GEMINI_STT_ENABLED=true
GEMINI_TTS_ENABLED=true

# PlayHT TTS (optional)
PLAYHT_API_KEY=your-playht-api-key
PLAYHT_USER_ID=your-playht-user-id

# Internet APIs
NEWS_API_KEY=your-news-api-key
WIKIPEDIA_ENABLED=true

# Audio Processing
MAX_AUDIO_SIZE_MB=10
SUPPORTED_AUDIO_FORMATS=wav,mp3,m4a,ogg

# CORS
API_ORIGINS=http://localhost:3000,https://your-frontend.com
```

## Installation & Setup

1. **Install Dependencies**
   ```bash
   pip install -r requirements.txt
   ```

2. **Database Setup**
   ```bash
   # Run migrations
   alembic upgrade head
   ```

3. **Environment Configuration**
   - Copy `.env.example` to `.env`
   - Fill in your API keys and database credentials

4. **Run Development Server**
   ```bash
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

## Database Schema

### Sessions
- `id`: UUID primary key
- `user_id`: Supabase user ID
- `mode`: Practice mode (debate, interview, presentation, casual)
- `topic`: Session topic/question
- `config`: JSON configuration (timers, rounds, persona)
- `state`: Session state (created, prep, live, ended)
- `messages`: Related conversation messages

### User Progress
- `user_id`: Supabase user ID
- `total_sessions`: Total practice sessions
- `total_xp`: Total experience points
- `current_level`: User's current level
- `current_streak`: Current daily streak
- `badges`: JSON array of earned badges
- `stats`: JSON object with mode-specific statistics

### Feedback
- `session_id`: Reference to session
- `clarity`: Clarity score (0-100)
- `structure`: Structure score (0-100)
- `persuasiveness`: Persuasiveness score (0-100)
- `fluency`: Fluency score (0-100)
- `time_score`: Timing score (0-100)
- `overall`: Overall score (0-100)
- `tips`: JSON array of personalized tips

## AI Personas

### Available Personas
1. **Friendly Mentor** - Supportive, encouraging coach
2. **Socratic Judge** - Critical thinking facilitator
3. **Hiring Manager** - Professional interviewer
4. **Debate Champion** - Skilled debater and coach
5. **Presentation Coach** - Public speaking expert
6. **Casual Conversationalist** - Everyday conversation partner

### Persona Selection
- Automatic selection based on practice mode
- Manual override via API parameters
- Context-aware responses based on session type

## Progress System

### XP & Levels
- Base XP: 100 per session
- Performance multipliers based on scores
- Level up every 1000 XP
- Maximum level: 100

### Badges
- **Achievement Badges**: First session, high scores, perfect sessions
- **Streak Badges**: 3, 7, 30 day streaks
- **Level Badges**: Milestone levels (5, 10, etc.)
- **Mode Badges**: Mastery in specific practice modes

### Streaks
- Daily practice tracking
- Automatic streak calculation
- Longest streak recording

## WebSocket Protocol

### Client → Server
```json
{
  "type": "attach_session",
  "session_id": "uuid"
}

{
  "type": "user_text",
  "text": "User's message",
  "persona_type": "friendly_mentor"
}

{
  "type": "start_round"
}

{
  "type": "end"
}
```

### Server → Client
```json
{
  "type": "session_attached",
  "session_id": "uuid",
  "config": {...},
  "topic": "Topic text"
}

{
  "type": "ai_reply_start"
}

{
  "type": "ai_token",
  "token": "streaming text"
}

{
  "type": "ai_reply_end",
  "text": "complete response"
}

{
  "type": "turn_switched",
  "turn": "user"
}
```

## Error Handling

- Comprehensive error responses with HTTP status codes
- Graceful fallbacks for AI service failures
- Detailed logging for debugging
- Rate limiting with SlowAPI

## Performance Considerations

- Database connection pooling
- JWT caching for authentication
- Streaming responses for real-time feel
- Efficient audio processing
- Cached internet API responses

## Security

- JWT-based authentication via Supabase
- CORS configuration
- Input validation and sanitization
- Rate limiting
- Secure environment variable handling

## Monitoring & Logging

- Structured logging with timestamps
- Health check endpoint
- Performance metrics
- Error tracking

## Development

### Running Tests
```bash
pytest tests/
```

### Code Quality
- Type hints throughout
- Pydantic models for validation
- SQLAlchemy ORM for database operations
- Async/await for I/O operations

## Deployment

### Docker
```bash
docker build -t commcoach-backend .
docker run -p 8000:8000 commcoach-backend
```

### Environment
- Production environment variables
- Database connection pooling
- Load balancing considerations
- Monitoring and alerting

## Contributing

1. Follow existing code patterns
2. Add type hints to new functions
3. Include docstrings for public APIs
4. Write tests for new features
5. Update documentation as needed

## License

See LICENSE file for details.
