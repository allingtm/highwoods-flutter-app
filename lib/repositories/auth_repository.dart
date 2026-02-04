import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/notification_service.dart';
import '../services/purchase_service.dart';

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Sends a magic link for registration (allows creating new users).
  Future<void> sendOTP({
    required String email,
    String? username,
    String? firstName,
    String? lastName,
  }) async {
    try {
      // Build redirect URL with optional profile parameters
      var redirectUrl = 'https://app.highwoods.co.uk/auth/magic-link';
      if (username != null && firstName != null && lastName != null) {
        final params = Uri(queryParameters: {
          'username': username,
          'firstName': firstName,
          'lastName': lastName,
        }).query;
        redirectUrl = '$redirectUrl?$params';
      }

      await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: redirectUrl,
      );
    } on AuthException catch (e) {
      throw Exception('Failed to send OTP: ${e.message}');
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  /// Sends a magic link for login only (does not create new users).
  Future<void> sendLoginOTP({required String email}) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'https://app.highwoods.co.uk/auth/magic-link',
        shouldCreateUser: false,
      );
    } on AuthException catch (e) {
      throw Exception('Failed to send OTP: ${e.message}');
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  Future<AuthResponse> verifyOTP({
    required String email,
    required String token,
  }) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );
      return response;
    } on AuthException catch (e) {
      throw Exception('Failed to verify OTP: ${e.message}');
    } catch (e) {
      throw Exception('Failed to verify OTP: $e');
    }
  }

  Future<bool> isUsernameAvailable(String username) async {
    try {
      // Call RPC function with SECURITY DEFINER to safely check username
      // without requiring authentication or bypassing RLS
      final response = await _supabase.rpc(
        'check_username_available',
        params: {'username': username.toLowerCase()},
      );

      return response as bool;
    } on PostgrestException catch (e) {
      throw Exception('Failed to check username: ${e.message}');
    } catch (e) {
      throw Exception('Failed to check username: $e');
    }
  }

  Future<void> createUserProfile({
    required String userId,
    required String email,
    required String username,
    String? firstName,
    String? lastName,
  }) async {
    try {
      await _supabase.from('profiles').insert({
        'id': userId,
        'email': email,
        'username': username.toLowerCase(),
        'first_name': firstName,
        'last_name': lastName,
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to create profile: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create profile: $e');
    }
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return UserProfile.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return null;
      }
      throw Exception('Failed to get profile: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }

  Future<void> updateUserProfile({
    required String userId,
    String? username,
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? bio,
    bool? allowOpenMessaging,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (firstName != null) updates['first_name'] = firstName;
      if (lastName != null) updates['last_name'] = lastName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (bio != null) updates['bio'] = bio;
      if (allowOpenMessaging != null) updates['allow_open_messaging'] = allowOpenMessaging;

      if (updates.isNotEmpty) {
        await _supabase
            .from('profiles')
            .update(updates)
            .eq('id', userId);
      }
    } on PostgrestException catch (e) {
      throw Exception('Failed to update profile: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> signOut() async {
    try {
      // Clear notification user data
      await NotificationService.logout();
      // Clear purchase user data
      await PurchaseService.logout();
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      throw Exception('Failed to sign out: ${e.message}');
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  /// Permanently deletes the user's account and all associated data.
  /// This action cannot be undone.
  Future<void> deleteAccount() async {
    final userId = currentUser?.id;
    if (userId == null) {
      throw Exception('Not authenticated');
    }

    try {
      // Call RPC function to delete all user data
      await _supabase.rpc(
        'delete_user_account',
        params: {'target_user_id': userId},
      );

      // Clear notification user data
      await NotificationService.logout();
      // Clear purchase user data
      await PurchaseService.logout();

      // Sign out to clear local session
      await _supabase.auth.signOut();
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete account: ${e.message}');
    } on AuthException catch (e) {
      throw Exception('Failed to delete account: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  bool get isAuthenticated => currentUser != null;
}
