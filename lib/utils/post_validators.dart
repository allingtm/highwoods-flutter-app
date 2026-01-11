import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:form_field_validator/form_field_validator.dart';

/// Field length limits matching database constraints
class PostFieldLimits {
  PostFieldLimits._();

  // Posts table
  static const int bodyMin = 10;
  static const int bodyMax = 2000;
  static const int titleMax = 150;
  static const int locationTextMax = 100;

  // Marketplace
  static const double priceMin = 0;
  static const double priceMax = 999999.99;

  // Events
  static const int venueNameMax = 100;
  static const int addressMax = 200;
  static const int maxAttendeesMin = 1;
  static const int maxAttendeesMax = 10000;

  // Lost & Found
  static const int petFieldMax = 50; // name, type, breed, color
  static const int lastSeenLocationMax = 200;
  static const int contactPhoneMax = 20;
  static const double rewardMin = 0;
  static const double rewardMax = 99999.99;

  // Jobs
  static const double hourlyRateMin = 0;
  static const double hourlyRateMax = 9999.99;

  // Comments
  static const int commentBodyMax = 1000;
}

/// Text sanitization utilities
class PostSanitizers {
  PostSanitizers._();

  // Collapse multiple whitespace to single space
  static final _multipleSpaces = RegExp(r'\s{2,}');

  // Block more than 3 consecutive special chars
  static final _consecutiveSpecialChars =
      RegExp(r'([!@#$%^&*(),.?":{}|<>])\1{3,}');

  /// Sanitize text by trimming, collapsing whitespace, and limiting special chars
  static String sanitizeText(String input) {
    return input
        .trim()
        .replaceAll(_multipleSpaces, ' ')
        .replaceAllMapped(
          _consecutiveSpecialChars,
          (match) => match.group(1)! * 3,
        );
  }

  /// Sanitize nullable text, returning null for empty strings
  static String? sanitizeNullable(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    return sanitizeText(input);
  }
}

/// Input formatter that sanitizes text in real-time as user types
class SanitizingTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Collapse multiple spaces as user types
    final sanitized = newValue.text.replaceAll(RegExp(r'  +'), ' ');
    if (sanitized == newValue.text) return newValue;

    // Adjust cursor position
    final cursorOffset = newValue.selection.baseOffset -
        (newValue.text.length - sanitized.length);

    return newValue.copyWith(
      text: sanitized,
      selection: TextSelection.collapsed(
        offset: cursorOffset.clamp(0, sanitized.length),
      ),
    );
  }
}

/// Input formatter for decimal numbers with optional max decimal places
class DecimalInputFormatter extends TextInputFormatter {
  DecimalInputFormatter({this.decimalPlaces = 2});

  final int decimalPlaces;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow empty
    if (newValue.text.isEmpty) return newValue;

    // Build regex pattern for valid decimal
    final pattern = RegExp(r'^\d*\.?\d{0,' + decimalPlaces.toString() + r'}$');

    if (pattern.hasMatch(newValue.text)) {
      return newValue;
    }

    // Invalid input, return old value
    return oldValue;
  }
}

/// Validators for post fields using form_field_validator package
class PostValidators {
  PostValidators._();

  /// Validator for post body (required, 10-2000 chars)
  static MultiValidator body() => MultiValidator([
        RequiredValidator(errorText: 'Please enter your post content'),
        MinLengthValidator(
          PostFieldLimits.bodyMin,
          errorText:
              'Post must be at least ${PostFieldLimits.bodyMin} characters',
        ),
        MaxLengthValidator(
          PostFieldLimits.bodyMax,
          errorText:
              'Post cannot exceed ${PostFieldLimits.bodyMax} characters',
        ),
      ]);

