import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class AccessibilityUtils {
  // Semantic labels for common UI elements
  static const String micButtonLabel = 'Microphone button. Tap to start recording.';
  static const String stopButtonLabel = 'Stop button. Tap to stop recording.';
  static const String playButtonLabel = 'Play button. Tap to play audio.';
  static const String pauseButtonLabel = 'Pause button. Tap to pause audio.';
  static const String captionsToggleLabel = 'Captions toggle. Tap to show or hide captions.';
  static const String timerLabel = 'Timer showing remaining time.';
  static const String scoreLabel = 'Score display showing performance rating.';
  static const String progressBarLabel = 'Progress bar showing completion status.';
  
  // Announcements for screen readers
  static void announceToScreenReader(BuildContext context, String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }
  
  // Focus management
  static void requestFocus(BuildContext context, FocusNode focusNode) {
    FocusScope.of(context).requestFocus(focusNode);
  }
  
  static void unfocus(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
  
  // High contrast support
  static bool isHighContrast(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }
  
  // Text scaling support
  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaleFactor;
  }
  
  // Screen reader support
  static bool isScreenReaderEnabled(BuildContext context) {
    return MediaQuery.of(context).accessibleNavigation;
  }
  
  // Keyboard navigation support
  static bool isKeyboardNavigation(BuildContext context) {
    return MediaQuery.of(context).accessibleNavigation;
  }
  
  // Create accessible button
  static Widget accessibleButton({
    required Widget child,
    required VoidCallback? onPressed,
    String? semanticLabel,
    String? tooltip,
    bool excludeSemantics = false,
  }) {
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onPressed != null,
      excludeSemantics: excludeSemantics,
      child: Tooltip(
        message: tooltip ?? '',
        child: child,
      ),
    );
  }
  
  // Create accessible text field
  static Widget accessibleTextField({
    required Widget child,
    String? label,
    String? hint,
    String? error,
    bool isRequired = false,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      textField: true,
      isRequired: isRequired,
      child: child,
    );
  }
  
  // Create accessible card
  static Widget accessibleCard({
    required Widget child,
    String? label,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: label,
      button: onTap != null,
      onTap: onTap,
      child: child,
    );
  }
  
  // Create accessible progress indicator
  static Widget accessibleProgressIndicator({
    required double value,
    String? label,
    String? hint,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      value: '${(value * 100).toInt()}%',
      child: LinearProgressIndicator(value: value),
    );
  }
  
  // Create accessible timer
  static Widget accessibleTimer({
    required String time,
    required String label,
    bool isActive = false,
  }) {
    return Semantics(
      label: '$label timer: $time',
      value: isActive ? 'Active' : 'Inactive',
      child: Text(time),
    );
  }
  
  // Create accessible score display
  static Widget accessibleScore({
    required int score,
    required String label,
    required Color color,
  }) {
    return Semantics(
      label: '$label score: $score out of 100',
      value: _getScoreDescription(score),
      child: Text(
        '$score',
        style: TextStyle(color: color),
      ),
    );
  }
  
  static String _getScoreDescription(int score) {
    if (score >= 90) return 'Excellent';
    if (score >= 80) return 'Good';
    if (score >= 70) return 'Fair';
    if (score >= 60) return 'Poor';
    return 'Very Poor';
  }
  
  // Create accessible badge
  static Widget accessibleBadge({
    required String name,
    required String description,
    required bool isEarned,
    required String icon,
  }) {
    return Semantics(
      label: isEarned ? 'Earned badge: $name' : 'Locked badge: $name',
      hint: description,
      child: Container(
        child: Text(icon),
      ),
    );
  }
  
  // Create accessible waveform
  static Widget accessibleWaveform({
    required bool isRecording,
    required bool isPlaying,
  }) {
    String label = 'Audio waveform';
    if (isRecording) {
      label = 'Recording audio waveform';
    } else if (isPlaying) {
      label = 'Playing audio waveform';
    }
    
    return Semantics(
      label: label,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  // Create accessible message bubble
  static Widget accessibleMessageBubble({
    required String text,
    required bool isUser,
    required DateTime timestamp,
  }) {
    final role = isUser ? 'You' : 'AI Coach';
    final time = '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    
    return Semantics(
      label: '$role said: $text at $time',
      child: Container(
        child: Text(text),
      ),
    );
  }
}
