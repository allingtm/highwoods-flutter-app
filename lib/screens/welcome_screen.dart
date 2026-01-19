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
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        children: [
          // Top section - full bleed carousel with image, logo, and text
          Expanded(
            flex: 4,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _benefits.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                final (icon, imagePath, title, description) = _benefits[index];
                return _OnboardingSlide(
                  icon: icon,
                  imagePath: imagePath,
                  title: title,
                  description: description,
                  logoWidth: screenWidth * 0.8,
                );
              },
            ),
          ),
          // Bottom section with white background - dots and button only
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

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({
    required this.icon,
    required this.imagePath,
    required this.title,
    required this.description,
    required this.logoWidth,
  });

  final IconData icon;
  final String imagePath;
  final String title;
  final String description;
  final double logoWidth;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image - fills entire area
        Image.asset(
          imagePath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to colored background with icon if image not found
            return Container(
              color: colorScheme.primary,
              child: Center(
                child: Icon(
                  icon,
                  size: 150,
                  color: colorScheme.onPrimary.withValues(alpha: 0.8),
                ),
              ),
            );
          },
        ),
        // Gradient overlay for text readability at bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 200,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
        ),
        // Logo at top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(top: tokens.spacingLg),
              child: Center(
                child: Image.asset(
                  'assets/images/splash_logo.png',
                  width: logoWidth,
                  color: Colors.white,
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
        // Title and description at bottom
        Positioned(
          left: tokens.spacingXl,
          right: tokens.spacingXl,
          bottom: tokens.spacingXl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: tokens.spacingSm),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
