import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:form_field_validator/form_field_validator.dart';
import '../../models/invitation.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/connections_repository.dart';
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
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _isLoading = false;
  bool _magicLinkSent = false;
  String? _errorMessage;

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
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
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
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = getErrorMessage(e);
      });
    }
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
                  _isCodeValidated ? Icons.check_circle_outline : Icons.vpn_key_outlined,
                  size: tokens.iconXl,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(height: tokens.spacingXl),
                Text(
                  _isCodeValidated ? 'Create your account' : 'Enter Invite Code',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: tokens.spacingXl),

                if (!_isCodeValidated) ...[
                  // Step 1: Invite code validation
                  _buildCodeEntryStep(tokens),
                ] else if (!_magicLinkSent) ...[
                  // Step 2: Registration form
                  _buildRegistrationStep(tokens),
                ] else ...[
                  // Step 3: Magic link sent confirmation
                  _buildMagicLinkSentStep(tokens),
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

  Widget _buildCodeEntryStep(AppThemeTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppInfoContainer(
          icon: Icons.lock_outline,
          child: Column(
            children: [
              Text(
                'Invitation Only',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
              SizedBox(height: tokens.spacingSm),
              const Text(
                'Highwoods is an invitation-only community. Enter the invite code you received, or ask someone you know with an account to send you an invitation.',
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.spacingXl),
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

  Widget _buildRegistrationStep(AppThemeTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Show who invited them
        if (_validationResult != null) ...[
          Container(
            padding: EdgeInsets.all(tokens.spacingLg),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(tokens.radiusLg),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: _validationResult!.inviterAvatar != null
                      ? ClipOval(
                          child: Image.network(
                            _validationResult!.inviterAvatar!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: Theme.of(context).colorScheme.onPrimary,
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
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          SizedBox(width: tokens.spacingXs),
                          Text(
                            'Invited by',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                      Text(
                        _validationResult!.inviterName ?? 'A member',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(tokens.radiusMd),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: tokens.spacingSm),
                  Expanded(
                    child: Text(
                      _validationResult!.message!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
      ],
    );
  }

  Widget _buildMagicLinkSentStep(AppThemeTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
    );
  }
}
