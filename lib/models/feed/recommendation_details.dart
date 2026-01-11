class RecommendationDetails {
  final String id;
  final String postId;
  final String? businessName;
  final String? businessCategory;
  final int? rating;
  final String? priceRange;
  final String? location;
  final String? contactInfo;
  final String? website;
  final DateTime createdAt;
  final DateTime updatedAt;

  RecommendationDetails({
    required this.id,
    required this.postId,
    this.businessName,
    this.businessCategory,
    this.rating,
    this.priceRange,
    this.location,
    this.contactInfo,
    this.website,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecommendationDetails.fromJson(Map<String, dynamic> json) {
    return RecommendationDetails(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      businessName: json['business_name'] as String?,
      businessCategory: json['business_category'] as String?,
      rating: json['rating'] as int?,
      priceRange: json['price_range'] as String?,
      location: json['location'] as String?,
      contactInfo: json['contact_info'] as String?,
      website: json['website'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Creates from flattened feed view data
  factory RecommendationDetails.fromFeedJson(Map<String, dynamic> json) {
    return RecommendationDetails(
      id: '',
      postId: json['id'] as String,
      businessName: json['business_name'] as String?,
      businessCategory: json['business_category'] as String?,
      rating: json['rating'] as int?,
      priceRange: json['price_range'] as String?,
      location: json['location'] as String?,
      contactInfo: null,
      website: null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'business_name': businessName,
      'business_category': businessCategory,
      'rating': rating,
      'price_range': priceRange,
      'location': location,
      'contact_info': contactInfo,
      'website': website,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'business_name': businessName,
      'business_category': businessCategory,
      'rating': rating,
      'price_range': priceRange,
      'location': location,
      'contact_info': contactInfo,
      'website': website,
    };
  }

  String get ratingDisplay {
    if (rating == null) return '';
    return '★' * rating! + '☆' * (5 - rating!);
  }

  String get priceRangeDisplay {
    if (priceRange == null) return '';
    switch (priceRange) {
      case 'budget':
        return '£';
      case 'moderate':
        return '££';
      case 'premium':
        return '£££';
      case 'luxury':
        return '££££';
      default:
        return priceRange!;
    }
  }
}
