import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'supabase_service.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000'; // Change to your backend URL
  static const String wsUrl = 'ws://localhost:8000/realtime/ws';
  
  late final Dio _dio;
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
    
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = SupabaseService.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            // Handle unauthorized - redirect to login
            SupabaseService.signOut();
          }
          handler.next(error);
        },
      ),
    );
  }
  
  // Session Management
  Future<Map<String, dynamic>> createSession({
    required String mode,
    String? topic,
    bool randomTopic = false,
    bool fetchFromInternet = false,
    String? personaType,
    int prepS = 60,
    int turnS = 60,
    int rounds = 2,
  }) async {
    final response = await _dio.post('/session/config', data: {
      'mode': mode,
      'topic': topic,
      'random_topic': randomTopic,
      'fetch_from_internet': fetchFromInternet,
      'persona_type': personaType,
      'prep_s': prepS,
      'turn_s': turnS,
      'rounds': rounds,
    });
    
    return response.data;
  }
  
  // Feedback
  Future<Map<String, dynamic>> getFeedback(String sessionId) async {
    final response = await _dio.post('/feedback/session/$sessionId');
    return response.data;
  }
  
  // History
  Future<List<Map<String, dynamic>>> getHistory({int limit = 20}) async {
    final response = await _dio.get('/history', queryParameters: {'limit': limit});
    return List<Map<String, dynamic>>.from(response.data);
  }
  
  Future<Map<String, dynamic>> getSession(String sessionId) async {
    final response = await _dio.get('/history/$sessionId');
    return response.data;
  }
  
  // Personas
  Future<List<Map<String, dynamic>>> getPersonas() async {
    final response = await _dio.get('/personas');
    return List<Map<String, dynamic>>.from(response.data['personas']);
  }
  
  Future<Map<String, dynamic>> getPersonaForMode(String mode) async {
    final response = await _dio.get('/personas/mode/$mode');
    return response.data;
  }
  
  // Progress
  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _dio.get('/progress/dashboard');
    return response.data;
  }
  
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 10}) async {
    final response = await _dio.get('/progress/leaderboard', queryParameters: {'limit': limit});
    return List<Map<String, dynamic>>.from(response.data['leaderboard']);
  }
  
  Future<List<Map<String, dynamic>>> getBadges() async {
    final response = await _dio.get('/progress/badges');
    return List<Map<String, dynamic>>.from(response.data['badges']);
  }
  
  // Internet APIs
  Future<List<Map<String, dynamic>>> getDebateTopics({
    String category = 'general',
    int count = 5,
  }) async {
    final response = await _dio.post('/internet/topics/debate', data: {
      'category': category,
      'count': count,
    });
    return List<Map<String, dynamic>>.from(response.data['topics']);
  }
  
  Future<List<Map<String, dynamic>>> getPresentationTopics({
    String industry = 'technology',
    int count = 5,
  }) async {
    final response = await _dio.post('/internet/topics/presentation', data: {
      'industry': industry,
      'count': count,
    });
    return List<Map<String, dynamic>>.from(response.data['topics']);
  }
  
  Future<List<Map<String, dynamic>>> getInterviewQuestions({
    String role = 'software_engineer',
    int count = 10,
  }) async {
    final response = await _dio.post('/internet/questions/interview', data: {
      'role': role,
      'count': count,
    });
    return List<Map<String, dynamic>>.from(response.data['questions']);
  }
  
  Future<Map<String, dynamic>> getFacts({
    required String topic,
    String context = 'debate',
  }) async {
    final response = await _dio.post('/internet/facts', data: {
      'topic': topic,
      'context': context,
    });
    return response.data;
  }
  
  // TTS
  Future<Map<String, dynamic>> synthesizeSpeech({
    required String text,
    String? voice,
    String language = 'en',
  }) async {
    final response = await _dio.post('/tts/speak', data: {
      'text': text,
      'voice': voice,
      'language': language,
    });
    return response.data;
  }
  
  Future<List<Map<String, dynamic>>> getVoices() async {
    final response = await _dio.get('/tts/voices');
    return List<Map<String, dynamic>>.from(response.data['voices']);
  }
  
  // STT
  Future<Map<String, dynamic>> transcribeAudio({
    required String audioData, // base64 encoded
    String language = 'en',
  }) async {
    final response = await _dio.post('/stt/transcribe-base64', data: {
      'audio_data': audioData,
      'language': language,
    });
    return response.data;
  }
  
  // WebSocket
  WebSocketChannel createWebSocketChannel() {
    return WebSocketChannel.connect(Uri.parse(wsUrl));
  }
  
  // WebSocket Message Types
  static Map<String, dynamic> attachSessionMessage(String sessionId) => {
    'type': 'attach_session',
    'session_id': sessionId,
  };
  
  static Map<String, dynamic> startPrepMessage() => {
    'type': 'start_prep',
  };
  
  static Map<String, dynamic> startRoundMessage() => {
    'type': 'start_round',
  };
  
  static Map<String, dynamic> userTextMessage({
    required String text,
    String? personaType,
  }) => {
    'type': 'user_text',
    'text': text,
    'persona_type': personaType,
  };
  
  static Map<String, dynamic> endSessionMessage() => {
    'type': 'end',
  };
}
