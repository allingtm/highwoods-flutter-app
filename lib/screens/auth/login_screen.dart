import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/biometric_provider.dart';
import '../../services/biometric_service.dart';
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
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _biometricLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptAutomaticBiometricLogin();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _attemptAutomaticBiometricLogin() async {
    final shouldAttempt = await BiometricService.shouldAttemptBiometricLogin();
    if (shouldAttempt && mounted) {
      _signInWithBiometrics();
    }
  }

  Future<void> _signInWithBiometrics() async {
    setState(() {
      _biometricLoading = true;
      _errorMessage = null;
    });

    try {
      final authenticated = await BiometricService.authenticate();
      if (!authenticated) {
        if (mounted) setState(() => _biometricLoading = false);
        return;
      }

      final credentials = await BiometricService.getCredentials();
      if (credentials == null) {
        if (mounted) {
          setState(() {
            _biometricLoading = false;
            _errorMessage =
                'Stored credentials not found. Please sign in with your password.';
          });
        }
        return;
      }

      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signInWithPassword(
        email: credentials.email,
        password: credentials.password,
      );

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      // Credentials may be stale (e.g. password changed on another device)
      await BiometricService.disableBiometricLogin();
      if (mounted) {
        ref.invalidate(shouldAttemptBiometricProvider);
        setState(() {
          _biometricLoading = false;
          _errorMessage =
              'Biometric sign in failed. Please enter your password.';
        });
      }
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signInWithPassword(
        email: email,
        password: password,
      );

      // Store credentials for biometric enrollment prompt (shown on HomeScreen)
      if (mounted) {
        final canOffer = await BiometricService.canOfferBiometricLogin();
        final isEnabled = await BiometricService.isBiometricEnabled();

        if (canOffer && !isEnabled) {
          ref.read(pendingBiometricEnrollmentProvider.notifier).state =
              (email: email, password: password);
        }

        context.go('/home');
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              handleError(e, stackTrace, operation: 'login_sign_in');
        });
      }
    }
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final shouldAttemptBiometric = ref.watch(shouldAttemptBiometricProvider);
    final biometricLabel = ref.watch(biometricLabelProvider);

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

                      SizedBox(height: tokens.spacingLg),

                      // Password field
                      AppTextField.password(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),

                      // Forgot password link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.push('/forgot-password'),
                          child: const Text('Forgot Password?'),
                        ),
                      ),

                      if (_errorMessage != null) ...[
                        SizedBox(height: tokens.spacingSm),
                        AppErrorContainer(message: _errorMessage!),
                      ],

                      SizedBox(height: tokens.spacingLg),

                      // Sign in button
                      AppButton(
                        text: 'Sign In',
                        onPressed: _signIn,
                        isLoading: _isLoading,
                      ),

                      // Biometric login button
                      shouldAttemptBiometric.when(
                        data: (should) {
                          if (!should) return const SizedBox.shrink();
                          final label =
                              biometricLabel.valueOrNull ?? 'Biometrics';
                          return Column(
                            children: [
                              SizedBox(height: tokens.spacingMd),
                              OutlinedButton.icon(
                                onPressed: _biometricLoading
                                    ? null
                                    : _signInWithBiometrics,
                                icon: Icon(
                                  label == 'Face ID'
                                      ? Icons.face
                                      : Icons.fingerprint,
                                ),
                                label: _biometricLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : Text('Sign in with $label'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize:
                                      const Size(double.infinity, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        tokens.radiusMd),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

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
