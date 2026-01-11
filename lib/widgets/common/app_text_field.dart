import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.showCounter = false,
    this.warningThreshold,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;
  final int maxLines;

  /// Maximum character length for the field
  final int? maxLength;

  /// Whether to show the character counter
  final bool showCounter;

  /// Number of remaining characters at which to show warning color
  final int? warningThreshold;

  /// Input formatters for text sanitization
  final List<TextInputFormatter>? inputFormatters;

  /// Factory constructor for email fields
  factory AppTextField.email({
    Key? key,
    required TextEditingController controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return AppTextField(
      key: key,
      controller: controller,
      label: 'Email',
      hint: 'your.email@example.com',
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: validator,
      onChanged: onChanged,
    );
  }

  /// Factory constructor for password fields
  factory AppTextField.password({
    Key? key,
    required TextEditingController controller,
    String label = 'Password',
    String? hint,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    Widget? suffixIcon,
    bool obscureText = true,
  }) {
    return AppTextField(
      key: key,
      controller: controller,
      label: label,
      hint: hint,
      prefixIcon: Icons.lock_outlined,
      suffixIcon: suffixIcon,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
    );
  }

  /// Factory constructor for username fields
  factory AppTextField.username({
    Key? key,
    required TextEditingController controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return AppTextField(
      key: key,
      controller: controller,
      label: 'Username',
      hint: 'johndoe',
      prefixIcon: Icons.person_outlined,
      validator: validator,
      onChanged: onChanged,
    );
  }

  /// Factory constructor for name fields
  factory AppTextField.name({
    Key? key,
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return AppTextField(
      key: key,
      controller: controller,
      label: label,
      hint: hint,
      prefixIcon: Icons.badge_outlined,
      textCapitalization: TextCapitalization.words,
      validator: validator,
      onChanged: onChanged,
    );
  }

  /// Factory constructor for post content fields with character counter
  factory AppTextField.postContent({
    Key? key,
    required TextEditingController controller,
    String label = 'What would you like to share?',
    String hint = 'Write your post here...',
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    int maxLength = 2000,
    int warningThreshold = 100,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return AppTextField(
      key: key,
      controller: controller,
      label: label,
      hint: hint,
      maxLines: 5,
      maxLength: maxLength,
      showCounter: true,
      warningThreshold: warningThreshold,
      textCapitalization: TextCapitalization.sentences,
      validator: validator,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
    );
  }

  /// Custom counter builder for character limit display
  Widget? _buildCounter(
    BuildContext context, {
    required int currentLength,
    required int? maxLength,
    required bool isFocused,
  }) {
    if (maxLength == null || !showCounter) return const SizedBox.shrink();

    final remaining = maxLength - currentLength;
    final isWarning =
        warningThreshold != null && remaining <= warningThreshold! && remaining >= 0;
    final isError = remaining < 0;

    Color counterColor;
    if (isError) {
      counterColor = Theme.of(context).colorScheme.error;
    } else if (isWarning) {
      counterColor = AppColors.warning;
    } else {
      counterColor = Theme.of(context).colorScheme.onSurfaceVariant;
    }

    return Text(
      '$currentLength / $maxLength',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: counterColor,
            fontWeight: isWarning || isError ? FontWeight.w600 : null,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMultiLine = maxLines > 1;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      maxLines: maxLines,
      maxLength: showCounter ? maxLength : null,
      inputFormatters: inputFormatters,
      buildCounter: showCounter ? _buildCounter : null,
      textAlignVertical: isMultiLine ? TextAlignVertical.top : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: isMultiLine,
        prefixIcon: prefixIcon != null
            ? Padding(
                padding: EdgeInsets.only(bottom: isMultiLine ? 60 : 0),
                child: Icon(prefixIcon),
              )
            : null,
        suffixIcon: suffixIcon,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
