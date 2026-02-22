import 'package:flutter/material.dart';
import '../core/utils/app_theme.dart';

class LoadingIndicator extends StatefulWidget {
  final String? message;
  final Color? color;
  final double size;
  final bool isFullPage;

  const LoadingIndicator({
    super.key,
    this.message,
    this.color,
    this.size = 50.0,
    this.isFullPage = false,
  });

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = widget.color ?? AppTheme.secondaryColor;

    Widget indicator = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer rotating ring
            RotationTransition(
              turns: _controller,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: effectiveColor.withValues(alpha: 0.2),
                    width: 3,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: effectiveColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: effectiveColor.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Inner pulsing dot
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final scale = 0.5 + (0.3 * (1.0 - _controller.value));
                final opacity = 0.3 + (0.7 * (1.0 - _controller.value));
                return Container(
                  width: widget.size * 0.4,
                  height: widget.size * 0.4,
                  decoration: BoxDecoration(
                    color: effectiveColor.withValues(alpha: opacity),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: effectiveColor.withValues(alpha: opacity * 0.5),
                        blurRadius: 12 * (1.0 - _controller.value),
                        spreadRadius: 4 * (1.0 - _controller.value),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        if (widget.message != null && widget.message!.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            widget.message!,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white.withValues(alpha: 0.8) 
                : AppTheme.primaryColor.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );

    if (widget.isFullPage) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.05),
                AppTheme.accentColor.withValues(alpha: 0.1),
                Colors.white,
              ],
            ),
          ),
          child: Center(child: indicator),
        ),
      );
    }

    return Center(child: indicator);
  }
}
