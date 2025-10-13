import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/theme.dart';

class WaveformWidget extends StatefulWidget {
  final bool isRecording;
  final bool isPlaying;

  const WaveformWidget({
    super.key,
    required this.isRecording,
    required this.isPlaying,
  });

  @override
  State<WaveformWidget> createState() => _WaveformWidgetState();
}

class _WaveformWidgetState extends State<WaveformWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(WaveformWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording || widget.isPlaying) {
      _animationController.repeat();
    } else {
      _animationController.stop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            size: const Size(double.infinity, 60),
            painter: WaveformPainter(
              progress: _animation.value,
              isRecording: widget.isRecording,
              isPlaying: widget.isPlaying,
              color: widget.isRecording 
                  ? AppTheme.danger 
                  : AppTheme.accentBlue,
            ),
          );
        },
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final double progress;
  final bool isRecording;
  final bool isPlaying;
  final Color color;

  WaveformPainter({
    required this.progress,
    required this.isRecording,
    required this.isPlaying,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isRecording && !isPlaying) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const barCount = 30;
    final barWidth = size.width / barCount;
    final centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth + barWidth / 2;
      final normalizedI = i / barCount;
      final phase = (progress + normalizedI) % 1.0;
      final height = (centerY * 0.8) * (0.3 + 0.7 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi)));
      
      canvas.drawLine(
        Offset(x, centerY - height),
        Offset(x, centerY + height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isRecording != isRecording ||
        oldDelegate.isPlaying != isPlaying;
  }
}
