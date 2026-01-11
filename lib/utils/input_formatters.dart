import 'package:flutter/services.dart';

/// A [TextInputFormatter] that formats input as an invite code in the format XXX-XXX-XXX.
///
/// This formatter:
/// - Auto-inserts dashes at positions 3 and 7 as the user types
/// - Strips non-alphanumeric characters
/// - Converts input to uppercase
/// - Handles paste operations correctly
/// - Maintains cursor at end of formatted text
class InviteCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 1. Strip all non-alphanumeric characters and convert to uppercase
    final cleanedText = newValue.text
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();

    // 2. Limit to 9 characters (the actual code without dashes)
    final truncated = cleanedText.length > 9
        ? cleanedText.substring(0, 9)
        : cleanedText;

    // 3. Insert dashes at positions 3 and 6 (after 3rd and 6th characters)
    final buffer = StringBuffer();
    for (int i = 0; i < truncated.length; i++) {
      if (i == 3 || i == 6) {
        buffer.write('-');
      }
      buffer.write(truncated[i]);
    }
    final formatted = buffer.toString();

    // 4. Position cursor at end of formatted text
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
