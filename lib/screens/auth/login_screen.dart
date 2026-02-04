import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _magicLinkSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendMagicLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.sendLoginOTP(email: _emailController.text.trim());
    } catch (e) {
      // Silently ignore errors to prevent user enumeration
      // (don't reveal whether an email exists or not)
    }

    // Always show success message for security
    setState(() {
      _magicLinkSent = true;
      _isLoading = false;
    });
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () => context.go('/'),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spacingXl,
                vertical: tokens.spacing2xl,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Center(
                        child: Image.asset(
                          'assets/images/highwoods-app-logo.png',
                          width: 240,
                        ),
                      ),
                      SizedBox(height: tokens.spacing2xl),

                      if (!_magicLinkSent) ...[
                        // Welcome text
                        Text(
                          'Welcome back',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: tokens.spacingSm),
                        Text(
                          'Sign in to your community',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: tokens.spacing2xl),

                        // Email field
                        AppTextField.email(
                          controller: _emailController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: tokens.spacingXl),

                        // Send button
                        AppButton(
                          text: 'Send Magic Link',
                          onPressed: _sendMagicLink,
                          isLoading: _isLoading,
                        ),
                      ] else ...[
                        // Magic link sent state
                        Icon(
                          Icons.mark_email_read_outlined,
                          size: tokens.iconXl,
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(height: tokens.spacingXl),
                        Text(
                          'Check your inbox',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: tokens.spacingLg),
                        Text(
                          'We sent a magic link to',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: tokens.spacingSm),
                        Text(
                          _emailController.text.trim(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: tokens.spacingXl),
                        AppInfoContainer(
                          icon: Icons.touch_app_rounded,
                          child: const Text('Tap the link in your email to sign in'),
                        ),
                        SizedBox(height: tokens.spacingXl),
                        AppButton(
                          text: 'Use a different email',
                          variant: AppButtonVariant.outline,
                          onPressed: () {
                            setState(() {
                              _magicLinkSent = false;
                            });
                          },
                        ),
                      ],

                      SizedBox(height: tokens.spacing2xl),
                      const Divider(),
                      SizedBox(height: tokens.spacingLg),

                      // Register link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/register'),
                            child: const Text('Register'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
