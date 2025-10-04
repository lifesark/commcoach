# CommCoach Frontend

A voice-first communication coaching platform built with Flutter, designed for cross-platform deployment (Web, Android, iOS, Desktop).

## Features

### 🎤 Voice-First Experience
- **Real-time Voice Recording**: Tap-to-talk microphone interface with waveform visualization
- **Text-to-Speech**: AI responses with natural voice synthesis
- **Speech-to-Text**: Automatic transcription of user speech
- **Audio Feedback**: Visual and audio cues for recording/playback states

### 🤖 AI-Powered Coaching
- **Multiple AI Personas**: 6 unique coaching personalities
  - Friendly Mentor: Supportive and encouraging
  - Socratic Judge: Critical thinking facilitator
  - Hiring Manager: Professional interviewer
  - Debate Champion: Skilled debater and coach
  - Presentation Coach: Public speaking expert
  - Casual Conversationalist: Everyday conversation partner

### 📊 Comprehensive Feedback
- **Multi-dimensional Scoring**: Clarity, Structure, Persuasiveness, Fluency, Timing
- **Personalized Tips**: AI-generated improvement suggestions
- **Real-time Analysis**: Live feedback during practice sessions
- **Performance Trends**: Track improvement over time

### 🎯 Practice Modes
- **Debate**: Structured arguments and counter-arguments
- **Interview**: Job interview simulation with common questions
- **Presentation**: Public speaking and presentation practice
- **Casual Chat**: Everyday conversation skills improvement

### 🏆 Gamification
- **XP System**: Earn experience points for practice sessions
- **Levels & Badges**: 11 different achievement badges
- **Streaks**: Daily practice tracking with rewards
- **Leaderboards**: Global and user-specific rankings
- **Progress Dashboard**: Comprehensive analytics and insights

### ♿ Accessibility
- **Screen Reader Support**: Full VoiceOver/TalkBack compatibility
- **Keyboard Navigation**: Complete keyboard accessibility
- **High Contrast**: Support for high contrast themes
- **Text Scaling**: Dynamic text size support
- **Captions**: Toggle-able conversation transcripts

## Tech Stack

- **Framework**: Flutter 3.0+
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Networking**: Dio (HTTP), WebSocket Channel (WS)
- **Authentication**: Supabase Flutter
- **Audio**: Flutter Sound, Flutter TTS, Flutter Audio Waveforms
- **UI**: Material Design 3 with custom theming

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # App configuration and routing
├── theme/
│   └── theme.dart           # Custom theme and colors
├── features/
│   ├── auth/                # Authentication screens
│   ├── setup/               # Session setup screens
│   ├── practice/            # Practice room screens
│   ├── feedback/            # Feedback display screens
│   └── dashboard/           # Progress dashboard screens
├── services/
│   ├── supabase_service.dart    # Supabase authentication
│   ├── api_service.dart         # Backend API integration
│   └── voice_service.dart       # Voice recording and TTS
├── state/
│   ├── auth_providers.dart      # Authentication state
│   └── api_providers.dart       # API data providers
├── widgets/
│   ├── custom_text_field.dart   # Custom input fields
│   ├── loading_button.dart      # Loading state buttons
│   ├── mic_button.dart          # Microphone interface
│   ├── message_bubble.dart      # Chat message display
│   ├── timer_widget.dart        # Session timers
│   ├── waveform_widget.dart     # Audio waveform visualization
│   ├── score_card.dart          # Performance score display
│   ├── tips_list.dart           # Improvement tips
│   ├── progress_badge.dart      # Achievement badges
│   ├── stats_card.dart          # Statistics display
│   ├── session_history_card.dart # Session history
│   ├── streak_widget.dart       # Streak tracking
│   ├── xp_progress_bar.dart     # XP and level progress
│   └── badge_grid.dart          # Badge collection
└── utils/
    ├── constants.dart            # App constants
    └── accessibility.dart        # Accessibility utilities
```

## Getting Started

### Prerequisites

- Flutter SDK 3.0 or higher
- Dart SDK 3.0 or higher
- Android Studio / VS Code with Flutter extensions
- Supabase account and project
- Backend API running (see backend README)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd commcoach/frontend
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment**
   - Update `lib/main.dart` with your Supabase credentials
   - Update `lib/services/api_service.dart` with your backend URL

4. **Run the app**
   ```bash
   flutter run
   ```

### Environment Configuration

Update the following in `lib/main.dart`:

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

Update the backend URL in `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'YOUR_BACKEND_URL';
static const String wsUrl = 'YOUR_WEBSOCKET_URL';
```

## Key Features Implementation

### Voice Processing

The app uses a comprehensive voice processing system:

```dart
// Initialize voice service
final voiceService = VoiceService();
await voiceService.initialize();

