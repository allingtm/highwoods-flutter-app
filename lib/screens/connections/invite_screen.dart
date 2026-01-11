import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/connections_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_tokens.dart';

class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key});

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite Someone'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(tokens.spacingXl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Icon(
                Icons.person_add_outlined,
                size: tokens.iconXl,
                color: colorScheme.primary,
              ),
              SizedBox(height: tokens.spacingLg),
              Text(
                'Invite a Connection',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: tokens.spacingSm),
              Text(
                'Invite neighbours and local businesses to join the Highwoods community.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: tokens.spacing2xl),

              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'neighbour@email.com',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an email address';
                  }
                  final emailRegex = RegExp(
                    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
                  );
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              SizedBox(height: tokens.spacingLg),

              // Personal Message Field
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                maxLength: 500,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Personal Message (optional)',
                  hintText: 'Hi! I\'d love to connect with you on the Highwoods community app...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: tokens.spacingLg),

              // Warning
              Container(
                padding: EdgeInsets.all(tokens.spacingMd),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(tokens.radiusMd),
                  border: Border.all(
                    color: colorScheme.tertiary.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.tertiary,
                      size: tokens.iconSm,
                    ),
                    SizedBox(width: tokens.spacingMd),
                    Expanded(
                      child: Text(
                        'Only invite people who live or work in Highwoods',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onTertiaryContainer,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: tokens.spacingXl),

              // Submit Button
              FilledButton(
                onPressed: _isLoading ? null : _sendInvitation,
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : const Text('Send Invitation'),
              ),
              SizedBox(height: tokens.spacingXl),

              // Sent Invitations Section
              _buildSentInvitations(context, tokens, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSentInvitations(
    BuildContext context,
    AppThemeTokens tokens,
    ColorScheme colorScheme,
  ) {
    final invitations = ref.watch(invitationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sent Invitations',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: tokens.spacingMd),
        invitations.when(
          data: (list) {
            if (list.isEmpty) {
              return Card(
                child: Padding(
                  padding: EdgeInsets.all(tokens.spacingLg),
                  child: Center(
                    child: Text(
                      'No invitations sent yet',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final invitation = list[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(invitation.status.name, colorScheme),
                      child: Icon(
                        _getStatusIcon(invitation.status.name),
                        color: colorScheme.onPrimary,
                        size: tokens.iconSm,
                      ),
                    ),
                    title: Text(invitation.email),
                    subtitle: Text(
                      '${invitation.status.name.toUpperCase()} - ${_formatDate(invitation.createdAt)}',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    trailing: invitation.isPending
                        ? IconButton(
                            icon: Icon(Icons.close, color: colorScheme.error),
                            onPressed: () => _cancelInvitation(invitation.id),
                            tooltip: 'Cancel',
                          )
                        : null,
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Card(
            child: Padding(
              padding: EdgeInsets.all(tokens.spacingLg),
              child: Text('Error loading invitations: $error'),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'pending':
        return colorScheme.primary;
      case 'accepted':
        return Colors.green;
      case 'expired':
        return colorScheme.outline;
      default:
        return colorScheme.outline;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'accepted':
        return Icons.check;
      case 'expired':
        return Icons.timer_off;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _sendInvitation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await sendInvitation(
        ref,
        email: _emailController.text.trim(),
        message: _messageController.text.trim().isNotEmpty
            ? _messageController.text.trim()
            : null,
      );

      if (mounted) {
        _emailController.clear();
        _messageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation sent successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send invitation: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cancelInvitation(String invitationId) async {
    try {
      await cancelInvitation(ref, invitationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation cancelled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel: $e')),
        );
      }
    }
  }
}
