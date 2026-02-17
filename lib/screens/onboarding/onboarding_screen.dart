import 'package:flutter/material.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/preferences_manager.dart';
import '../auth/auth_wrapper.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      title: 'Effortless Finance',
      description: 'Streamline your school\'s financial management with our intuitive automated system.',
      icon: Icons.account_balance_wallet_rounded,
      color: AppTheme.primaryColor,
    ),
    OnboardingItem(
      title: 'Real-time Tracking',
      description: 'Keep track of fees, expenses, and salaries in real-time with comprehensive analytics.',
      icon: Icons.analytics_rounded,
      color: AppTheme.neonBlue,
    ),
    OnboardingItem(
      title: 'Secure Payments',
      description: 'Experience peace of mind with our ultra-secure and transparent payment processing.',
      icon: Icons.security_rounded,
      color: AppTheme.neonEmerald,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background decoration
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _items[_currentPage].color.withValues(alpha: 0.1),
              ),
            ),
          ),
          
          PageView.builder(
            controller: _pageController,
            itemCount: _items.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: AppTheme.glassDecoration(
                        context: context,
                        opacity: 0.1,
                        borderRadius: 60,
                        hasGlow: true,
                        borderColor: _items[index].color.withValues(alpha: 0.3),
                      ),
                      child: Icon(
                        _items[index].icon,
                        size: 150,
                        color: _items[index].color,
                      ),
                    ),
                    const SizedBox(height: 60),
                    Text(
                      _items[index].title,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _items[index].description,
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppTheme.textSecondaryColor,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Navigation Bottom Bar
          Positioned(
            bottom: 50,
            left: 30,
            right: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Indicators
                Row(
                  children: List.generate(
                    _items.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index 
                            ? _items[_currentPage].color 
                            : AppTheme.textSecondaryColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                
                // Next/Get Started Button
                InkWell(
                  onTap: () {
                    if (_currentPage < _items.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _completeOnboarding();
                    }
                  },
                  borderRadius: BorderRadius.circular(25),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.symmetric(
                      horizontal: _currentPage == _items.length - 1 ? 30 : 20,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: _items[_currentPage].color,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: _items[_currentPage].color.withValues(alpha: 0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == _items.length - 1 ? 'Get Started' : 'Next',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (_currentPage < _items.length - 1) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Skip Button
          if (_currentPage < _items.length - 1)
            Positioned(
              top: 60,
              right: 20,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _completeOnboarding() async {
    await PreferencesManager.setOnboardingComplete(true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthWrapper()),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
