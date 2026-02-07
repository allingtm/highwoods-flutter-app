import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/invite_quota.dart';
import '../../providers/connections_provider.dart';
import '../../providers/user_profile_provider.dart';
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
  bool _hasConfirmedEligibility = false;

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
    final quotaAsync = ref.watch(inviteQuotaProvider);

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
            SizedBox(height: tokens.spacingXl),

            // Quota Banner
            quotaAsync.when(
              data: (quota) => _buildQuotaBanner(context, tokens, colorScheme, quota),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            SizedBox(height: tokens.spacingXl),

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

            // Eligibility Confirmation
            Container(
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(tokens.radiusMd),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.5),
                ),
              ),
              child: CheckboxListTile(
                value: _hasConfirmedEligibility,
                onChanged: (value) => setState(() {
                  _hasConfirmedEligibility = value ?? false;
                }),
                checkColor: colorScheme.onPrimary,
                activeColor: colorScheme.primary,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  'I confirm this person lives, works, or has a connection to Highwoods',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: tokens.spacingSm,
                  vertical: tokens.spacingXs,
                ),
                dense: true,
              ),
            ),
            SizedBox(height: tokens.spacingXl),

            // Share Button
            FilledButton.icon(
              key: _shareButtonKey,
              onPressed: _isLoading ||
                      _recipientNameController.text.trim().isEmpty ||
                      !_hasConfirmedEligibility ||
                      !(quotaAsync.valueOrNull?.hasRemaining ?? true)
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

  Widget _buildQuotaBanner(
    BuildContext context,
    AppThemeTokens tokens,
    ColorScheme colorScheme,
    InviteQuota quota,
  ) {
    final Color bannerColor;
    final IconData bannerIcon;

    if (quota.isAtCap && !quota.hasRemaining) {
      bannerColor = colorScheme.error;
      bannerIcon = Icons.block;
    } else if (!quota.hasRemaining) {
      bannerColor = Colors.orange;
      bannerIcon = Icons.hourglass_empty;
    } else {
      bannerColor = colorScheme.primary;
      bannerIcon = Icons.mail_outline;
    }

    return Container(
      padding: EdgeInsets.all(tokens.spacingMd),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        border: Border.all(color: bannerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(bannerIcon, color: bannerColor, size: tokens.iconSm),
              SizedBox(width: tokens.spacingSm),
              Expanded(
                child: Text(
                  quota.statusMessage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: bannerColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (quota.hasRemaining) ...[
            SizedBox(height: tokens.spacingSm),
            ClipRRect(
              borderRadius: BorderRadius.circular(tokens.radiusSm),
              child: LinearProgressIndicator(
                value: quota.used / quota.limit,
                backgroundColor: bannerColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(bannerColor),
                minHeight: 6,
              ),
            ),
            SizedBox(height: tokens.spacingXs),
            Text(
              '${quota.used} of ${quota.limit} used',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
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

  String _buildShareMessage(
    String inviteLink,
    String? personalMessage,
    String? code,
    String inviterName,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('$inviterName has invited you to join the Highwoods community app!');
    buffer.writeln();

    if (personalMessage != null && personalMessage.isNotEmpty) {
      buffer.writeln('"$personalMessage"');
      buffer.writeln();
    }

    buffer.writeln('Already a member?');
    buffer.writeln('Tap the link below to connect with $inviterName:');
    buffer.writeln(inviteLink);
    buffer.writeln();

    buffer.writeln('Not a member yet?');
    buffer.writeln('Visit https://highwoods.co.uk for instructions to download the app. Once installed, tap the link above or enter this invite code to register:');
    if (code != null) {
      buffer.writeln(code);
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
      final profile = ref.read(userProfileProvider).valueOrNull;
      final inviterName = profile?.fullName ?? 'A Highwoods member';
      final shareText = _buildShareMessage(
        invitation.inviteLink,
        invitation.message,
        invitation.code,
        inviterName,
      );

      // Open native share sheet
      final box = _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
      await Share.share(
        shareText,
        subject: 'Highwoods Community Invitation',
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
        final message = e.toString().toUpperCase().contains('INVITATION_LIMIT_EXCEEDED')
            ? 'You have used all your available invitations.'
            : 'Failed to create invitation: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        ref.invalidate(inviteQuotaProvider);
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
    final profile = ref.read(userProfileProvider).valueOrNull;
    final inviterName = profile?.fullName ?? 'A Highwoods member';
    final shareText = _buildShareMessage(inviteLink, personalMessage, code, inviterName);
    final box = buttonContext.findRenderObject() as RenderBox?;

    await Share.share(
      shareText,
      subject: 'Highwoods Community Invitation',
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
          const SnackBar(content: Text('Invitation cancelled. Invite slot freed up.')),
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
