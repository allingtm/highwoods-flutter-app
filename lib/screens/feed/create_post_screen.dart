import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/post_category.dart';
import '../../models/post_type.dart';
import '../../models/feed/feed_models.dart';
import '../../providers/feed_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_tokens.dart';
import '../../utils/error_utils.dart';
import '../../utils/post_validators.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/feed/image_picker_widget.dart';
import '../../widgets/feed/media_picker_widget.dart';

/// Wizard steps for creating a post
enum CreatePostStep {
  categorySelection,
  subCategorySelection,
  postDetails,
}

/// Screen for creating a new community post
class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key, this.initialCategory});

  /// Optional initial category to pre-select (e.g., when coming from filtered feed)
  final PostCategory? initialCategory;

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();

  // Wizard state
  CreatePostStep _currentStep = CreatePostStep.categorySelection;
  bool _isDiscussionFlow = false;

  // Form state
  PostCategory? _selectedCategory;
  PostType? _selectedPostType;
  bool _isLoading = false;
  String? _errorMessage;

  // Media
  List<SelectedImage> _selectedImages = [];
  SelectedVideo? _selectedVideo;

  // Category-specific controllers
  // Marketplace
  final _priceController = TextEditingController();
  bool _priceNegotiable = false;
  bool _isFree = false;
  String? _condition;
  bool _pickupAvailable = true;
  bool _deliveryAvailable = false;

  // Event
  DateTime? _eventDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _venueNameController = TextEditingController();
  final _maxAttendeesController = TextEditingController();
  bool _rsvpRequired = false;

  // Lost & Found
  final _petNameController = TextEditingController();
  final _petTypeController = TextEditingController();
  final _petBreedController = TextEditingController();
  final _petColorController = TextEditingController();
  DateTime? _dateLostFound;
  final _lastSeenLocationController = TextEditingController();
  bool _rewardOffered = false;
  final _rewardAmountController = TextEditingController();

  // Jobs
  JobType _jobType = JobType.oneTime;
  bool _isPaid = true;
  final _hourlyRateController = TextEditingController();
  bool _paymentNegotiable = false;
  bool _remotePossible = false;

  @override
  void initState() {
    super.initState();
    // Pre-select category if provided (e.g., from filtered feed)
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory;
      _currentStep = CreatePostStep.subCategorySelection;
    }
  }

  // Navigation logic methods

  void _onDiscussionSelected() {
    setState(() {
      _isDiscussionFlow = true;
      _selectedCategory = PostCategory.social;
      _selectedPostType = PostType.discussion;
      _currentStep = CreatePostStep.postDetails;
      _errorMessage = null;
    });
  }

  void _onCategorySelected(PostCategory category) {
    setState(() {
      _isDiscussionFlow = false;
      _selectedCategory = category;
      _selectedPostType = null;
      _currentStep = CreatePostStep.subCategorySelection;
      _errorMessage = null;
    });
  }

  void _onPostTypeSelected(PostType type) {
    setState(() {
      _selectedPostType = type;
      _currentStep = CreatePostStep.postDetails;
      _errorMessage = null;
    });
  }

  void _goBack() {
    FocusScope.of(context).unfocus();
    setState(() {
      _errorMessage = null;
      if (_currentStep == CreatePostStep.postDetails) {
        if (_isDiscussionFlow) {
          _currentStep = CreatePostStep.categorySelection;
          _selectedCategory = null;
          _selectedPostType = null;
          _isDiscussionFlow = false;
        } else {
          _currentStep = CreatePostStep.subCategorySelection;
          _selectedPostType = null;
        }
      } else if (_currentStep == CreatePostStep.subCategorySelection) {
        _currentStep = CreatePostStep.categorySelection;
        _selectedCategory = null;
      }
    });
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case CreatePostStep.categorySelection:
        return 'Create Post';
      case CreatePostStep.subCategorySelection:
        return 'Select Type';
      case CreatePostStep.postDetails:
        return _selectedPostType?.displayName ?? 'Post Details';
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _priceController.dispose();
    _venueNameController.dispose();
    _maxAttendeesController.dispose();
    _petNameController.dispose();
    _petTypeController.dispose();
    _petBreedController.dispose();
    _petColorController.dispose();
    _lastSeenLocationController.dispose();
    _rewardAmountController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getStepTitle()),
        leading: IconButton(
          icon: Icon(
            _currentStep == CreatePostStep.categorySelection
                ? Icons.close_rounded
                : Icons.arrow_back_rounded,
          ),
          onPressed: _currentStep == CreatePostStep.categorySelection
              ? () => context.pop()
              : _goBack,
        ),
      ),
      body: Form(
        key: _formKey,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _buildCurrentStep(tokens, theme),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(AppThemeTokens tokens, ThemeData theme) {
    switch (_currentStep) {
      case CreatePostStep.categorySelection:
        return _buildCategorySelectionStep(tokens, theme);
      case CreatePostStep.subCategorySelection:
        return _buildSubCategorySelectionStep(tokens, theme);
      case CreatePostStep.postDetails:
        return _buildPostDetailsStep(tokens, theme);
    }
  }

  Widget _buildCategorySelectionStep(AppThemeTokens tokens, ThemeData theme) {
    return ListView(
      key: const ValueKey('categorySelection'),
      padding: EdgeInsets.all(tokens.spacingLg),
      children: [
        Text(
          'What would you like to share?',
          style: theme.textTheme.titleMedium,
        ),
        SizedBox(height: tokens.spacingMd),
        _CategorySelector(
          selectedCategory: _selectedCategory,
          isDiscussionSelected: _isDiscussionFlow,
          onCategorySelected: _onCategorySelected,
          onDiscussionSelected: _onDiscussionSelected,
        ),
      ],
    );
  }

  Widget _buildSubCategorySelectionStep(AppThemeTokens tokens, ThemeData theme) {
    return ListView(
      key: const ValueKey('subCategorySelection'),
      padding: EdgeInsets.all(tokens.spacingLg),
      children: [
        // Category header with icon
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(tokens.spacingSm),
              decoration: BoxDecoration(
                color: _selectedCategory!.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(tokens.radiusMd),
              ),
              child: Icon(
                _selectedCategory!.icon,
                color: _selectedCategory!.color,
                size: tokens.iconSm,
              ),
            ),
            SizedBox(width: tokens.spacingSm),
            Text(
              _selectedCategory!.displayName,
              style: theme.textTheme.titleMedium?.copyWith(
                color: _selectedCategory!.color,
              ),
            ),
          ],
        ),
        SizedBox(height: tokens.spacingLg),
        Text(
          'What type of ${_selectedCategory!.displayName.toLowerCase()}?',
          style: theme.textTheme.titleMedium,
        ),
        SizedBox(height: tokens.spacingMd),
        _PostTypeSelector(
          category: _selectedCategory!,
          selectedType: _selectedPostType,
          onTypeSelected: _onPostTypeSelected,
        ),
      ],
    );
  }

  Widget _buildPostDetailsStep(AppThemeTokens tokens, ThemeData theme) {
    return ListView(
      key: const ValueKey('postDetails'),
      padding: EdgeInsets.all(tokens.spacingLg),
      children: [
        // Error message
        if (_errorMessage != null) ...[
          Container(
            padding: EdgeInsets.all(tokens.spacingMd),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(tokens.radiusMd),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: theme.colorScheme.onErrorContainer,
                ),
                SizedBox(width: tokens.spacingSm),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.spacingLg),
        ],

        // Post type header
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(tokens.spacingSm),
              decoration: BoxDecoration(
                color: _selectedCategory!.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(tokens.radiusMd),
              ),
              child: Icon(
                _selectedCategory!.icon,
                color: _selectedCategory!.color,
                size: tokens.iconSm,
              ),
            ),
            SizedBox(width: tokens.spacingSm),
            Text(
              _selectedPostType!.displayName,
              style: theme.textTheme.titleMedium?.copyWith(
                color: _selectedCategory!.color,
              ),
            ),
          ],
        ),
        SizedBox(height: tokens.spacingLg),

        // Content field
        AppTextField.postContent(
          controller: _contentController,
          label: _selectedPostType!.contentLabel,
          hint: _selectedPostType!.contentHint,
          validator: PostValidators.body().call,
          inputFormatters: [SanitizingTextInputFormatter()],
        ),
        SizedBox(height: tokens.spacingLg),

        // Media picker (photos or video)
        MediaPickerWidget(
          images: _selectedImages,
          video: _selectedVideo,
          maxImages: 5,
          onImagesChanged: (images) {
            setState(() {
              _selectedImages = images;
            });
          },
          onVideoChanged: (video) {
            setState(() {
              _selectedVideo = video;
            });
          },
          onError: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        SizedBox(height: tokens.spacingLg),

        // Category-specific fields
        _buildCategorySpecificFields(),

        // Submit button
        SizedBox(height: tokens.spacingXl),
        AppButton(
          text: 'Create Post',
          isLoading: _isLoading,
          onPressed: _submitPost,
        ),
        SizedBox(height: tokens.spacing2xl),
      ],
    );
  }

  Widget _buildCategorySpecificFields() {
    switch (_selectedCategory) {
      case PostCategory.marketplace:
        return _MarketplaceFields(
          priceController: _priceController,
          priceNegotiable: _priceNegotiable,
          isFree: _isFree,
          condition: _condition,
          pickupAvailable: _pickupAvailable,
          deliveryAvailable: _deliveryAvailable,
          onPriceNegotiableChanged: (value) => setState(() => _priceNegotiable = value),
          onIsFreeChanged: (value) => setState(() {
            _isFree = value;
            if (value) _priceController.clear();
          }),
          onConditionChanged: (value) => setState(() => _condition = value),
          onPickupAvailableChanged: (value) => setState(() => _pickupAvailable = value),
          onDeliveryAvailableChanged: (value) => setState(() => _deliveryAvailable = value),
        );

      case PostCategory.social:
        if (_selectedPostType == PostType.event) {
          return _EventFields(
            eventDate: _eventDate,
            startTime: _startTime,
            endTime: _endTime,
            venueNameController: _venueNameController,
            maxAttendeesController: _maxAttendeesController,
            rsvpRequired: _rsvpRequired,
            onEventDateChanged: (date) => setState(() => _eventDate = date),
            onStartTimeChanged: (time) => setState(() => _startTime = time),
            onEndTimeChanged: (time) => setState(() => _endTime = time),
            onRsvpRequiredChanged: (value) => setState(() => _rsvpRequired = value),
          );
        }
        return const SizedBox.shrink();

      case PostCategory.lostFound:
        final isPet = _selectedPostType == PostType.lostPet ||
            _selectedPostType == PostType.foundPet;
        return _LostFoundFields(
          isPet: isPet,
          petNameController: _petNameController,
          petTypeController: _petTypeController,
          petBreedController: _petBreedController,
          petColorController: _petColorController,
          dateLostFound: _dateLostFound,
          lastSeenLocationController: _lastSeenLocationController,
          rewardOffered: _rewardOffered,
          rewardAmountController: _rewardAmountController,
          onDateLostFoundChanged: (date) => setState(() => _dateLostFound = date),
          onRewardOfferedChanged: (value) => setState(() => _rewardOffered = value),
        );

      case PostCategory.jobs:
        return _JobFields(
          jobType: _jobType,
          isPaid: _isPaid,
          hourlyRateController: _hourlyRateController,
          paymentNegotiable: _paymentNegotiable,
          remotePossible: _remotePossible,
          onJobTypeChanged: (type) => setState(() => _jobType = type),
          onIsPaidChanged: (value) => setState(() => _isPaid = value),
          onPaymentNegotiableChanged: (value) => setState(() => _paymentNegotiable = value),
          onRemotePossibleChanged: (value) => setState(() => _remotePossible = value),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null || _selectedPostType == null) return;

    // Additional validation for event posts
    if (_selectedPostType == PostType.event) {
      if (_eventDate == null) {
        setState(() {
          _errorMessage = 'Please select an event date';
        });
        return;
      }

      // Validate end time is after start time
      final timeError = PostValidators.eventTimes(_startTime, _endTime);
      if (timeError != null) {
        setState(() {
          _errorMessage = timeError;
        });
        return;
      }

      // Validate event is not in the past
      final pastError = PostValidators.eventNotInPast(_eventDate, _startTime);
      if (pastError != null) {
        setState(() {
          _errorMessage = pastError;
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Build category-specific details
      MarketplaceDetails? marketplaceDetails;
      EventDetails? eventDetails;
      LostFoundDetails? lostFoundDetails;
      JobDetails? jobDetails;

      if (_selectedCategory == PostCategory.marketplace) {
        final price = _isFree ? null : double.tryParse(_priceController.text);
        marketplaceDetails = MarketplaceDetails(
          id: '',
          postId: '',
          price: price,
          priceNegotiable: _priceNegotiable,
          isFree: _isFree,
          condition: _condition,
          pickupAvailable: _pickupAvailable,
          deliveryAvailable: _deliveryAvailable,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      if (_selectedPostType == PostType.event) {
        eventDetails = EventDetails(
          id: '',
          postId: '',
          eventDate: _eventDate!,
          startTime: _startTime,
          endTime: _endTime,
          venueName: _venueNameController.text.isEmpty ? null : _venueNameController.text,
          maxAttendees: int.tryParse(_maxAttendeesController.text),
          rsvpRequired: _rsvpRequired,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      if (_selectedCategory == PostCategory.lostFound) {
        lostFoundDetails = LostFoundDetails(
          id: '',
          postId: '',
          petName: _petNameController.text.isEmpty ? null : _petNameController.text,
          petType: _petTypeController.text.isEmpty ? null : _petTypeController.text,
          petBreed: _petBreedController.text.isEmpty ? null : _petBreedController.text,
          petColor: _petColorController.text.isEmpty ? null : _petColorController.text,
          dateLostFound: _dateLostFound,
          lastSeenLocation: _lastSeenLocationController.text.isEmpty
              ? null
              : _lastSeenLocationController.text,
          rewardOffered: _rewardOffered,
          rewardAmount: _rewardOffered ? double.tryParse(_rewardAmountController.text) : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      if (_selectedCategory == PostCategory.jobs) {
        jobDetails = JobDetails(
          id: '',
          postId: '',
          jobType: _jobType,
          isPaid: _isPaid,
          hourlyRate: _isPaid ? double.tryParse(_hourlyRateController.text) : null,
          paymentNegotiable: _paymentNegotiable,
          remotePossible: _remotePossible,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      // Extract files from selected media
      final imageFiles = _selectedImages.map((img) => img.file).toList();

      await ref.read(feedActionsProvider.notifier).createPost(
        category: _selectedCategory!,
        postType: _selectedPostType!,
        content: PostSanitizers.sanitizeText(_contentController.text),
        marketplaceDetails: marketplaceDetails,
        eventDetails: eventDetails,
        lostFoundDetails: lostFoundDetails,
        jobDetails: jobDetails,
        imageFiles: imageFiles.isNotEmpty ? imageFiles : null,
        videoFile: _selectedVideo?.file,
        videoDurationSeconds: _selectedVideo?.durationSeconds,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e, stackTrace) {
      setState(() {
        _errorMessage = handleError(e, stackTrace, operation: 'create_post');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

/// Category selection step with Discussion tile at top
class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.selectedCategory,
    required this.isDiscussionSelected,
    required this.onCategorySelected,
    required this.onDiscussionSelected,
  });

  final PostCategory? selectedCategory;
  final bool isDiscussionSelected;
  final ValueChanged<PostCategory> onCategorySelected;
  final VoidCallback onDiscussionSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Full-width Discussion tile at top
        _DiscussionTile(
          isSelected: isDiscussionSelected,
          onTap: onDiscussionSelected,
        ),
        SizedBox(height: tokens.spacingMd),
        // 6 category tiles in 2x3 grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: tokens.spacingMd,
          crossAxisSpacing: tokens.spacingMd,
          childAspectRatio: 1.5,
          children: PostCategory.values.map((category) {
            final isSelected = selectedCategory == category && !isDiscussionSelected;
            return _CategoryCard(
              category: category,
              isSelected: isSelected,
              onTap: () => onCategorySelected(category),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final PostCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Material(
      color: isSelected ? category.color.withValues(alpha: 0.15) : theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(tokens.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? category.color : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(tokens.radiusLg),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                category.icon,
                color: isSelected ? category.color : theme.colorScheme.onSurfaceVariant,
                size: tokens.iconMd,
              ),
              SizedBox(height: tokens.spacingSm),
              Text(
                category.displayName,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected ? category.color : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width tile for Discussion option at top of category selection
class _DiscussionTile extends StatelessWidget {
  const _DiscussionTile({
    required this.isSelected,
    required this.onTap,
  });

  final bool isSelected;
  final VoidCallback onTap;

  // Discussion uses the social category color (purple)
  static const _color = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Material(
      color: isSelected ? _color.withValues(alpha: 0.15) : theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(tokens.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacingLg,
            vertical: tokens.spacingMd,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? _color : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(tokens.radiusLg),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.forum_rounded,
                color: isSelected ? _color : theme.colorScheme.onSurfaceVariant,
                size: tokens.iconMd,
              ),
              SizedBox(height: tokens.spacingSm),
              Text(
                'Discussion',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected ? _color : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// List of post types for selected category
class _PostTypeSelector extends StatelessWidget {
  const _PostTypeSelector({
    required this.category,
    required this.selectedType,
    required this.onTypeSelected,
  });

  final PostCategory category;
  final PostType? selectedType;
  final ValueChanged<PostType> onTypeSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    // Filter out discussion from social category since it's now a top-level option
    final types = PostType.forCategory(category)
        .where((t) => t != PostType.discussion)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: tokens.spacingSm,
          runSpacing: tokens.spacingSm,
          children: types.map((type) {
            final isSelected = selectedType == type;
            return ChoiceChip(
              label: Text(type.displayName),
              selected: isSelected,
              onSelected: (_) => onTypeSelected(type),
              selectedColor: category.color.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? category.color : null,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            );
          }).toList(),
        ),
        // Show description when a type is selected
        if (selectedType != null) ...[
          SizedBox(height: tokens.spacingMd),
          Container(
            padding: EdgeInsets.all(tokens.spacingMd),
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(tokens.radiusMd),
              border: Border.all(
                color: category.color.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: tokens.iconSm,
                  color: category.color,
                ),
                SizedBox(width: tokens.spacingSm),
                Expanded(
                  child: Text(
                    selectedType!.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Marketplace-specific form fields
class _MarketplaceFields extends StatelessWidget {
  const _MarketplaceFields({
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

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Free item toggle
        SwitchListTile(
          value: isFree,
          onChanged: onIsFreeChanged,
          title: const Text('This item is free'),
          contentPadding: EdgeInsets.zero,
        ),

        // Price field (hidden if free)
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
            onChanged: (value) => onPriceNegotiableChanged(value ?? false),
            title: const Text('Price is negotiable'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
        SizedBox(height: tokens.spacingMd),

        // Condition dropdown
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

        // Collection options
        Text(
          'Collection options',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        CheckboxListTile(
          value: pickupAvailable,
          onChanged: (value) => onPickupAvailableChanged(value ?? true),
          title: const Text('Pickup available'),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          value: deliveryAvailable,
          onChanged: (value) => onDeliveryAvailableChanged(value ?? false),
          title: const Text('Delivery available'),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

/// Event-specific form fields
class _EventFields extends StatelessWidget {
  const _EventFields({
    required this.eventDate,
    required this.startTime,
    required this.endTime,
    required this.venueNameController,
    required this.maxAttendeesController,
    required this.rsvpRequired,
    required this.onEventDateChanged,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
    required this.onRsvpRequiredChanged,
  });

  final DateTime? eventDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final TextEditingController venueNameController;
  final TextEditingController maxAttendeesController;
  final bool rsvpRequired;
  final ValueChanged<DateTime?> onEventDateChanged;
  final ValueChanged<TimeOfDay?> onStartTimeChanged;
  final ValueChanged<TimeOfDay?> onEndTimeChanged;
  final ValueChanged<bool> onRsvpRequiredChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Event date picker
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.calendar_today_rounded),
          title: Text(
            eventDate != null
                ? '${eventDate!.day}/${eventDate!.month}/${eventDate!.year}'
                : 'Select event date *',
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: eventDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              onEventDateChanged(date);
            }
          },
        ),
        SizedBox(height: tokens.spacingSm),

        // Time pickers
        Row(
          children: [
            Expanded(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time_rounded),
                title: Text(
                  startTime != null
                      ? '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}'
                      : 'Start time',
                ),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: startTime ?? TimeOfDay.now(),
                  );
                  if (time != null) {
                    onStartTimeChanged(time);
                  }
                },
              ),
            ),
            Expanded(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time_rounded),
                title: Text(
                  endTime != null
                      ? '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}'
                      : 'End time',
                ),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: endTime ?? TimeOfDay.now(),
                  );
                  if (time != null) {
                    onEndTimeChanged(time);
                  }
                },
              ),
            ),
          ],
        ),
        SizedBox(height: tokens.spacingMd),

        // Venue name
        AppTextField(
          controller: venueNameController,
          label: 'Venue name',
          hint: 'Where is it happening?',
          prefixIcon: Icons.location_on_outlined,
          textCapitalization: TextCapitalization.words,
          maxLength: PostFieldLimits.venueNameMax,
          showCounter: true,
          warningThreshold: 20,
          validator: PostValidators.venueName,
        ),
        SizedBox(height: tokens.spacingMd),

        // Max attendees
        AppTextField(
          controller: maxAttendeesController,
          label: 'Max attendees',
          hint: 'Leave empty for unlimited',
          prefixIcon: Icons.people_outline_rounded,
          keyboardType: TextInputType.number,
          validator: PostValidators.maxAttendees,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        SizedBox(height: tokens.spacingSm),

        // RSVP required
        SwitchListTile(
          value: rsvpRequired,
          onChanged: onRsvpRequiredChanged,
          title: const Text('RSVP required'),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

/// Lost & Found-specific form fields
class _LostFoundFields extends StatelessWidget {
  const _LostFoundFields({
    required this.isPet,
    required this.petNameController,
    required this.petTypeController,
    required this.petBreedController,
    required this.petColorController,
    required this.dateLostFound,
    required this.lastSeenLocationController,
    required this.rewardOffered,
    required this.rewardAmountController,
    required this.onDateLostFoundChanged,
    required this.onRewardOfferedChanged,
  });

  final bool isPet;
  final TextEditingController petNameController;
  final TextEditingController petTypeController;
  final TextEditingController petBreedController;
  final TextEditingController petColorController;
  final DateTime? dateLostFound;
  final TextEditingController lastSeenLocationController;
  final bool rewardOffered;
  final TextEditingController rewardAmountController;
  final ValueChanged<DateTime?> onDateLostFoundChanged;
  final ValueChanged<bool> onRewardOfferedChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pet-specific fields
        if (isPet) ...[
          AppTextField(
            controller: petNameController,
            label: 'Pet name',
            hint: 'What is their name?',
            prefixIcon: Icons.pets_rounded,
            textCapitalization: TextCapitalization.words,
            maxLength: PostFieldLimits.petFieldMax,
            showCounter: true,
            warningThreshold: 10,
            validator: (v) => PostValidators.petField(v, 'Pet name'),
          ),
          SizedBox(height: tokens.spacingMd),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: petTypeController,
                  label: 'Pet type',
                  hint: 'Dog, Cat, etc.',
                  textCapitalization: TextCapitalization.words,
                  maxLength: PostFieldLimits.petFieldMax,
                  showCounter: true,
                  warningThreshold: 10,
                  validator: (v) => PostValidators.petField(v, 'Pet type'),
                ),
              ),
              SizedBox(width: tokens.spacingMd),
              Expanded(
                child: AppTextField(
                  controller: petBreedController,
                  label: 'Breed',
                  hint: 'Optional',
                  textCapitalization: TextCapitalization.words,
                  maxLength: PostFieldLimits.petFieldMax,
                  showCounter: true,
                  warningThreshold: 10,
                  validator: (v) => PostValidators.petField(v, 'Breed'),
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spacingMd),
          AppTextField(
            controller: petColorController,
            label: 'Color/markings',
            hint: 'Describe their appearance',
            textCapitalization: TextCapitalization.sentences,
            maxLength: PostFieldLimits.petFieldMax,
            showCounter: true,
            warningThreshold: 10,
            validator: (v) => PostValidators.petField(v, 'Color/markings'),
          ),
          SizedBox(height: tokens.spacingMd),
        ],

        // Date lost/found
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.calendar_today_rounded),
          title: Text(
            dateLostFound != null
                ? 'Date: ${dateLostFound!.day}/${dateLostFound!.month}/${dateLostFound!.year}'
                : 'When was it lost/found?',
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: dateLostFound ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              onDateLostFoundChanged(date);
            }
          },
        ),
        SizedBox(height: tokens.spacingMd),

        // Last seen location
        AppTextField(
          controller: lastSeenLocationController,
          label: 'Last seen location',
          hint: 'Where was it last seen?',
          prefixIcon: Icons.location_on_outlined,
          textCapitalization: TextCapitalization.sentences,
          maxLength: PostFieldLimits.lastSeenLocationMax,
          showCounter: true,
          warningThreshold: 30,
          validator: PostValidators.lastSeenLocation,
        ),
        SizedBox(height: tokens.spacingMd),

        // Reward offered
        SwitchListTile(
          value: rewardOffered,
          onChanged: onRewardOfferedChanged,
          title: const Text('Reward offered'),
          contentPadding: EdgeInsets.zero,
        ),

        if (rewardOffered) ...[
          AppTextField(
            controller: rewardAmountController,
            label: 'Reward amount',
            hint: 'Optional - leave empty for unspecified',
            prefixIcon: Icons.currency_pound,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: PostValidators.rewardAmount,
            inputFormatters: [DecimalInputFormatter()],
          ),
        ],
      ],
    );
  }
}

/// Jobs-specific form fields
class _JobFields extends StatelessWidget {
  const _JobFields({
    required this.jobType,
    required this.isPaid,
    required this.hourlyRateController,
    required this.paymentNegotiable,
    required this.remotePossible,
    required this.onJobTypeChanged,
    required this.onIsPaidChanged,
    required this.onPaymentNegotiableChanged,
    required this.onRemotePossibleChanged,
  });

  final JobType jobType;
  final bool isPaid;
  final TextEditingController hourlyRateController;
  final bool paymentNegotiable;
  final bool remotePossible;
  final ValueChanged<JobType> onJobTypeChanged;
  final ValueChanged<bool> onIsPaidChanged;
  final ValueChanged<bool> onPaymentNegotiableChanged;
  final ValueChanged<bool> onRemotePossibleChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Job type dropdown
        DropdownButtonFormField<JobType>(
          value: jobType,
          decoration: const InputDecoration(
            labelText: 'Job type',
            border: OutlineInputBorder(),
          ),
          items: JobType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type.displayName),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) onJobTypeChanged(value);
          },
        ),
        SizedBox(height: tokens.spacingMd),

        // Paid/Unpaid toggle
        SwitchListTile(
          value: isPaid,
          onChanged: onIsPaidChanged,
          title: const Text('This is a paid opportunity'),
          contentPadding: EdgeInsets.zero,
        ),

        // Hourly rate (only if paid)
        if (isPaid) ...[
          SizedBox(height: tokens.spacingSm),
          AppTextField(
            controller: hourlyRateController,
            label: 'Hourly rate',
            hint: 'e.g. 15',
            prefixIcon: Icons.currency_pound,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: PostValidators.hourlyRate,
            inputFormatters: [DecimalInputFormatter()],
          ),
          SizedBox(height: tokens.spacingSm),
          CheckboxListTile(
            value: paymentNegotiable,
            onChanged: (value) => onPaymentNegotiableChanged(value ?? false),
            title: const Text('Pay is negotiable'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
        SizedBox(height: tokens.spacingSm),

        // Remote option
        SwitchListTile(
          value: remotePossible,
          onChanged: onRemotePossibleChanged,
          title: const Text('Remote work possible'),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
