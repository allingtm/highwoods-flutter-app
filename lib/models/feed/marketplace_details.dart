class MarketplaceDetails {
  final String id;
  final String postId;
  final double? price;
  final bool priceNegotiable;
  final bool isFree;
  final String? condition;
  final bool pickupAvailable;
  final bool deliveryAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  MarketplaceDetails({
    required this.id,
    required this.postId,
    this.price,
    this.priceNegotiable = false,
    this.isFree = false,
    this.condition,
    this.pickupAvailable = true,
    this.deliveryAvailable = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MarketplaceDetails.fromJson(Map<String, dynamic> json) {
    return MarketplaceDetails(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      priceNegotiable: json['price_negotiable'] as bool? ?? false,
      isFree: json['is_free'] as bool? ?? false,
      condition: json['condition'] as String?,
      pickupAvailable: json['pickup_available'] as bool? ?? true,
      deliveryAvailable: json['delivery_available'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Creates from flattened feed view data
  factory MarketplaceDetails.fromFeedJson(Map<String, dynamic> json) {
    return MarketplaceDetails(
      id: '', // Not available in feed view
      postId: json['id'] as String,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      priceNegotiable: json['price_negotiable'] as bool? ?? false,
      isFree: json['is_free'] as bool? ?? false,
      condition: json['condition'] as String?,
      pickupAvailable: json['pickup_available'] as bool? ?? true,
      deliveryAvailable: json['delivery_available'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'price': price,
      'price_negotiable': priceNegotiable,
      'is_free': isFree,
      'condition': condition,
      'pickup_available': pickupAvailable,
      'delivery_available': deliveryAvailable,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// For creating a new marketplace post
  Map<String, dynamic> toInsertJson() {
    return {
      'price': price,
      'price_negotiable': priceNegotiable,
      'is_free': isFree,
      'condition': condition,
      'pickup_available': pickupAvailable,
      'delivery_available': deliveryAvailable,
    };
  }

  String get priceDisplay {
    if (isFree) return 'Free';
    if (price == null) return 'Price on request';
    final priceStr = price!.toStringAsFixed(price! % 1 == 0 ? 0 : 2);
    return priceNegotiable ? '£$priceStr (negotiable)' : '£$priceStr';
  }

  String get conditionDisplay {
    if (condition == null) return '';
    switch (condition) {
      case 'new':
        return 'New';
      case 'like_new':
        return 'Like New';
      case 'good':
        return 'Good';
      case 'fair':
        return 'Fair';
      case 'poor':
        return 'Poor';
      default:
        return condition!;
    }
  }

  MarketplaceDetails copyWith({
    String? id,
    String? postId,
    double? price,
    bool? priceNegotiable,
    bool? isFree,
    String? condition,
    bool? pickupAvailable,
    bool? deliveryAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MarketplaceDetails(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      price: price ?? this.price,
      priceNegotiable: priceNegotiable ?? this.priceNegotiable,
      isFree: isFree ?? this.isFree,
      condition: condition ?? this.condition,
      pickupAvailable: pickupAvailable ?? this.pickupAvailable,
      deliveryAvailable: deliveryAvailable ?? this.deliveryAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
