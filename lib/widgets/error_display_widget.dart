import 'package:flutter/material.dart';

/// A reusable widget to display user-friendly error messages
/// Maps technical errors to understandable messages with retry options
class ErrorDisplayWidget extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;
  final VoidCallback? onContactSupport;
  final bool showContactSupport;

  const ErrorDisplayWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.onContactSupport,
    this.showContactSupport = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userFriendlyMessage = _getUserFriendlyMessage(error);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated error icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 56,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Error title
            Text(
              'Oops! Something went wrong',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // User-friendly message
            Text(
              userFriendlyMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Action buttons
            Column(
              children: [
                if (onRetry != null)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                
                if (showContactSupport) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onContactSupport ?? () {},
                      icon: const Icon(Icons.support_agent),
                      label: const Text('Contact Support'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Maps technical error messages to user-friendly ones
  String _getUserFriendlyMessage(String error) {
    final lowerError = error.toLowerCase();
    
    // Network errors
    if (lowerError.contains('socket') || 
        lowerError.contains('network') ||
        lowerError.contains('connection')) {
      return 'Unable to connect to the server. Please check your internet connection and try again.';
    }
    
    // Authentication errors
    if (lowerError.contains('unauthorized') || 
        lowerError.contains('401') ||
        lowerError.contains('unauthenticated')) {
      return 'Your session has expired. Please log in again.';
    }
    
    if (lowerError.contains('403') || 
        lowerError.contains('forbidden') ||
        lowerError.contains('permission')) {
      return 'You don\'t have permission to perform this action.';
    }
    
    // Validation errors
    if (lowerError.contains('validation') || 
        lowerError.contains('invalid')) {
      return 'Please check your input and try again.';
    }
    
    // Not found errors
    if (lowerError.contains('404') || 
        lowerError.contains('not found')) {
      return 'The requested information could not be found.';
    }
    
    // Server errors
    if (lowerError.contains('500') || 
        lowerError.contains('server error') ||
        lowerError.contains('internal')) {
      return 'Our servers are experiencing issues. Please try again in a few moments.';
    }
    
    // Timeout errors
    if (lowerError.contains('timeout')) {
      return 'The request took too long. Please try again.';
    }
    
    // Default message
    return 'An unexpected error occurred. Please try again or contact support if the problem persists.';
  }
}
