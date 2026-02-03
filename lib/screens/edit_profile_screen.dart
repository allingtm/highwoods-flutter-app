import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/user_profile_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isSaving = false;
  bool _isCheckingUsername = false;
  bool _isUsernameAvailable = true;
  String? _originalUsername;
  Timer? _usernameDebounce;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    final profile = ref.read(userProfileNotifierProvider).valueOrNull;
    if (profile != null) {
      _firstNameController.text = profile.firstName ?? '';
      _lastNameController.text = profile.lastName ?? '';
      _usernameController.text = profile.username;
      _bioController.text = profile.bio ?? '';
      _originalUsername = profile.username;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _usernameDebounce?.cancel();
    super.dispose();
  }

  Future<void> _checkUsernameAvailability(String username) async {
    if (username.isEmpty || username == _originalUsername) {
      setState(() {
        _isUsernameAvailable = true;
        _isCheckingUsername = false;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
    });

    try {
      final authRepository = ref.read(authRepositoryProvider);
      final isAvailable = await authRepository.isUsernameAvailable(username);
      if (mounted) {
        setState(() {
          _isUsernameAvailable = isAvailable;
          _isCheckingUsername = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingUsername = false;
        });
      }
    }
  }

  void _onUsernameChanged(String value) {
    _usernameDebounce?.cancel();
    _usernameDebounce = Timer(const Duration(milliseconds: 500), () {
      _checkUsernameAvailability(value.trim().toLowerCase());
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isUsernameAvailable) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final username = _usernameController.text.trim().toLowerCase();
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final bio = _bioController.text.trim();

      await ref.read(userProfileNotifierProvider.notifier).updateProfile(
            username: username != _originalUsername ? username : null,
            firstName: firstName.isNotEmpty ? firstName : null,
            lastName: lastName.isNotEmpty ? lastName : null,
            bio: bio.isNotEmpty ? bio : null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final profile = ref.watch(userProfileNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SafeArea(
        child: profile.when(
          data: (profileData) {
            if (profileData == null) {
              return const Center(child: Text('Profile not found'));
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(tokens.spacingXl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField.name(
                      controller: _firstNameController,
                      label: 'First Name',
                      hint: 'Enter your first name',
                    ),
                    SizedBox(height: tokens.spacingLg),
                    AppTextField.name(
                      controller: _lastNameController,
                      label: 'Last Name',
                      hint: 'Enter your last name',
                    ),
                    SizedBox(height: tokens.spacingLg),
                    AppTextField.username(
                      controller: _usernameController,
                      onChanged: _onUsernameChanged,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username is required';
                        }
                        if (value.trim().length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        if (!_isUsernameAvailable &&
                            value.trim().toLowerCase() != _originalUsername) {
                          return 'Username is already taken';
                        }
                        return null;
                      },
                    ),
                    if (_isCheckingUsername)
                      Padding(
                        padding: EdgeInsets.only(top: tokens.spacingXs),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            SizedBox(width: tokens.spacingSm),
                            Text(
                              'Checking availability...',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    if (!_isCheckingUsername &&
                        _usernameController.text.trim().isNotEmpty &&
                        _usernameController.text.trim().toLowerCase() !=
                            _originalUsername)
                      Padding(
                        padding: EdgeInsets.only(top: tokens.spacingXs),
                        child: Row(
                          children: [
                            Icon(
                              _isUsernameAvailable
                                  ? Icons.check_circle
                                  : Icons.error,
                              size: 16,
                              color: _isUsernameAvailable
                                  ? Colors.green
                                  : Theme.of(context).colorScheme.error,
                            ),
                            SizedBox(width: tokens.spacingSm),
                            Text(
                              _isUsernameAvailable
                                  ? 'Username is available'
                                  : 'Username is taken',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: _isUsernameAvailable
                                        ? Colors.green
                                        : Theme.of(context).colorScheme.error,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: tokens.spacingLg),
                    AppTextField(
                      controller: _bioController,
                      label: 'Bio',
                      hint: 'Tell us about yourself',
                      maxLines: 4,
                      maxLength: 500,
                      showCounter: true,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    SizedBox(height: tokens.spacingXl),
                    AppButton(
                      text: 'Save Changes',
                      onPressed: _isSaving ? null : _saveProfile,
                      isLoading: _isSaving,
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: tokens.iconXl,
                  color: Theme.of(context).colorScheme.error,
                ),
                SizedBox(height: tokens.spacingLg),
                const Text('Error loading profile'),
                SizedBox(height: tokens.spacingLg),
                AppButton(
                  text: 'Retry',
                  fullWidth: false,
                  onPressed: () {
                    ref.read(userProfileNotifierProvider.notifier).refresh();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
