import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/theme.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isStreaming;
  final DateTime? timestamp;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.isStreaming = false,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.accentBlue,
              child: Icon(
                Icons.smart_toy,
                color: AppTheme.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppTheme.accentBlue
                    : AppTheme.lightGray,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isUser ? AppTheme.white : AppTheme.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  if (isStreaming) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isUser ? AppTheme.white : AppTheme.accentBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI is typing...',
                          style: TextStyle(
                            color: isUser ? AppTheme.white : AppTheme.textSecondary,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (timestamp != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('HH:mm').format(timestamp!),
                      style: TextStyle(
                        color: isUser 
                            ? AppTheme.white.withOpacity(0.7)
                            : AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.accentBlue,
              child: Icon(
                Icons.person,
                color: AppTheme.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
