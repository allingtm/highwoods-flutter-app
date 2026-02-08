import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:form_field_validator/form_field_validator.dart';
import '../../models/invitation.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/connections_repository.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_tokens.dart';
import '../../utils/error_utils.dart';
import '../../utils/input_formatters.dart';
import '../../widgets/widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, this.inviteCode});

  /// Pre-filled invite code from deep link
  final String? inviteCode;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Invite validation state
  bool _isCodeValidated = false;
  InviteValidationResult? _validationResult;

  @override
  void initState() {
    super.initState();
    // If code was provided via deep link, auto-validate it
    if (widget.inviteCode != null) {
      _codeController.text = widget.inviteCode!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _validateCode();
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _validateCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an invite code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ConnectionsRepository();
      final result = await repository.validateInviteCode(code);

      setState(() {
        _isLoading = false;
        if (result.valid) {
          _isCodeValidated = true;
          _validationResult = result;
        } else {
          _errorMessage = result.error ?? 'Invalid invite code';
        }
      });
    } catch (e, stackTrace) {
      setState(() {
        _isLoading = false;
        _errorMessage = handleError(e, stackTrace, operation: 'register_validate_code');
      });
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepository = ref.read(authRepositoryProvider);

      // Check username availability
      final username = _usernameController.text.trim().toLowerCase();
      final isAvailable = await authRepository.isUsernameAvailable(username);
      if (!isAvailable) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Username "$username" is already taken';
        });
        return;
      }

      // Create auth account
      final response = await authRepository.signUpWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = response.user;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to create account. Please try again.';
        });
        return;
      }

      // Create profile
      await authRepository.createUserProfile(
        userId: user.id,
        email: user.email ?? _emailController.text.trim(),
        username: username,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );

      if (mounted) {
        // Request notification permission for new users
        await NotificationService.requestPermissionWithRationale(context);

        if (mounted) {
          context.go('/home');
        }
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = handleError(e, stackTrace, operation: 'register_sign_up');
        });
      }
    }
  }

  void _resetToCodeEntry() {
    setState(() {
      _isCodeValidated = false;
      _validationResult = null;
      _errorMessage = null;
      _codeController.clear();
    });
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
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
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

                      // Title based on current step
                      Text(
                        _isCodeValidated
                            ? 'Create your account'
                            : 'Join the community',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: tokens.spacingSm),
                      Text(
                        _isCodeValidated
                            ? 'Complete your profile to get started'
                            : 'Enter your invitation code to register',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: tokens.spacing2xl),

                      if (!_isCodeValidated) ...[
                        // Step 1: Invite code validation
                        _buildCodeEntryStep(tokens, theme),
                      ] else ...[
                        // Step 2: Registration form
                        _buildRegistrationStep(tokens, theme),
                      ],

                      SizedBox(height: tokens.spacing2xl),
                      const Divider(),
                      SizedBox(height: tokens.spacingLg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/login'),
                            child: const Text('Login'),
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

  Widget _buildCodeEntryStep(AppThemeTokens tokens, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Invitation Only card with border (no background)
        Container(
          padding: EdgeInsets.all(tokens.spacingLg),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(tokens.radiusLg),
          ),
          child: Column(
            children: [
              Icon(
                Icons.lock_outline,
                size: tokens.iconLg,
                color: theme.colorScheme.primary,
              ),
              SizedBox(height: tokens.spacingMd),
              Text(
                'Invitation Only',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              SizedBox(height: tokens.spacingSm),
              Text(
                'Highwoods is an invitation-only community. Enter the invite code you received, or ask someone you know with an account to send you an invitation.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.spacing2xl),
        // Invite code input below the card
        TextFormField(
          controller: _codeController,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: 'Invite Code',
            hintText: 'XXX-XXX-XXX',
            prefixIcon: const Icon(Icons.confirmation_number_outlined),
            border: const OutlineInputBorder(),
          ),
          inputFormatters: [
            InviteCodeFormatter(),
          ],
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _validateCode(),
        ),
        if (_errorMessage != null) ...[
          SizedBox(height: tokens.spacingLg),
          AppErrorContainer(message: _errorMessage!),
        ],
        SizedBox(height: tokens.spacingXl),
        AppButton(
          text: 'Verify Code',
          onPressed: _validateCode,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildRegistrationStep(AppThemeTokens tokens, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Show who invited them
        if (_validationResult != null) ...[
          Container(
            padding: EdgeInsets.all(tokens.spacingLg),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(tokens.radiusLg),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary,
                  ),
                  child: _validationResult!.inviterAvatar != null
                      ? ClipOval(
                          child: Image.network(
                            _validationResult!.inviterAvatar!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: theme.colorScheme.onPrimary,
                        ),
                ),
                SizedBox(width: tokens.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          SizedBox(width: tokens.spacingXs),
                          Text(
                            'Invited by',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _validationResult!.inviterName ?? 'A member',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _resetToCodeEntry,
                  tooltip: 'Use different code',
                ),
              ],
            ),
          ),
          if (_validationResult!.message != null) ...[
            SizedBox(height: tokens.spacingMd),
            Container(
              padding: EdgeInsets.all(tokens.spacingMd),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(tokens.radiusMd),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: tokens.spacingSm),
                  Expanded(
                    child: Text(
                      _validationResult!.message!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: tokens.spacingXl),
        ],

        // Registration form fields
        AppTextField.email(
          controller: _emailController,
          validator: MultiValidator([
            RequiredValidator(errorText: 'Email is required'),
            EmailValidator(errorText: 'Please enter a valid email'),
            MaxLengthValidator(254, errorText: 'Email is too long'),
          ]).call,
        ),
        SizedBox(height: tokens.spacingLg),
        AppTextField.username(
          controller: _usernameController,
          validator: MultiValidator([
            RequiredValidator(errorText: 'Username is required'),
            MinLengthValidator(3, errorText: 'Username must be at least 3 characters'),
            MaxLengthValidator(30, errorText: 'Username must be at most 30 characters'),
            PatternValidator(r'^[a-zA-Z0-9_]+$',
                errorText: 'Username can only contain letters, numbers, and underscores'),
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
            PatternValidator(r'^[a-zA-Z\s\-]+$',
                errorText: 'First name can only contain letters, spaces, and hyphens'),
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
            PatternValidator(r'^[a-zA-Z\s\-]+$',
                errorText: 'Last name can only contain letters, spaces, and hyphens'),
          ]).call,
        ),
        SizedBox(height: tokens.spacingLg),
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
          validator: MultiValidator([
            RequiredValidator(errorText: 'Password is required'),
            MinLengthValidator(8, errorText: 'Password must be at least 8 characters'),
          ]).call,
        ),
        SizedBox(height: tokens.spacingLg),
        AppTextField.password(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
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
          SizedBox(height: tokens.spacingLg),
          AppErrorContainer(message: _errorMessage!),
        ],
        SizedBox(height: tokens.spacingXl),
        AppButton(
          text: 'Create Account',
          onPressed: _signUp,
          isLoading: _isLoading,
        ),
      ],
    );
  }
}
