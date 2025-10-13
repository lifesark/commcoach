import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../services/voice_service.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/persona_card.dart';
import '../../widgets/mode_card.dart';
import '../../state/api_providers.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  String _selectedMode = 'debate';
  String? _selectedPersona;
  String? _selectedTopic;
  bool _isRandomTopic = false;
  bool _isFetchFromInternet = false;
  bool _isLoading = false;
  bool _micPermissionGranted = false;
  
  final List<String> _modes = [
    'debate',
    'interview',
    'presentation',
    'casual',
  ];
  
  final Map<String, String> _modeLabels = {
    'debate': 'Debate',
    'interview': 'Interview',
    'presentation': 'Presentation',
    'casual': 'Casual Chat',
  };
  
  final Map<String, String> _modeDescriptions = {
    'debate': 'Practice structured arguments and counter-arguments',
    'interview': 'Simulate job interviews with common questions',
    'presentation': 'Practice public speaking and presentations',
    'casual': 'Improve everyday conversation skills',
  };

  @override
  void initState() {
    super.initState();
    _checkMicrophonePermission();
  }

  Future<void> _checkMicrophonePermission() async {
    final voiceService = VoiceService();
    final hasPermission = await voiceService.hasMicrophonePermission();
    
    if (mounted) {
      setState(() {
        _micPermissionGranted = hasPermission;
      });
    }
  }

  Future<void> _requestMicrophonePermission() async {
    final voiceService = VoiceService();
    final granted = await voiceService.requestMicrophonePermission();
    
    if (mounted) {
      setState(() {
        _micPermissionGranted = granted;
      });
      
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required to use CommCoach'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _startSession() async {
    if (!_micPermissionGranted) {
      await _requestMicrophonePermission();
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final apiService = ref.read(apiServiceProvider);
      
      final sessionData = await apiService.createSession(
        mode: _selectedMode,
        topic: _selectedTopic,
        randomTopic: _isRandomTopic,
        fetchFromInternet: _isFetchFromInternet,
        personaType: _selectedPersona,
        prepS: 60,
        turnS: 60,
        rounds: 2,
      );
      
      if (mounted) {
        context.go('/practice?sessionId=${sessionData['session_id']}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating session: ${e.toString()}'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final personasAsync = ref.watch(personasProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Practice Session'),
        actions: [
          IconButton(
            onPressed: () {
              // Go to dashboard
              context.go('/dashboard');
            },
            icon: const Icon(Icons.dashboard),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Microphone Permission Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _micPermissionGranted 
                    ? AppTheme.success.withOpacity(0.1)
                    : AppTheme.warn.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _micPermissionGranted 
                      ? AppTheme.success
                      : AppTheme.warn,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _micPermissionGranted ? Icons.mic : Icons.mic_off,
                    color: _micPermissionGranted 
                        ? AppTheme.success
                        : AppTheme.warn,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _micPermissionGranted
                          ? 'Microphone permission granted'
                          : 'Microphone permission required',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _micPermissionGranted 
                            ? AppTheme.success
                            : AppTheme.warn,
                      ),
                    ),
                  ),
                  if (!_micPermissionGranted)
                    TextButton(
                      onPressed: _requestMicrophonePermission,
                      child: const Text('Grant Permission'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Practice Mode Selection
            Text(
              'Choose Practice Mode',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _modes.length,
              itemBuilder: (context, index) {
                final mode = _modes[index];
                final isSelected = _selectedMode == mode;
                
                return ModeCard(
                  title: _modeLabels[mode]!,
                  description: _modeDescriptions[mode]!,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedMode = mode;
                      _selectedPersona = null; // Reset persona when mode changes
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            
            // Persona Selection
            Text(
              'Choose AI Coach',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            personasAsync.when(
              data: (personas) => Column(
                children: personas.map((persona) {
                  final isSelected = _selectedPersona == persona['type'];
                  return PersonaCard(
                    name: persona['name'],
                    description: persona['description'],
                    tone: persona['tone'],
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedPersona = persona['type'];
                      });
                    },
                  );
                }).toList(),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error loading personas: $error'),
            ),
            const SizedBox(height: 24),
            
            // Topic Selection
            Text(
              'Choose Topic',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            // Topic Options
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RadioListTile<bool>(
                      title: const Text('Random Topic'),
                      subtitle: const Text('Let us choose a topic for you'),
                      value: true,
                      groupValue: _isRandomTopic,
                      onChanged: (value) {
                        setState(() {
                          _isRandomTopic = value ?? false;
                          _isFetchFromInternet = false;
                          _selectedTopic = null;
                        });
                      },
                    ),
                    RadioListTile<bool>(
                      title: const Text('Fetch from Internet'),
                      subtitle: const Text('Get current topics from news'),
                      value: true,
                      groupValue: _isFetchFromInternet,
                      onChanged: (value) {
                        setState(() {
                          _isFetchFromInternet = value ?? false;
                          _isRandomTopic = false;
                          _selectedTopic = null;
                        });
                      },
                    ),
                    RadioListTile<bool>(
                      title: const Text('Custom Topic'),
                      subtitle: const Text('Enter your own topic'),
                      value: true,
                      groupValue: !_isRandomTopic && !_isFetchFromInternet,
                      onChanged: (value) {
                        if (value == true) {
                          setState(() {
                            _isRandomTopic = false;
                            _isFetchFromInternet = false;
                          });
                        }
                      },
                    ),
                    if (!_isRandomTopic && !_isFetchFromInternet) ...[
                      const SizedBox(height: 16),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Enter your topic',
                          hintText: 'e.g., "The benefits of remote work"',
                        ),
                        onChanged: (value) {
                          _selectedTopic = value.trim().isEmpty ? null : value.trim();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Start Session Button
            LoadingButton(
              onPressed: _startSession,
              isLoading: _isLoading,
              child: const Text('Start Practice Session'),
            ),
          ],
        ),
      ),
    );
  }
}