// Start recording
await voiceService.startRecording();

// Stop recording and transcribe
final path = await voiceService.stopRecording();
final text = await voiceService.transcribeRecording(path);

// Text-to-speech
await voiceService.speak("Hello, how are you?");
```

### WebSocket Integration

Real-time communication with the backend:

```dart
// Create WebSocket connection
final channel = apiService.createWebSocketChannel();

// Send messages
channel.sink.add(jsonEncode(ApiService.userTextMessage(
  text: "User input",
  personaType: "friendly_mentor",
)));

// Listen for responses
channel.stream.listen((data) {
  final message = jsonDecode(data);
  // Handle different message types
});
```

### State Management

Riverpod providers for reactive state management:

```dart
// Authentication state
final authStateProvider = StreamProvider<User?>((ref) {
  return SupabaseService.authStateChanges.map((data) => data.session?.user);
});

// API data
final dashboardProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getDashboard();
});
```

### Accessibility

Comprehensive accessibility support:

```dart
// Accessible button
AccessibilityUtils.accessibleButton(
  onPressed: () => startRecording(),
  semanticLabel: "Start recording",
  child: MicButton(),
);

// Screen reader announcements
AccessibilityUtils.announceToScreenReader(
  context, 
  "Recording started"
);
```

## UI/UX Design

### Color Scheme
- **Primary**: Accent Blue (#2F5FE4)
- **Success**: Green (#1BBE84)
- **Warning**: Orange (#E9A53A)
- **Danger**: Red (#E0564A)
- **Background**: Off White (#F7F7F5)
- **Text**: Charcoal (#1F1F1F)

### Typography
- **Font Family**: Inter (system fallback)
- **Headings**: SemiBold (600)
- **Body**: Regular (400)
- **Labels**: Medium (500)

### Motion
- **Duration**: 120-180ms
- **Curves**: EaseInOut
- **Transitions**: Fade and slide

## Cross-Platform Support

### Web
- Responsive design for desktop and mobile browsers
- WebRTC for audio recording
- Service worker for offline support (optional)

### Mobile (Android/iOS)
- Native audio recording and playback
- Platform-specific permissions handling
- Adaptive UI for different screen sizes

### Desktop (Windows/macOS/Linux)
- Native window management
- Keyboard shortcuts support
- Desktop-optimized layouts

## Testing

### Unit Tests
```bash
flutter test
```

### Widget Tests
```bash
flutter test test/widget_test.dart
```

### Integration Tests
```bash
flutter test integration_test/
```

### Manual Testing Checklist
- [ ] Authentication flow works
- [ ] Session creation and practice flow
- [ ] WebSocket events stream correctly
- [ ] Waveform renders during recording/playback
- [ ] Captions toggle persists
- [ ] Keyboard navigation works
- [ ] Screen reader compatibility
- [ ] Cross-platform builds

## Performance Optimization

### Dependencies
- Minimal dependency footprint
- Lazy loading of heavy components
- Efficient state management

### Audio Processing
- Optimized audio recording settings
- Efficient waveform rendering
- Background processing for transcription

### UI Performance
- Custom lightweight charts
- Efficient list rendering
- Optimized animations

## Deployment

### Web
```bash
flutter build web
# Deploy to your hosting service
```

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
# Archive and upload to App Store
```

### Desktop
```bash
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

## Troubleshooting

### Common Issues

1. **Microphone Permission Denied**
   - Check platform-specific permission settings
   - Ensure proper permission handling in code

2. **WebSocket Connection Failed**
   - Verify backend is running
   - Check network connectivity
   - Validate WebSocket URL configuration

3. **Audio Recording Issues**
   - Check microphone permissions
   - Verify audio format support
   - Test on different devices

4. **Build Errors**
   - Run `flutter clean && flutter pub get`
   - Check Flutter and Dart SDK versions
   - Verify platform-specific requirements

### Debug Mode
```bash
flutter run --debug
```

### Release Mode
```bash
flutter run --release
```

## Contributing

1. Follow the existing code structure
2. Add proper documentation
3. Include unit tests for new features
4. Ensure accessibility compliance
5. Test on multiple platforms

## License

See LICENSE file for details.

## Support

For issues and questions:
- Check the troubleshooting section
- Review the backend API documentation
- Open an issue in the repository
