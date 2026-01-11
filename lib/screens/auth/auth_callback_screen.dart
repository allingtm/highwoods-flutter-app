import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/error_utils.dart';
import '../../widgets/widgets.dart';

class AuthCallbackScreen extends ConsumerStatefulWidget {
  final String? type;

  const AuthCallbackScreen({
    super.key,
    this.type,
  });

  @override
  ConsumerState<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends ConsumerState<AuthCallbackScreen> {
  bool _isProcessing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _handleDeepLink();
  }

  Future<void> _handleDeepLink() async {
    try {
      // Get the incoming URI using app_links
      final appLinks = AppLinks();
      final uri = await appLinks.getInitialLink();

      if (uri != null) {
        // Extract profile data from query parameters (if present - registration flow)
        final username = uri.queryParameters['username'];
        final firstName = uri.queryParameters['firstName'];
        final lastName = uri.queryParameters['lastName'];

        // Process the authentication URI with Supabase
        await Supabase.instance.client.auth.getSessionFromUrl(uri);

        if (mounted) {
          // Wait a moment for the auth state to propagate
          await Future.delayed(const Duration(milliseconds: 500));

          // Verify the user is actually logged in
          final user = Supabase.instance.client.auth.currentUser;

          if (user != null) {
            // Check if profile exists
            final authRepository = ref.read(authRepositoryProvider);
            final profile = await authRepository.getUserProfile(user.id);

            if (profile == null) {
              // No profile exists
              if (username != null && firstName != null && lastName != null) {
                // Registration flow - create profile with data from URL
                try {
                  await authRepository.createUserProfile(
                    userId: user.id,
                    email: user.email ?? '',
                    username: username,
                    firstName: firstName,
                    lastName: lastName,
                  );

                  // Profile created successfully, navigate to home
                  if (mounted) {
                    // Request notification permission for new users with rationale
                    await NotificationService.requestPermissionWithRationale(context);

                    if (mounted) {
                      context.go('/home');
                    }
                  }
                } catch (e) {
                  setState(() {
                    _errorMessage = 'Failed to create profile: ${getErrorMessage(e)}';
                    _isProcessing = false;
                  });
                }
              } else {
                // Login flow but no profile exists - shouldn't happen for existing users
                setState(() {
                  _errorMessage = 'Account not found. Please register first.';
                  _isProcessing = false;
                });
              }
            } else {
              // Profile exists, navigate to home
              if (mounted) {
                context.go('/home');
              }
            }
          } else {
            setState(() {
              _errorMessage = 'Authentication failed. Session not established.';
              _isProcessing = false;
            });
          }
        } else if (mounted) {
          setState(() {
            _errorMessage = 'Authentication failed. Please try again.';
            _isProcessing = false;
          });
        }
      } else {
        // No URI found, check if already authenticated
        await Future.delayed(const Duration(milliseconds: 500));
        final user = Supabase.instance.client.auth.currentUser;

        if (mounted) {
          if (user != null) {
            context.go('/home');
          } else {
            setState(() {
              _errorMessage = 'No authentication link found.';
              _isProcessing = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = getErrorMessage(e);
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Authenticating'),
      ),
      body: Center(
        child: _isProcessing
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: tokens.spacingLg),
                  Text(
                    widget.type == 'magic-link'
                        ? 'Verifying magic link...'
                        : 'Confirming your email...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              )
            : Padding(
                padding: EdgeInsets.all(tokens.spacingXl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: tokens.iconLg,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    SizedBox(height: tokens.spacingLg),
                    Text(
                      _errorMessage ?? 'Unknown error',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: tokens.spacingXl),
                    AppButton(
                      text: 'Return to Login',
                      variant: AppButtonVariant.outline,
                      onPressed: () => context.go('/login'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