  /// Validator for post title (optional, max 150 chars)
  static String? title(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length > PostFieldLimits.titleMax) {
      return 'Title cannot exceed ${PostFieldLimits.titleMax} characters';
    }
    return null;
  }

  /// Validator for location text (optional, max 100 chars)
  static String? locationText(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length > PostFieldLimits.locationTextMax) {
      return 'Location cannot exceed ${PostFieldLimits.locationTextMax} characters';
    }
    return null;
  }

  /// Validator for price (numeric range 0-999999.99)
  static String? price(String? value) {
    if (value == null || value.isEmpty) return null;
    final parsed = double.tryParse(value);
    if (parsed == null) return 'Please enter a valid price';
    if (parsed < PostFieldLimits.priceMin) return 'Price cannot be negative';
    if (parsed > PostFieldLimits.priceMax) {
      return 'Price cannot exceed ${_formatCurrency(PostFieldLimits.priceMax)}';
    }
    return null;
  }

  /// Validator for venue name (optional, max 100 chars)
  static String? venueName(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length > PostFieldLimits.venueNameMax) {
      return 'Venue name cannot exceed ${PostFieldLimits.venueNameMax} characters';
    }
    return null;
  }

  /// Validator for address (optional, max 200 chars)
  static String? address(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length > PostFieldLimits.addressMax) {
      return 'Address cannot exceed ${PostFieldLimits.addressMax} characters';
    }
    return null;
  }

  /// Validator for max attendees (integer 1-10000)
  static String? maxAttendees(String? value) {
    if (value == null || value.isEmpty) return null;
    final parsed = int.tryParse(value);
    if (parsed == null) return 'Please enter a valid number';
    if (parsed < PostFieldLimits.maxAttendeesMin) return 'Must be at least 1';
    if (parsed > PostFieldLimits.maxAttendeesMax) {
      return 'Cannot exceed ${PostFieldLimits.maxAttendeesMax}';
    }
    return null;
  }

  /// Validator for pet fields (optional, max 50 chars)
  static String? petField(String? value, String fieldName) {
    if (value == null || value.isEmpty) return null;
    if (value.length > PostFieldLimits.petFieldMax) {
      return '$fieldName cannot exceed ${PostFieldLimits.petFieldMax} characters';
    }
    return null;
  }

  /// Validator for last seen location (optional, max 200 chars)
  static String? lastSeenLocation(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length > PostFieldLimits.lastSeenLocationMax) {
      return 'Location cannot exceed ${PostFieldLimits.lastSeenLocationMax} characters';
    }
    return null;
  }

  /// Validator for phone number (optional, max 20 chars, phone format)
  static String? phone(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length > PostFieldLimits.contactPhoneMax) {
      return 'Phone number is too long';
    }
    // Allow digits, spaces, +, -, (, )
    if (!RegExp(r'^[\d\s+\-()]+$').hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Validator for reward amount (numeric range 0-99999.99)
  static String? rewardAmount(String? value) {
    if (value == null || value.isEmpty) return null;
    final parsed = double.tryParse(value);
    if (parsed == null) return 'Please enter a valid amount';
    if (parsed < PostFieldLimits.rewardMin) return 'Amount cannot be negative';
    if (parsed > PostFieldLimits.rewardMax) {
      return 'Amount cannot exceed ${_formatCurrency(PostFieldLimits.rewardMax)}';
    }
    return null;
  }

  /// Validator for hourly rate (numeric range 0-9999.99)
  static String? hourlyRate(String? value) {
    if (value == null || value.isEmpty) return null;
    final parsed = double.tryParse(value);
    if (parsed == null) return 'Please enter a valid rate';
    if (parsed < PostFieldLimits.hourlyRateMin) return 'Rate cannot be negative';
    if (parsed > PostFieldLimits.hourlyRateMax) {
      return 'Rate cannot exceed ${_formatCurrency(PostFieldLimits.hourlyRateMax)}';
    }
    return null;
  }

  /// Generic validator for optional text fields with max length
  static String? optionalText(String? value, int maxLength, String fieldName) {
    if (value == null || value.isEmpty) return null;
    if (value.length > maxLength) {
      return '$fieldName cannot exceed $maxLength characters';
    }
    return null;
  }

  /// Helper to format currency values for error messages
  static String _formatCurrency(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  // ============================================
  // Business Logic Validators (Dates/Times)
  // ============================================

  /// Validates that end time is after start time
  static String? eventTimes(TimeOfDay? startTime, TimeOfDay? endTime) {
    if (startTime == null || endTime == null) return null;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    if (endMinutes <= startMinutes) {
      return 'End time must be after start time';
    }
    return null;
  }

  /// Validates event is not in the past (date + time combination)
  static String? eventNotInPast(DateTime? eventDate, TimeOfDay? startTime) {
    if (eventDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);

    // If event is today and start time provided, check it's not in the past
    if (eventDay.isAtSameMomentAs(today) && startTime != null) {
      final eventDateTime = DateTime(
        eventDate.year,
        eventDate.month,
        eventDate.day,
        startTime.hour,
        startTime.minute,
      );
      if (eventDateTime.isBefore(now)) {
        return 'Event start time cannot be in the past';
      }
    }
    return null;
  }

  /// Validates lost/found date is not in the future
  static String? lostFoundDateNotFuture(DateTime? date) {
    if (date == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly.isAfter(today)) {
      return 'Date cannot be in the future';
    }
    return null;
  }
}
