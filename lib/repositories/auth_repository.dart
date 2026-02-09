import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/biometric_service.dart';
import '../services/notification_service.dart';
import '../services/purchase_service.dart';
import '../services/sentry_service.dart';

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Signs in an existing user with email and password.
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  /// Creates a new user account with email and password.
  Future<AuthResponse> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signUp(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  /// Sends a password reset email to the user.
  Future<void> resetPassword({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'https://app.highwoods.co.uk/auth/confirm',
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to send reset email: $e');
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
    bool? showFollowerCount,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (firstName != null) updates['first_name'] = firstName;
      if (lastName != null) updates['last_name'] = lastName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (bio != null) updates['bio'] = bio;
      if (allowOpenMessaging != null) updates['allow_open_messaging'] = allowOpenMessaging;
      if (showFollowerCount != null) updates['show_follower_count'] = showFollowerCount;

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

  /// Updates the current user's password (used after password recovery).
  Future<void> updatePassword({required String newPassword}) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      // Stored biometric credentials are now invalid
      await BiometricService.disableBiometricLogin();
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }

  Future<void> signOut() async {
    try {
      // Clear notification user data
      await NotificationService.logout();
      // Clear purchase user data
      await PurchaseService.logout();
      // Keep biometric credentials so Face ID / fingerprint login works after
      // sign-out. They're encrypted in secure storage and gated behind biometric
      // auth, so they're safe to retain.
      await _supabase.auth.signOut();
      SentryService.addBreadcrumb('User signed out', category: 'auth');
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
      // Clear biometric login data
      await BiometricService.disableBiometricLogin();

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
