import 'package:flutter/material.dart';

import '../theme/theme.dart';

class MicButton extends StatefulWidget {
  final bool isRecording;
  final bool isEnabled;
  final VoidCallback onPressed;

  const MicButton({
    super.key,
    required this.isRecording,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.isEnabled) {
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.isEnabled) {
      _animationController.reverse();
      widget.onPressed();
    }
  }

  void _handleTapCancel() {
    if (widget.isEnabled) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isRecording
                    ? AppTheme.danger
                    : widget.isEnabled
                        ? AppTheme.accentBlue
                        : AppTheme.mediumGray,
                boxShadow: [
                  BoxShadow(
                    color: (widget.isRecording
                            ? AppTheme.danger
                            : widget.isEnabled
                                ? AppTheme.accentBlue
                                : AppTheme.mediumGray)
                        .withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                widget.isRecording ? Icons.stop : Icons.mic,
                color: AppTheme.white,
                size: 32,
              ),
            ),
          );
        },
      ),
    );
  }
}
