import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_tokens.dart';
import '../../utils/error_utils.dart';
import '../../widgets/widgets.dart';

/// Screen shown after a password recovery link is processed.
/// The session is already established by AuthCallbackScreen before
/// navigating here — this screen just collects the new password.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;
  bool _passwordUpdated = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.updatePassword(
        newPassword: _passwordController.text,
      );

      if (mounted) {
        setState(() {
          _passwordUpdated = true;
          _isSubmitting = false;
        });
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() {
          _errorMessage =
              handleError(e, stackTrace, operation: 'reset_password_update');
          _isSubmitting = false;
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

    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Reset Password'),
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
                child: _buildContent(tokens, theme),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AppThemeTokens tokens, ThemeData theme) {
    // Error state (only show when not submitting and not yet updated)
    if (_errorMessage != null && !_passwordUpdated && !_isSubmitting) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: tokens.iconLg,
            color: theme.colorScheme.error,
          ),
          SizedBox(height: tokens.spacingLg),
          Text(
            _errorMessage!,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: tokens.spacingXl),
          AppButton(
            text: 'Return to Login',
            variant: AppButtonVariant.outline,
            onPressed: () => context.go('/login'),
          ),
        ],
      );
    }

    // Success state
    if (_passwordUpdated) {
      return Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: tokens.iconXl,
            color: theme.colorScheme.primary,
          ),
          SizedBox(height: tokens.spacingXl),
          Text(
            'Password Updated',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: tokens.spacingSm),
          Text(
            'Your password has been successfully updated.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: tokens.spacingXl),
          AppButton(
            text: 'Continue',
            onPressed: () => context.go('/home'),
          ),
        ],
      );
    }

    // Password form
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Image.asset(
              'assets/images/highwoods-app-logo.png',
              width: 240,
            ),
          ),
          SizedBox(height: tokens.spacing2xl),
          Text(
            'Set New Password',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: tokens.spacingSm),
          Text(
            'Enter your new password below',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: tokens.spacing2xl),

          // New password
          AppTextField.password(
            controller: _passwordController,
            label: 'New Password',
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
                return 'Please enter a new password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),

          SizedBox(height: tokens.spacingLg),

          // Confirm password
          AppTextField.password(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            obscureText: _obscureConfirm,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirm = !_obscureConfirm;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),

          if (_errorMessage != null) ...[
            SizedBox(height: tokens.spacingSm),
            AppErrorContainer(message: _errorMessage!),
          ],

          SizedBox(height: tokens.spacingXl),

          AppButton(
            text: 'Update Password',
            onPressed: _updatePassword,
            isLoading: _isSubmitting,
          ),
        ],
      ),
    );
  }
}
