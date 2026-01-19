import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/error_utils.dart';
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
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendMagicLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.sendOTP(email: _emailController.text.trim());

      setState(() {
        _magicLinkSent = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = getErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(tokens.spacingXl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: tokens.spacingLg),
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 80,
                  ),
                ),
                SizedBox(height: tokens.spacingXl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: tokens.iconMd,
                      color: colorScheme.primary,
                    ),
                    SizedBox(width: tokens.spacingMd),
                    Text(
                      'Sign in to your account',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                SizedBox(height: tokens.spacing2xl),
                if (!_magicLinkSent) ...[
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
                  if (_errorMessage != null) ...[
                    SizedBox(height: tokens.spacingLg),
                    AppErrorContainer(message: _errorMessage!),
                  ],
                  SizedBox(height: tokens.spacingXl),
                  AppButton(
                    text: 'Send Magic Link',
                    onPressed: _sendMagicLink,
                    isLoading: _isLoading,
                  ),
                ] else ...[
                  Icon(
                    Icons.email_outlined,
                    size: tokens.iconXl,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(height: tokens.spacingXl),
                  Text(
                    'Check your email!',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: tokens.spacingLg),
                  Text(
                    'We sent a magic link to:',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: tokens.spacingSm),
                  Text(
                    _emailController.text.trim(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: tokens.spacingXl),
                  AppInfoContainer(
                    icon: Icons.touch_app,
                    child: const Text('Click the link in your email to log in'),
                  ),
                  SizedBox(height: tokens.spacingXl),
                  AppButton(
                    text: 'Use a different email',
                    variant: AppButtonVariant.ghost,
                    onPressed: () {
                      setState(() {
                        _magicLinkSent = false;
                        _errorMessage = null;
                      });
                    },
                  ),
                ],
                SizedBox(height: tokens.spacingXl),
                const Divider(),
                SizedBox(height: tokens.spacingLg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text('Register'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
