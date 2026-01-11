import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/promo.dart';
import '../models/testimonial.dart';
import '../repositories/directory_repository.dart';

// ============================================================
// Repository Provider
// ============================================================

final directoryRepositoryProvider = Provider<DirectoryRepository>((ref) {
  return DirectoryRepository();
});

// ============================================================
// Promos Providers (Read-only - admin managed)
// ============================================================

/// State for promos list with filtering
class PromosState {
  final List<Promo> promos;
  final PromoCategory? selectedCategory;
  final bool featuredOnly;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int offset;

  const PromosState({
    this.promos = const [],
    this.selectedCategory,
    this.featuredOnly = false,
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.offset = 0,
  });

  PromosState copyWith({
    List<Promo>? promos,
    PromoCategory? selectedCategory,
    bool? featuredOnly,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? offset,
    bool clearCategory = false,
  }) {
    return PromosState(
      promos: promos ?? this.promos,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      featuredOnly: featuredOnly ?? this.featuredOnly,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
    );
  }
}

/// Provider for browsing all active promos
class PromosNotifier extends StateNotifier<PromosState> {
  PromosNotifier(this._repository) : super(const PromosState()) {
    load();
  }

  final DirectoryRepository _repository;
  static const _pageSize = 20;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null, offset: 0);
    try {
      final promos = await _repository.getPromos(
        category: state.selectedCategory,
        featuredOnly: state.featuredOnly ? true : null,
        limit: _pageSize,
        offset: 0,
      );
      state = state.copyWith(
        promos: promos,
        isLoading: false,
        hasMore: promos.length >= _pageSize,
        offset: promos.length,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    try {
      final promos = await _repository.getPromos(
        category: state.selectedCategory,
        featuredOnly: state.featuredOnly ? true : null,
        limit: _pageSize,
        offset: state.offset,
      );
      state = state.copyWith(
        promos: [...state.promos, ...promos],
        isLoading: false,
        hasMore: promos.length >= _pageSize,
        offset: state.offset + promos.length,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    await load();
  }

  void setCategory(PromoCategory? category) {
    if (category == state.selectedCategory) return;
    state = state.copyWith(
      selectedCategory: category,
      clearCategory: category == null,
    );
    load();
  }

  void setFeaturedOnly(bool featuredOnly) {
    if (featuredOnly == state.featuredOnly) return;
    state = state.copyWith(featuredOnly: featuredOnly);
    load();
  }
}

final promosProvider = StateNotifierProvider<PromosNotifier, PromosState>((ref) {
  final repository = ref.watch(directoryRepositoryProvider);
  return PromosNotifier(repository);
});

/// Provider for a single promo with full details
final promoDetailProvider = FutureProvider.family<Promo, String>(
  (ref, promoId) async {
    final repository = ref.watch(directoryRepositoryProvider);
    return repository.getPromo(promoId);
  },
);

/// Provider for promo search
final promoSearchProvider = FutureProvider.family<List<Promo>, String>(
  (ref, query) async {
    final repository = ref.watch(directoryRepositoryProvider);
    return repository.searchPromos(query);
  },
);

// ============================================================
// Testimonials Providers
// ============================================================

/// Provider for approved testimonials of a promo
final testimonialsByPromoProvider = FutureProvider.family<List<Testimonial>, String>(
  (ref, promoId) async {
    final repository = ref.watch(directoryRepositoryProvider);
    return repository.getTestimonials(promoId);
  },
);

// ============================================================
// Testimonial Actions (Users can submit reviews)
// ============================================================

/// Create a new testimonial
Future<Testimonial> createTestimonial(
  WidgetRef ref, {
  required String promoId,
  required int rating,
  required String content,
}) async {
  final repository = ref.read(directoryRepositoryProvider);
  final testimonial = await repository.createTestimonial(
    promoId: promoId,
    rating: rating,
    content: content,
  );

  // Invalidate the testimonials cache for this promo so it refreshes
  ref.invalidate(testimonialsByPromoProvider(promoId));

  return testimonial;
}
