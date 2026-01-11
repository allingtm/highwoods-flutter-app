import 'package:supabase_flutter/supabase_flutter.dart';

/// Converts error objects to user-friendly messages.
///
/// This utility centralizes error message handling to:
/// - Provide consistent, friendly messages throughout the app
/// - Hide technical details from users
/// - Make internationalization easier in the future
String getErrorMessage(Object error) {
  // Handle Supabase Auth exceptions
  if (error is AuthException) {
    return _getAuthErrorMessage(error);
  }

  // Handle Supabase Postgrest exceptions
  if (error is PostgrestException) {
    return _getPostgrestErrorMessage(error);
  }

  // Handle standard exceptions
  if (error is Exception) {
    final message = error.toString().toLowerCase();

    // Network errors
    if (message.contains('socketexception') ||
        message.contains('network') ||
        message.contains('connection refused') ||
        message.contains('no internet')) {
      return 'Unable to connect. Please check your internet connection.';
    }

    // Timeout errors
    if (message.contains('timeout') || message.contains('timed out')) {
      return 'The request timed out. Please try again.';
    }

    // Generic exception - clean up the message
    final cleanMessage = error.toString().replaceAll('Exception: ', '');
    if (cleanMessage.length < 100) {
      return cleanMessage;
    }
  }

  return 'Something went wrong. Please try again.';
}

/// Converts Supabase Auth exceptions to user-friendly messages.
String _getAuthErrorMessage(AuthException error) {
  final message = error.message.toLowerCase();

  // Invalid credentials
  if (message.contains('invalid login credentials') ||
      message.contains('invalid email or password')) {
    return 'Invalid email or password.';
  }

  // Email not confirmed
  if (message.contains('email not confirmed')) {
    return 'Please confirm your email address first.';
  }

  // User already registered
  if (message.contains('user already registered') ||
      message.contains('email already in use')) {
    return 'This email is already registered.';
  }

  // Invalid OTP/Token
  if (message.contains('invalid otp') ||
      message.contains('token has expired') ||
      message.contains('invalid token')) {
    return 'The verification code is invalid or has expired.';
  }

  // Rate limiting
  if (message.contains('rate limit') ||
      message.contains('too many requests')) {
    return 'Too many attempts. Please wait a moment and try again.';
  }

  // Email rate limiting
  if (message.contains('email rate limit')) {
    return 'Too many emails sent. Please wait before requesting another.';
  }

  // Weak password
  if (message.contains('weak password') ||
      message.contains('password should be')) {
    return 'Password is too weak. Please use a stronger password.';
  }

  // Session expired
  if (message.contains('session expired') ||
      message.contains('refresh token')) {
    return 'Your session has expired. Please sign in again.';
  }

  // Network/Connection issues
  if (message.contains('network') ||
      message.contains('connection')) {
    return 'Unable to connect. Please check your internet connection.';
  }

  // Default auth error
  return 'Authentication failed. Please try again.';
}

/// Converts Supabase Postgrest exceptions to user-friendly messages.
String _getPostgrestErrorMessage(PostgrestException error) {
  final code = error.code ?? '';
  final message = error.message.toLowerCase();

  // Unique constraint violation
  if (code == '23505' || message.contains('duplicate key') || message.contains('already exists')) {
    if (message.contains('username')) {
      return 'This username is already taken.';
    }
    if (message.contains('email')) {
      return 'This email is already registered.';
    }
    return 'This value is already in use.';
  }

  // Foreign key violation
  if (code == '23503') {
    return 'Cannot complete this action. Related data is missing.';
  }

  // Not null violation
  if (code == '23502') {
    return 'Required information is missing.';
  }

  // Check constraint violation
  if (code == '23514') {
    // Post body length
    if (message.contains('posts_body_check')) {
      return 'Post content must be between 10 and 2000 characters.';
    }
    // Price range
    if (message.contains('marketplace_price_range')) {
      return 'Price must be between 0 and 999,999.99.';
    }
    // Max attendees range
    if (message.contains('event_max_attendees_range')) {
      return 'Max attendees must be between 1 and 10,000.';
    }
    // Hourly rate range
    if (message.contains('job_hourly_rate_range')) {
      return 'Hourly rate must be between 0 and 9,999.99.';
    }
    // Reward amount range
    if (message.contains('lost_found_reward_range')) {
      return 'Reward amount must be between 0 and 99,999.99.';
    }
    // Title length
    if (message.contains('posts_title_check')) {
      return 'Title cannot exceed 150 characters.';
    }
    // Location length
    if (message.contains('posts_location_text_check')) {
      return 'Location cannot exceed 100 characters.';
    }
    // Venue name length
    if (message.contains('event_details_venue_name_check')) {
      return 'Venue name cannot exceed 100 characters.';
    }
    // Address length
    if (message.contains('event_details_address_check')) {
      return 'Address cannot exceed 200 characters.';
    }
    // Event date not in past
    if (message.contains('event_date_not_past')) {
      return 'Event date cannot be in the past.';
    }
    // Event end time after start time
    if (message.contains('event_end_after_start')) {
      return 'End time must be after start time.';
    }
    // Lost/found date not in future
    if (message.contains('lost_found_date_not_future')) {
      return 'Lost/found date cannot be in the future.';
    }
    // Generic field length violations
    if (message.contains('char_length')) {
      return 'One or more fields exceed the maximum length.';
    }
    return 'The provided data is invalid.';
  }

  // Row not found
  if (code == 'PGRST116' || message.contains('no rows')) {
    return 'The requested item was not found.';
  }

  // Permission denied
  if (code == '42501' || message.contains('permission denied')) {
    return 'You do not have permission to perform this action.';
  }

  // Default database error
  return 'An error occurred while processing your request.';
}
