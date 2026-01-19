import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _benefits = [
    (Icons.storefront_outlined, 'assets/images/onboarding/marketplace.png', 'Marketplace', 'Buy, sell & give away locally — pickup is streets away'),
    (Icons.thumb_up_outlined, 'assets/images/onboarding/recommendations.png', 'Recommendations', 'Get trusted advice from neighbours who\'ve used local services'),
    (Icons.shield_outlined, 'assets/images/onboarding/safety.png', 'Safety Alerts', 'Hear about incidents on your streets when they happen'),
    (Icons.pets_outlined, 'assets/images/onboarding/lost_and_found.png', 'Lost & Found', 'Reach people who actually walk past your street daily'),
    (Icons.event_outlined, 'assets/images/onboarding/events.png', 'Events', 'Discover local events, RSVP and see who\'s going'),
    (Icons.work_outline, 'assets/images/onboarding/jobs.png', 'Local Jobs', 'Find nearby help or offer your skills — no platform fees'),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          // Top section with colored background
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.primary,
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    SizedBox(height: tokens.spacingLg),
                    // Logo at top
                    Image.asset(
                      'assets/images/splash_logo.png',
                      width: 160,
                      color: Colors.white,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                    // Illustration carousel
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _benefits.length,
                        onPageChanged: (index) => setState(() => _currentPage = index),
                        itemBuilder: (context, index) {
                          final (icon, imagePath, _, _) = _benefits[index];
                          return _IllustrationCard(
                            icon: icon,
                            imagePath: imagePath,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bottom section with white background
          Container(
            width: double.infinity,
            color: colorScheme.surface,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: tokens.spacingXl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: tokens.spacing2xl),
                    // Title
                    Text(
                      _benefits[_currentPage].$3,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: tokens.spacingMd),
                    // Description
                    Text(
                      _benefits[_currentPage].$4,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: tokens.spacingXl),
                    // Dot indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _benefits.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.symmetric(horizontal: tokens.spacingXs),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? colorScheme.primary
                                : colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: tokens.spacing2xl),
                    // Get Started button
                    AppButton(
                      text: 'Get Started',
                      onPressed: () => context.go('/login'),
                    ),
                    SizedBox(height: tokens.spacingXl),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IllustrationCard extends StatelessWidget {
  const _IllustrationCard({
    required this.icon,
    required this.imagePath,
  });

  final IconData icon;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to icon if image not found
            return Icon(
              icon,
              size: 150,
              color: colorScheme.onPrimary.withValues(alpha: 0.8),
            );
          },
        ),
      ),
    );
  }
}
