class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://localhost:8000';
  static const String wsUrl = 'ws://localhost:8000/realtime/ws';
  
  // Audio Configuration
  static const int maxAudioDurationSeconds = 60;
  static const int sampleRate = 44100;
  static const int numChannels = 1;
  
  // Session Configuration
  static const int defaultPrepTime = 60;
  static const int defaultTurnTime = 60;
  static const int defaultRounds = 2;
  
  // Progress Configuration
  static const int xpPerSession = 100;
  static const int xpPerLevel = 1000;
  static const int maxLevel = 100;
  
  // UI Configuration
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  static const double buttonHeight = 48.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Storage Keys
  static const String captionsEnabledKey = 'captions_enabled';
  static const String selectedVoiceKey = 'selected_voice';
  static const String lastSessionKey = 'last_session';
  
  // Error Messages
  static const String networkError = 'Network error. Please check your connection.';
  static const String micPermissionError = 'Microphone permission is required.';
  static const String sessionError = 'Session error. Please try again.';
  static const String authError = 'Authentication error. Please sign in again.';
  
  // Success Messages
  static const String sessionCreated = 'Session created successfully!';
  static const String feedbackGenerated = 'Feedback generated successfully!';
  static const String progressUpdated = 'Progress updated!';
  
  // Practice Modes
  static const List<String> practiceModes = [
    'debate',
    'interview',
    'presentation',
    'casual',
  ];
  
  // Persona Types
  static const List<String> personaTypes = [
    'friendly_mentor',
    'socratic_judge',
    'hiring_manager',
    'debate_champion',
    'presentation_coach',
    'casual_conversationalist',
  ];
  
  // Audio Formats
  static const List<String> supportedAudioFormats = [
    'wav',
    'mp3',
    'm4a',
    'ogg',
  ];
}
