import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../theme/theme.dart';
import '../../services/voice_service.dart';
import '../../services/api_service.dart';
import '../../widgets/mic_button.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/timer_widget.dart';
import '../../widgets/waveform_widget.dart';

class PracticeRoomScreen extends ConsumerStatefulWidget {
  final String sessionId;
  
  const PracticeRoomScreen({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<PracticeRoomScreen> createState() => _PracticeRoomScreenState();
}

class _PracticeRoomScreenState extends ConsumerState<PracticeRoomScreen> {
  late WebSocketChannel _channel;
  late VoiceService _voiceService;
  
  // Session state
  String? _sessionId;
  String? _mode;
  String? _topic;
  String? _personaType;
  Map<String, dynamic>? _config;
  String _currentState = 'created';
  int _roundNo = 0;
  String _turn = 'user';
  
  // UI state
  bool _isConnected = false;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _showCaptions = true;
  String _prepTime = '00:00';
  String _turnTime = '00:00';
  int _prepSeconds = 0;
  int _turnSeconds = 0;
  
  // Messages
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  
  // Timers
  Timer? _prepTimer;
  Timer? _turnTimer;

  @override
  void initState() {
    super.initState();
    _voiceService = VoiceService();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    await _voiceService.initialize();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    final apiService = ApiService();
    _channel = apiService.createWebSocketChannel();
    
    _channel.stream.listen(
      (data) {
        final message = jsonDecode(data);
        _handleWebSocketMessage(message);
      },
      onError: (error) {
        debugPrint('WebSocket error: $error');
        _showError('Connection error. Attempting to reconnect...');
        _reconnect();
      },
      onDone: () {
        debugPrint('WebSocket closed');
        _showError('Connection lost. Attempting to reconnect...');
        _reconnect();
      },
    );
    
    // Attach to session
    _channel.sink.add(jsonEncode(ApiService.attachSessionMessage(widget.sessionId)));
  }

  void _reconnect() {
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _connectWebSocket();
      }
    });
  }

  void _handleWebSocketMessage(Map<String, dynamic> message) {
    final type = message['type'] as String;
    
    switch (type) {
      case 'session_attached':
        setState(() {
          _sessionId = message['session_id'];
          _mode = message['mode'];
          _topic = message['topic'];
          _config = message['config'];
          _personaType = _config?['persona_type'];
          _isConnected = true;
        });
        debugPrint('Session attached: $_sessionId (mode: $_mode)');
        break;
        
      case 'prep_started':
        _startPrepTimer(message['seconds'] as int);
        break;
        
      case 'round_started':
        setState(() {
          _roundNo = message['round'];
          _turn = message['turn'];
          _currentState = 'live';
        });
        debugPrint('Round $_roundNo started');
        _startTurnTimer(message['turn_seconds'] as int);
        break;
        
      case 'ai_reply_start':
        setState(() {
          _isPlaying = true;
        });
        break;
        
      case 'ai_token':
        _addAIToken(message['token'] as String);
        break;
        
      case 'ai_reply_end':
        setState(() {
          _isPlaying = false;
        });
        _addAIMessage(message['text'] as String);
        _speakMessage(message['text'] as String);
        break;
        
      case 'turn_switched':
        setState(() {
          _turn = message['turn'];
        });
        break;
        
      case 'session_ended':
        _endSession();
        break;
        
      case 'error':
        _showError(message['detail'] as String);
        break;
    }
  }

  void _startPrepTimer(int seconds) {
    _prepSeconds = seconds;
    _prepTimer?.cancel();
    _prepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_prepSeconds > 0) {
        setState(() {
          _prepSeconds--;
          _prepTime = _formatTime(_prepSeconds);
        });
      } else {
        timer.cancel();
        _startRound();
      }
    });
  }

  void _startTurnTimer(int seconds) {
    _turnSeconds = seconds;
    _turnTimer?.cancel();
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_turnSeconds > 0) {
        setState(() {
          _turnSeconds--;
          _turnTime = _formatTime(_turnSeconds);
        });
      } else {
        timer.cancel();
        _switchTurn();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _startRound() {
    _channel.sink.add(jsonEncode(ApiService.startRoundMessage()));
  }

  void _switchTurn() {
    // This would be handled by the server
  }

  void _addAIToken(String token) {
    if (_messages.isNotEmpty && _messages.last['role'] == 'ai' && _messages.last['isStreaming'] == true) {
      setState(() {
        _messages.last['content'] += token;
      });
    } else {
      setState(() {
        _messages.add({
          'role': 'ai',
          'content': token,
          'isStreaming': true,
          'timestamp': DateTime.now(),
        });
      });
    }
    _scrollToBottom();
  }

  void _addAIMessage(String text) {
    if (_messages.isNotEmpty && _messages.last['role'] == 'ai' && _messages.last['isStreaming'] == true) {
      setState(() {
        _messages.last['content'] = text;
        _messages.last['isStreaming'] = false;
      });
    } else {
      setState(() {
        _messages.add({
          'role': 'ai',
          'content': text,
          'isStreaming': false,
          'timestamp': DateTime.now(),
        });
      });
    }
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add({
        'role': 'user',
        'content': text,
        'timestamp': DateTime.now(),
      });
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _speakMessage(String text) async {
    await _voiceService.speak(text);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.danger,
      ),
    );
  }

  void _endSession() {
    _prepTimer?.cancel();
    _turnTimer?.cancel();
    _channel.sink.close();
    
    if (mounted) {
      context.go('/feedback?sessionId=${widget.sessionId}');
    }
  }

  Future<void> _handleMicPress() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      await _voiceService.startRecording();
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      _showError('Failed to start recording: ${e.toString()}');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final recordingPath = await _voiceService.stopRecording();
      if (recordingPath != null) {
        final transcribedText = await _voiceService.transcribeRecording(recordingPath);
        if (transcribedText.isNotEmpty) {
          _addUserMessage(transcribedText);
          _channel.sink.add(jsonEncode(ApiService.userTextMessage(
            text: transcribedText,
            personaType: _personaType,
          )));
        }
      }
      setState(() {
        _isRecording = false;
      });
    } catch (e) {
      _showError('Failed to stop recording: ${e.toString()}');
      setState(() {
        _isRecording = false;
      });
    }
  }

  @override
  void dispose() {
    _prepTimer?.cancel();
    _turnTimer?.cancel();
    _channel.sink.close();
    _voiceService.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_topic ?? 'Practice Session'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _showCaptions = !_showCaptions;
              });
            },
            icon: Icon(_showCaptions ? Icons.closed_caption : Icons.closed_caption_off),
          ),
          IconButton(
            onPressed: _endSession,
            icon: const Icon(Icons.stop),
          ),
        ],
      ),
      body: Column(
        children: [
          // Timers
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TimerWidget(
                  label: 'Prep',
                  time: _prepTime,
                  isActive: _currentState == 'prep',
                ),
                TimerWidget(
                  label: 'Turn',
                  time: _turnTime,
                  isActive: _currentState == 'live' && _turn == 'user',
                ),
              ],
            ),
          ),
          
          // Messages
          Expanded(
            child: _showCaptions
                ? ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return MessageBubble(
                        text: message['content'],
                        isUser: message['role'] == 'user',
                        isStreaming: message['isStreaming'] == true,
                        timestamp: message['timestamp'],
                      );
                    },
                  )
                : const Center(
                    child: Text('Captions disabled'),
                  ),
          ),
          
          // Waveform
          if (_isRecording || _isPlaying)
            Container(
              height: 100,
              padding: const EdgeInsets.all(16),
              child: WaveformWidget(
                isRecording: _isRecording,
                isPlaying: _isPlaying,
              ),
            ),
          
          // Mic Button
          Container(
            padding: const EdgeInsets.all(24),
            child: MicButton(
              isRecording: _isRecording,
              isEnabled: _isConnected && _turn == 'user',
              onPressed: _handleMicPress,
            ),
          ),
        ],
      ),
    );
  }
}
