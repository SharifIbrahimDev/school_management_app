import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final String message;
  final Color? color;
  final double size;

  const LoadingIndicator({
    super.key,
    this.message = 'Loading...',
    this.color,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.primaryColor;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3.0,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
            ),
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: effectiveColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
