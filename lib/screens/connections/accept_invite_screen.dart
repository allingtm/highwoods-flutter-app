import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/invitation.dart';
import '../../providers/connections_provider.dart';
import '../../theme/app_theme.dart';

/// Screen for authenticated users to accept an invitation and connect with the inviter.
/// Shown when an existing member taps an invite link.
class AcceptInviteScreen extends ConsumerStatefulWidget {
  const AcceptInviteScreen({super.key, required this.code});

  final String code;

  @override
  ConsumerState<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends ConsumerState<AcceptInviteScreen> {
  InviteValidationResult? _validation;
  bool _isLoading = true;
  bool _isAccepting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _validateCode();
  }

  Future<void> _validateCode() async {
    if (widget.code.isEmpty) {
      setState(() {
        _errorMessage = 'No invite code provided.';
        _isLoading = false;
      });
      return;
    }

    try {
      final repository = ref.read(connectionsRepositoryProvider);
      final result = await repository.validateInviteCode(widget.code);
      if (mounted) {
        setState(() {
          _validation = result;
          _isLoading = false;
          if (!result.valid) {
            _errorMessage = result.error ?? 'Invalid or expired invite code.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to validate invite code.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _acceptInvitation() async {
    setState(() => _isAccepting = true);

    try {
      final repository = ref.read(connectionsRepositoryProvider);
      await repository.acceptInvitation(widget.code);

      // Refresh connections list
      ref.read(connectionsProvider.notifier).refresh();
      ref.invalidate(inviteQuotaProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected with ${_validation?.inviterName ?? 'member'}!'),
          ),
        );
        context.go('/home?tab=3');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAccepting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accept Invitation'),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(tokens.spacingXl),
          child: _isLoading
              ? const CircularProgressIndicator()
              : _errorMessage != null
                  ? _buildError(context, tokens, colorScheme)
                  : _buildInvitation(context, tokens, colorScheme),
        ),
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    dynamic tokens,
    ColorScheme colorScheme,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: tokens.iconXl,
          color: colorScheme.error,
        ),
        SizedBox(height: tokens.spacingLg),
        Text(
          _errorMessage!,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: tokens.spacingXl),
        OutlinedButton(
          onPressed: () => context.go('/home'),
          child: const Text('Go Home'),
        ),
      ],
    );
  }

  Widget _buildInvitation(
    BuildContext context,
    dynamic tokens,
    ColorScheme colorScheme,
  ) {
    final validation = _validation!;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Inviter avatar
        CircleAvatar(
          radius: 48,
          backgroundColor: colorScheme.primaryContainer,
          backgroundImage: validation.inviterAvatar != null
              ? NetworkImage(validation.inviterAvatar!)
              : null,
          child: validation.inviterAvatar == null
              ? Text(
                  validation.inviterName?.isNotEmpty == true
                      ? validation.inviterName![0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                )
              : null,
        ),
        SizedBox(height: tokens.spacingLg),

        // Inviter name
        Text(
          validation.inviterName ?? 'A member',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: tokens.spacingSm),
        Text(
          'has invited you to connect',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),

        // Personal message
        if (validation.message != null && validation.message!.isNotEmpty) ...[
          SizedBox(height: tokens.spacingXl),
          Container(
            padding: EdgeInsets.all(tokens.spacingMd),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(tokens.radiusMd),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.format_quote,
                  color: colorScheme.onSurfaceVariant,
                  size: tokens.iconSm,
                ),
                SizedBox(width: tokens.spacingSm),
                Expanded(
                  child: Text(
                    validation.message!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],

        SizedBox(height: tokens.spacing2xl),

        // Connect button
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isAccepting ? null : _acceptInvitation,
            icon: _isAccepting
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.person_add),
            label: Text(_isAccepting ? 'Connecting...' : 'Connect'),
          ),
        ),
        SizedBox(height: tokens.spacingMd),
        TextButton(
          onPressed: () => context.go('/home'),
          child: const Text('Not now'),
        ),
      ],
    );
  }
}
