import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'api_service.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();
  
  late FlutterSoundRecorder _recorder;
  late FlutterTts _tts;
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordingPath;
  
  // Stream controllers for real-time audio data
  final StreamController<Uint8List> _audioDataController = StreamController<Uint8List>.broadcast();
  final StreamController<double> _volumeController = StreamController<double>.broadcast();
  
  Stream<Uint8List> get audioDataStream => _audioDataController.stream;
  Stream<double> get volumeStream => _volumeController.stream;
  
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  
  Future<void> initialize() async {
    // Initialize recorder
    _recorder = FlutterSoundRecorder();
    await _recorder.openRecorder();
    
    // Initialize TTS
    _tts = FlutterTts();
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    
    // Set up TTS completion handler
    _tts.setCompletionHandler(() {
      _isPlaying = false;
    });
    
    // Set up TTS error handler
    _tts.setErrorHandler((message) {
      debugPrint('TTS Error: $message');
      _isPlaying = false;
    });
  }
  
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }
  
  Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status == PermissionStatus.granted;
  }
  
  Future<void> startRecording() async {
    if (_isRecording) return;
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      _recordingPath = path.join(
        directory.path,
        'recording_${DateTime.now().millisecondsSinceEpoch}.aac',
      );
      
      await _recorder.startRecorder(
        toFile: _recordingPath,
        codec: Codec.aacADTS,
        sampleRate: 44100,
        numChannels: 1,
      );
      
      _isRecording = true;
      
      // Start volume monitoring
      _startVolumeMonitoring();
      
    } catch (e) {
      debugPrint('Error starting recording: $e');
      rethrow;
    }
  }
  
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    
    try {
      final path = await _recorder.stopRecorder();
      _isRecording = false;
      _stopVolumeMonitoring();
      
      return path;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      rethrow;
    }
  }
  
  Future<String> transcribeRecording(String filePath) async {
    try {
      // Read the audio file
      final file = File(filePath);
      final audioBytes = await file.readAsBytes();
      final base64Audio = base64Encode(audioBytes);
      
      // Send to backend for transcription
      final apiService = ApiService();
      final result = await apiService.transcribeAudio(audioData: base64Audio);
      
      return result['text'] ?? '';
    } catch (e) {
      debugPrint('Error transcribing recording: $e');
      rethrow;
    }
  }
  
  Future<void> speak(String text, {String? voice}) async {
    if (_isPlaying) {
      await stopSpeaking();
    }
    
    try {
      _isPlaying = true;
      
      if (voice != null) {
        await _tts.setVoice({'name': voice, 'locale': 'en-US'});
      }
      
      await _tts.speak(text);
    } catch (e) {
      debugPrint('Error speaking: $e');
      _isPlaying = false;
      rethrow;
    }
  }
  
  Future<void> stopSpeaking() async {
    if (_isPlaying) {
      await _tts.stop();
      _isPlaying = false;
    }
  }
  
  Future<void> pauseSpeaking() async {
    if (_isPlaying) {
      await _tts.pause();
    }
  }
  
  Future<void> resumeSpeaking() async {
    if (_isPlaying) {
      await _tts.speak('');
    }
  }
  
  Future<List<Map<String, dynamic>>> getAvailableVoices() async {
    try {
      final voices = await _tts.getVoices;
      return List<Map<String, dynamic>>.from(voices ?? []);
    } catch (e) {
      debugPrint('Error getting voices: $e');
      return [];
    }
  }
  
  Future<List<String>> getLanguages() async {
    try {
      final languages = await _tts.getLanguages;
      return List<String>.from(languages ?? []);
    } catch (e) {
      debugPrint('Error getting languages: $e');
      return [];
    }
  }
  
  Future<void> setLanguage(String language) async {
    await _tts.setLanguage(language);
  }
  
  Future<void> setSpeechRate(double rate) async {
    await _tts.setSpeechRate(rate);
  }
  
  Future<void> setVolume(double volume) async {
    await _tts.setVolume(volume);
  }
  
  Future<void> setPitch(double pitch) async {
    await _tts.setPitch(pitch);
  }
  
  void _startVolumeMonitoring() {
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isRecording) {
        timer.cancel();
        return;
      }
      
      _recorder.onProgress?.listen((event) {
        _volumeController.add(event.decibels ?? 0.0);
      });
    });
  }
  
  void _stopVolumeMonitoring() {
    // Volume monitoring is stopped when recording stops
  }
  
  Future<void> dispose() async {
    await _recorder.closeRecorder();
    await _tts.stop();
    await _audioDataController.close();
    await _volumeController.close();
  }
}
