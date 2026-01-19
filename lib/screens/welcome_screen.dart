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
    (Icons.people_outline, 'Connect', 'Meet and chat with your neighbors'),
    (Icons.storefront_outlined, 'Marketplace', 'Buy & sell items locally'),
    (Icons.event_outlined, 'Events', 'Discover community events'),
    (Icons.pets_outlined, 'Lost & Found', 'Help reunite lost pets'),
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
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(tokens.spacingXl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: tokens.spacing2xl),
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 180,
                ),
              ),
              SizedBox(height: tokens.spacingXl),
              Text(
                'Welcome to Highwoods',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: tokens.spacingSm),
              Text(
                'Your community, connected',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: tokens.spacing2xl),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _benefits.length,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    final (icon, title, description) = _benefits[index];
                    return _BenefitCard(
                      icon: icon,
                      title: title,
                      description: description,
                    );
                  },
                ),
              ),
              SizedBox(height: tokens.spacingLg),
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
              AppButton(
                text: 'Get Started',
                onPressed: () => context.go('/login'),
              ),
              SizedBox(height: tokens.spacingXl),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.spacingMd),
      child: Container(
        padding: EdgeInsets.all(tokens.spacingXl),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(tokens.radiusXl),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: tokens.iconXl,
              color: colorScheme.primary,
            ),
            SizedBox(height: tokens.spacingLg),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
            ),
            SizedBox(height: tokens.spacingSm),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
