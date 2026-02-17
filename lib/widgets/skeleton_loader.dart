import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A professional skeleton loader widget using shimmer effect
class SkeletonLoader extends StatelessWidget {
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;
  final EdgeInsets? margin;

  const SkeletonLoader({
    super.key,
    this.height,
    this.width,
    this.borderRadius,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
      highlightColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
      child: Container(
        height: height,
        width: width,
        margin: margin,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// Skeleton loader for card-style content
class CardSkeletonLoader extends StatelessWidget {
  const CardSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonLoader(height: 20, width: 150),
            const SizedBox(height: 12),
            const SkeletonLoader(height: 16, width: double.infinity),
            const SizedBox(height: 8),
            const SkeletonLoader(height: 16, width: 200),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader for list items
class ListItemSkeletonLoader extends StatelessWidget {
  const ListItemSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SkeletonLoader(
            height: 48,
            width: 48,
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoader(height: 16, width: double.infinity),
                const SizedBox(height: 8),
                SkeletonLoader(height: 14, width: MediaQuery.of(context).size.width * 0.4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader for dashboard stats cards
class DashboardCardSkeletonLoader extends StatelessWidget {
  const DashboardCardSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonLoader(
              height: 40,
              width: 40,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            const SizedBox(height: 12),
            const SkeletonLoader(height: 14, width: 80),
            const SizedBox(height: 8),
            const SkeletonLoader(height: 24, width: 120),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader for form fields
class FormSkeletonLoader extends StatelessWidget {
  const FormSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(height: 16, width: 100),
          const SizedBox(height: 8),
          const SkeletonLoader(height: 56, width: double.infinity),
          const SizedBox(height: 24),
          const SkeletonLoader(height: 16, width: 120),
          const SizedBox(height: 8),
          const SkeletonLoader(height: 56, width: double.infinity),
          const SizedBox(height: 24),
          const SkeletonLoader(height: 16, width: 80),
          const SizedBox(height: 8),
          const SkeletonLoader(height: 56, width: double.infinity),
        ],
      ),
    );
  }
}

/// Skeleton loader for charts
class ChartSkeletonLoader extends StatelessWidget {
  const ChartSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonLoader(height: 20, width: 150),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                6,
                (index) => SkeletonLoader(
                  height: 80.0 + (index * 20),
                  width: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                3,
                (index) => Row(
                  children: [
                    SkeletonLoader(
                      height: 12,
                      width: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(width: 4),
                    const SkeletonLoader(height: 12, width: 50),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader for profile screen
class ProfileSkeletonLoader extends StatelessWidget {
  const ProfileSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SkeletonLoader(
            height: 100,
            width: 100,
            borderRadius: BorderRadius.all(Radius.circular(50)),
          ),
          const SizedBox(height: 16),
          const SkeletonLoader(height: 24, width: 200),
          const SizedBox(height: 8),
          const SkeletonLoader(height: 16, width: 150),
          const SizedBox(height: 32),
          ...List.generate(
            5,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const SkeletonLoader(height: 16, width: 100),
                      const Spacer(),
                      const SkeletonLoader(height: 16, width: 120),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

