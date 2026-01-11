import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:form_field_validator/form_field_validator.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/error_utils.dart';
import '../../widgets/widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _isLoading = false;
  bool _magicLinkSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
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

      // Send magic link with profile data
      await authRepository.sendOTP(
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(tokens.spacingXl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: tokens.spacingXl),
                Icon(
                  Icons.person_add_outlined,
                  size: tokens.iconXl,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(height: tokens.spacingXl),
                Text(
                  'Create your account',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: tokens.spacing2xl),
                if (!_magicLinkSent) ...[
                  AppTextField.email(
                    controller: _emailController,
                    validator: MultiValidator([
                      RequiredValidator(errorText: 'Email is required'),
                      EmailValidator(errorText: 'Please enter a valid email'),
                      MaxLengthValidator(254, errorText: 'Email is too long'),
                    ]).call,
                  ),
                  SizedBox(height: tokens.spacingLg),
                  AppTextField.name(
                    controller: _firstNameController,
                    label: 'First Name',
                    hint: 'John',
                    validator: MultiValidator([
                      RequiredValidator(errorText: 'First name is required'),
                      MinLengthValidator(2, errorText: 'First name must be at least 2 characters'),
                      MaxLengthValidator(50, errorText: 'First name must be at most 50 characters'),
                      PatternValidator(r'^[a-zA-Z\s\-]+$', errorText: 'First name can only contain letters, spaces, and hyphens'),
                    ]).call,
                  ),
                  SizedBox(height: tokens.spacingLg),
                  AppTextField.name(
                    controller: _lastNameController,
                    label: 'Last Name',
                    hint: 'Doe',
                    validator: MultiValidator([
                      RequiredValidator(errorText: 'Last name is required'),
                      MinLengthValidator(2, errorText: 'Last name must be at least 2 characters'),
                      MaxLengthValidator(50, errorText: 'Last name must be at most 50 characters'),
                      PatternValidator(r'^[a-zA-Z\s\-]+$', errorText: 'Last name can only contain letters, spaces, and hyphens'),
                    ]).call,
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
                    child: const Text('Click the link in your email to create your account'),
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
                    const Text('Already have an account? '),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Login'),
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
