import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/connections_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_tokens.dart';

class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key});

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  final _recipientNameController = TextEditingController();
  final _messageController = TextEditingController();
  final _shareButtonKey = GlobalKey();
  bool _isLoading = false;

  @override
  void dispose() {
    _recipientNameController.dispose();
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
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
        padding: EdgeInsets.all(tokens.spacingXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Icon(
              Icons.share_outlined,
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
              'Share an invite link via WhatsApp, SMS, Email, or any app.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: tokens.spacing2xl),

            // Recipient Name Field (required)
            TextFormField(
              controller: _recipientNameController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Who is this invite for?',
                hintText: 'Enter recipient\'s name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: tokens.spacingMd),

            // Personal Message Field
            TextFormField(
              controller: _messageController,
              maxLines: 3,
              maxLength: 200,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Personal Message (optional)',
                hintText: 'Add a personal note to your invitation...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: tokens.spacingLg),

            // Info Box
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

            // Share Button
            FilledButton.icon(
              key: _shareButtonKey,
              onPressed: _isLoading || _recipientNameController.text.trim().isEmpty
                  ? null
                  : _shareInvitation,
              icon: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.share),
              label: Text(_isLoading ? 'Creating link...' : 'Share Invite Link'),
            ),
            SizedBox(height: tokens.spacingMd),

            // Share options hint
            Text(
              'Choose WhatsApp, SMS, Email, or any other app',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: tokens.spacing2xl),

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
          'Your Invitations',
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
                    child: Column(
                      children: [
                        Icon(
                          Icons.send_outlined,
                          color: colorScheme.onSurfaceVariant,
                          size: tokens.iconLg,
                        ),
                        SizedBox(height: tokens.spacingSm),
                        Text(
                          'No invitations shared yet',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
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
                  child: Padding(
                    padding: EdgeInsets.all(tokens.spacingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status row
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: _getStatusColor(invitation.status.name, colorScheme),
                              child: Icon(
                                _getStatusIcon(invitation.status.name),
                                color: colorScheme.onPrimary,
                                size: 16,
                              ),
                            ),
                            SizedBox(width: tokens.spacingSm),
                            Text(
                              invitation.status.name.toUpperCase(),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: _getStatusColor(invitation.status.name, colorScheme),
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const Spacer(),
                            Text(
                              _formatDate(invitation.createdAt),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                        // Recipient name display
                        SizedBox(height: tokens.spacingSm),
                        Text(
                          invitation.recipientDisplay,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        // Invite code display
                        if (invitation.code != null) ...[
                          SizedBox(height: tokens.spacingMd),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: tokens.spacingMd,
                              vertical: tokens.spacingSm,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(tokens.radiusMd),
                              border: Border.all(
                                color: colorScheme.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Code: ',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                Text(
                                  invitation.code!,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                        letterSpacing: 2,
                                        color: colorScheme.primary,
                                      ),
                                ),
                                SizedBox(width: tokens.spacingSm),
                                IconButton(
                                  icon: Icon(Icons.copy, size: 18, color: colorScheme.primary),
                                  onPressed: () => _copyCode(invitation.code!),
                                  tooltip: 'Copy code',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // Action buttons for pending invitations
                        if (invitation.isPending) ...[
                          SizedBox(height: tokens.spacingMd),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Builder(
                              builder: (buttonContext) => TextButton.icon(
                                icon: const Icon(Icons.share, size: 18),
                                label: const Text('Share'),
                                onPressed: () => _reshareInvitation(
                                  invitation.inviteLink,
                                  invitation.message,
                                  invitation.code,
                                  buttonContext,
                                ),
                              ),
                            ),
                              SizedBox(width: tokens.spacingSm),
                              TextButton.icon(
                                icon: Icon(Icons.close, size: 18, color: colorScheme.error),
                                label: Text('Cancel', style: TextStyle(color: colorScheme.error)),
                                onPressed: () => _cancelInvitation(invitation.id),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
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

  String _buildShareMessage(String inviteLink, String? personalMessage, [String? code]) {
    final buffer = StringBuffer();
    buffer.writeln("Hey! I'd like to invite you to join the Highwoods community app.");
    buffer.writeln();

    if (personalMessage != null && personalMessage.isNotEmpty) {
      buffer.writeln(personalMessage);
      buffer.writeln();
    }

    buffer.writeln('Join here: $inviteLink');

    if (code != null) {
      buffer.writeln();
      buffer.writeln('Or enter this invite code: $code');
    }

    return buffer.toString();
  }

  Future<void> _shareInvitation() async {
    setState(() => _isLoading = true);

    try {
      // Create the invitation in the database
      final invitation = await createInvitation(
        ref,
        recipientName: _recipientNameController.text.trim(),
        message: _messageController.text.trim().isNotEmpty
            ? _messageController.text.trim()
            : null,
      );

      // Build the share message
      final shareText = _buildShareMessage(
        invitation.inviteLink,
        invitation.message,
        invitation.code,
      );

      // Open native share sheet
      final box = _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
      await Share.share(
        shareText,
        subject: 'Join the Highwoods Community',
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : Rect.fromLTWH(0, 0, MediaQuery.of(context).size.width, 100),
      );

      if (mounted) {
        FocusScope.of(context).unfocus();
        _recipientNameController.clear();
        _messageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation created!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create invitation: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _reshareInvitation(
    String inviteLink,
    String? personalMessage,
    String? code,
    BuildContext buttonContext,
  ) async {
    final shareText = _buildShareMessage(inviteLink, personalMessage, code);
    final box = buttonContext.findRenderObject() as RenderBox?;

    await Share.share(
      shareText,
      subject: 'Join the Highwoods Community',
      sharePositionOrigin: box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : Rect.fromLTWH(0, 0, MediaQuery.of(context).size.width, 100),
    );
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Code "$code" copied to clipboard')),
    );
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
