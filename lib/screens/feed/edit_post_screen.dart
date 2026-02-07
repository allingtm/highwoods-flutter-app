import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/post_category.dart';
import '../../models/post_status.dart';
import '../../models/feed/feed_models.dart';
import '../../providers/feed_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../utils/error_utils.dart';
import '../../utils/post_validators.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

/// Screen for editing an existing post
class EditPostScreen extends ConsumerStatefulWidget {
  final String postId;

  const EditPostScreen({super.key, required this.postId});

  @override
  ConsumerState<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends ConsumerState<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();

  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  Post? _post;

  // Marketplace fields
  final _priceController = TextEditingController();
  bool _priceNegotiable = false;
  bool _isFree = false;
  String? _condition;
  bool _pickupAvailable = true;
  bool _deliveryAvailable = false;

  @override
  void dispose() {
    _contentController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _initializeFromPost(Post post) {
    if (_isInitialized) return;

    _post = post;
    _contentController.text = post.content ?? '';

    // Initialize marketplace fields
    if (post.marketplaceDetails != null) {
      final details = post.marketplaceDetails!;
      _priceController.text = details.price?.toString() ?? '';
      _priceNegotiable = details.priceNegotiable;
      _isFree = details.isFree;
      _condition = details.condition;
      _pickupAvailable = details.pickupAvailable;
      _deliveryAvailable = details.deliveryAvailable;
    }

    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final postAsync = ref.watch(postDetailProvider(widget.postId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Post'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_post != null)
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value),
              itemBuilder: (context) => [
                if (_post!.status == PostStatus.active) ...[
                  if (_post!.category == PostCategory.marketplace)
                    const PopupMenuItem(
                      value: 'mark_sold',
                      child: Text('Mark as Sold'),
                    ),
                  if (_post!.category == PostCategory.lostFound)
                    const PopupMenuItem(
                      value: 'mark_resolved',
                      child: Text('Mark as Resolved'),
                    ),
                  const PopupMenuItem(
                    value: 'mark_expired',
                    child: Text('Mark as Expired'),
                  ),
                ],
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete Post', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              ],
            ),
        ],
      ),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text('Failed to load post', style: AppTypography.headlineSmall),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(postDetailProvider(widget.postId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (post) {
          if (post == null) {
            return const Center(child: Text('Post not found'));
          }

          _initializeFromPost(post);

          return Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(tokens.spacingLg),
              children: [
                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: EdgeInsets.all(tokens.spacingMd),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(tokens.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                        SizedBox(width: tokens.spacingSm),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: tokens.spacingLg),
                ],

                // Post type info (read-only)
                _PostTypeInfo(post: post),
                SizedBox(height: tokens.spacingLg),

                // Content field
                AppTextField.postContent(
                  controller: _contentController,
                  validator: PostValidators.body().call,
                  inputFormatters: [SanitizingTextInputFormatter()],
                ),
                SizedBox(height: tokens.spacingLg),

                // Category-specific fields
                _buildCategorySpecificFields(post),

                // Submit button
                SizedBox(height: tokens.spacingXl),
                AppButton(
                  text: 'Save Changes',
                  isLoading: _isLoading,
                  onPressed: _submitChanges,
                ),
                SizedBox(height: tokens.spacing2xl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategorySpecificFields(Post post) {
    if (post.category == PostCategory.marketplace) {
      return _MarketplaceEditFields(
        priceController: _priceController,
        priceNegotiable: _priceNegotiable,
        isFree: _isFree,
        condition: _condition,
        pickupAvailable: _pickupAvailable,
        deliveryAvailable: _deliveryAvailable,
        onPriceNegotiableChanged: (v) => setState(() => _priceNegotiable = v),
        onIsFreeChanged: (v) => setState(() {
          _isFree = v;
          if (v) _priceController.clear();
        }),
        onConditionChanged: (v) => setState(() => _condition = v),
        onPickupAvailableChanged: (v) => setState(() => _pickupAvailable = v),
        onDeliveryAvailableChanged: (v) => setState(() => _deliveryAvailable = v),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case 'mark_sold':
      case 'mark_resolved':
        await _updateStatus('resolved');
        break;
      case 'mark_expired':
        await _updateStatus('expired');
        break;
      case 'delete':
        await _confirmDelete();
        break;
    }
  }

  Future<void> _updateStatus(String status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Status Change'),
        content: Text('Are you sure you want to mark this post as $status?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(feedActionsProvider.notifier).updatePostStatus(
        postId: widget.postId,
        status: status,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post marked as $status'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
     } catch (e, stackTrace) {
      setState(() => _errorMessage = handleError(e, stackTrace, operation: 'edit_post'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(feedActionsProvider.notifier).deletePost(widget.postId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/feed');
      }
    } catch (e, stackTrace) {
      setState(() => _errorMessage = handleError(e, stackTrace, operation: 'edit_post'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_post == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Build marketplace details if applicable
      MarketplaceDetails? marketplaceDetails;
      if (_post!.category == PostCategory.marketplace && _post!.marketplaceDetails != null) {
        final price = _isFree ? null : double.tryParse(_priceController.text);
        marketplaceDetails = _post!.marketplaceDetails!.copyWith(
          price: price,
          priceNegotiable: _priceNegotiable,
          isFree: _isFree,
          condition: _condition,
          pickupAvailable: _pickupAvailable,
          deliveryAvailable: _deliveryAvailable,
        );
      }

      await ref.read(feedActionsProvider.notifier).updatePost(
        postId: widget.postId,
        content: PostSanitizers.sanitizeText(_contentController.text),
        marketplaceDetails: marketplaceDetails,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post updated successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e, stackTrace) {
      setState(() => _errorMessage = handleError(e, stackTrace, operation: 'edit_post'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

/// Shows post type info (read-only)
class _PostTypeInfo extends StatelessWidget {
  final Post post;

  const _PostTypeInfo({required this.post});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      padding: EdgeInsets.all(tokens.spacingMd),
      decoration: BoxDecoration(
        color: post.category.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        border: Border.all(color: post.category.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(post.category.icon, color: post.category.color),
          SizedBox(width: tokens.spacingSm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.category.displayName,
                style: AppTypography.labelMedium.copyWith(
                  color: post.category.color,
                ),
              ),
              Text(
                post.postType.displayName,
                style: AppTypography.caption.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Marketplace-specific edit fields
class _MarketplaceEditFields extends StatelessWidget {
  final TextEditingController priceController;
  final bool priceNegotiable;
  final bool isFree;
  final String? condition;
  final bool pickupAvailable;
  final bool deliveryAvailable;
  final ValueChanged<bool> onPriceNegotiableChanged;
  final ValueChanged<bool> onIsFreeChanged;
  final ValueChanged<String?> onConditionChanged;
  final ValueChanged<bool> onPickupAvailableChanged;
  final ValueChanged<bool> onDeliveryAvailableChanged;

  const _MarketplaceEditFields({
    required this.priceController,
    required this.priceNegotiable,
    required this.isFree,
    required this.condition,
    required this.pickupAvailable,
    required this.deliveryAvailable,
    required this.onPriceNegotiableChanged,
    required this.onIsFreeChanged,
    required this.onConditionChanged,
    required this.onPickupAvailableChanged,
    required this.onDeliveryAvailableChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          value: isFree,
          onChanged: onIsFreeChanged,
          title: const Text('This item is free'),
          contentPadding: EdgeInsets.zero,
        ),
        if (!isFree) ...[
          AppTextField(
            controller: priceController,
            label: 'Price',
            hint: '0.00',
            prefixIcon: Icons.currency_pound,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: PostValidators.price,
            inputFormatters: [DecimalInputFormatter()],
          ),
          SizedBox(height: tokens.spacingSm),
          CheckboxListTile(
            value: priceNegotiable,
            onChanged: (v) => onPriceNegotiableChanged(v ?? false),
            title: const Text('Price is negotiable'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
        SizedBox(height: tokens.spacingMd),
        DropdownButtonFormField<String>(
          value: condition,
          decoration: const InputDecoration(
            labelText: 'Condition',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'new', child: Text('New')),
            DropdownMenuItem(value: 'like_new', child: Text('Like New')),
            DropdownMenuItem(value: 'good', child: Text('Good')),
            DropdownMenuItem(value: 'fair', child: Text('Fair')),
            DropdownMenuItem(value: 'poor', child: Text('Poor')),
          ],
          onChanged: onConditionChanged,
        ),
        SizedBox(height: tokens.spacingMd),
        Text('Collection options', style: AppTypography.labelMedium),
        CheckboxListTile(
          value: pickupAvailable,
          onChanged: (v) => onPickupAvailableChanged(v ?? true),
          title: const Text('Pickup available'),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          value: deliveryAvailable,
          onChanged: (v) => onDeliveryAvailableChanged(v ?? false),
          title: const Text('Delivery available'),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
