import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/promo.dart';
import '../models/testimonial.dart';

/// Repository for promos and testimonials (read-only for promos, users can submit testimonials)
class DirectoryRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Gets the current user's ID
  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // ============================================================
  // Promos (Read-only - managed by admins)
  // ============================================================

  /// Gets all active promos with optional filtering
  Future<List<Promo>> getPromos({
    PromoCategory? category,
    bool? featuredOnly,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from('promos')
          .select('''
            *,
            owner:owner_id (
              id, email, username, first_name, last_name, avatar_url, bio, role, created_at, updated_at
            )
          ''')
          .eq('is_active', true);

      if (category != null) {
        query = query.eq('category', category.name);
      }

      if (featuredOnly == true) {
        query = query.eq('is_featured', true);
      }

      final response = await query
          .order('is_featured', ascending: false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List<dynamic>)
          .map((json) => Promo.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch promos: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch promos: $e');
    }
  }

  /// Gets a single promo by ID with testimonial stats
  Future<Promo> getPromo(String promoId) async {
    try {
      final response = await _supabase
          .from('promos')
          .select('''
            *,
            owner:owner_id (
              id, email, username, first_name, last_name, avatar_url, bio, role, created_at, updated_at
            )
          ''')
          .eq('id', promoId)
          .single();

      // Get testimonial stats separately
      final statsResponse = await _supabase
          .from('testimonials')
          .select('rating')
          .eq('promo_id', promoId)
          .eq('status', 'approved');

      final stats = statsResponse as List<dynamic>;
      double? avgRating;
      int? count;

      if (stats.isNotEmpty) {
        count = stats.length;
        final sum = stats.fold<int>(0, (sum, t) => sum + (t['rating'] as int));
        avgRating = sum / count;
      }

      final promo = Promo.fromJson(response);
      return promo.copyWith(
        averageRating: avgRating,
        testimonialCount: count,
      );
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch promo: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch promo: $e');
    }
  }

  /// Searches promos by title or description
  Future<List<Promo>> searchPromos(String query) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      final response = await _supabase
          .from('promos')
          .select('''
            *,
            owner:owner_id (
              id, email, username, first_name, last_name, avatar_url, bio, role, created_at, updated_at
            )
          ''')
          .eq('is_active', true)
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .order('is_featured', ascending: false)
          .order('created_at', ascending: false)
          .limit(20);

      return (response as List<dynamic>)
          .map((json) => Promo.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to search promos: ${e.message}');
    } catch (e) {
      throw Exception('Failed to search promos: $e');
    }
  }

  // ============================================================
  // Testimonials
  // ============================================================

  /// Gets approved testimonials for a promo
  Future<List<Testimonial>> getTestimonials(String promoId) async {
    try {
      final response = await _supabase
          .from('testimonials')
          .select('''
            *,
            author:author_id (
              id, email, username, first_name, last_name, avatar_url, bio, role, created_at, updated_at
            )
          ''')
          .eq('promo_id', promoId)
          .eq('status', 'approved')
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => Testimonial.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch testimonials: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch testimonials: $e');
    }
  }

  /// Creates a new testimonial (users can submit reviews)
  Future<Testimonial> createTestimonial({
    required String promoId,
    required int rating,
    required String content,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      final response = await _supabase
          .from('testimonials')
          .insert({
            'promo_id': promoId,
            'author_id': userId,
            'rating': rating,
            'content': content,
          })
          .select()
          .single();

      return Testimonial.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('You have already submitted a review for this listing');
      }
      throw Exception('Failed to create testimonial: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create testimonial: $e');
    }
  }
}
