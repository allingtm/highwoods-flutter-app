import 'package:flutter/material.dart';

import 'user_profile.dart';

/// Promo categories for directory listings
enum PromoCategory {
  service,
  event,
  organisation,
  product;

  static PromoCategory fromString(String value) {
    return PromoCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PromoCategory.service,
    );
  }

  String get displayName {
    switch (this) {
      case PromoCategory.service:
        return 'Service';
      case PromoCategory.event:
        return 'Event';
      case PromoCategory.organisation:
        return 'Organisation';
      case PromoCategory.product:
        return 'Product';
    }
  }

  IconData get icon {
    switch (this) {
      case PromoCategory.service:
        return Icons.build_outlined;
      case PromoCategory.event:
        return Icons.event_outlined;
      case PromoCategory.organisation:
        return Icons.groups_outlined;
      case PromoCategory.product:
        return Icons.shopping_bag_outlined;
    }
  }
}

/// Contact information for a promo
class PromoContactInfo {
  final String? phone;
  final String? email;
  final String? website;
  final String? address;

  PromoContactInfo({
    this.phone,
    this.email,
    this.website,
    this.address,
  });

  factory PromoContactInfo.fromJson(Map<String, dynamic> json) {
    return PromoContactInfo(
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (website != null) 'website': website,
      if (address != null) 'address': address,
    };
  }

  bool get isEmpty =>
      phone == null && email == null && website == null && address == null;

  bool get isNotEmpty => !isEmpty;
}

/// Represents a promo/listing in the directory
class Promo {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final PromoCategory category;
  final List<String> images;
  final String? videoUrl;
  final String? externalLink;
  final PromoContactInfo contactInfo;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool isActive;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Optional: populated when fetching with owner data
  final UserProfile? owner;

  /// Optional: populated when fetching with testimonial stats
  final double? averageRating;
  final int? testimonialCount;

  Promo({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.category,
    this.images = const [],
    this.videoUrl,
    this.externalLink,
    required this.contactInfo,
    this.startsAt,
    this.endsAt,
    this.isActive = true,
    this.isFeatured = false,
    required this.createdAt,
    required this.updatedAt,
    this.owner,
    this.averageRating,
    this.testimonialCount,
  });

  factory Promo.fromJson(Map<String, dynamic> json) {
    return Promo(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: PromoCategory.fromString(json['category'] as String),
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      videoUrl: json['video_url'] as String?,
      externalLink: json['external_link'] as String?,
      contactInfo: json['contact_info'] != null
          ? PromoContactInfo.fromJson(json['contact_info'] as Map<String, dynamic>)
          : PromoContactInfo(),
      startsAt: json['starts_at'] != null
          ? DateTime.parse(json['starts_at'] as String)
          : null,
      endsAt: json['ends_at'] != null
          ? DateTime.parse(json['ends_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      owner: json['owner'] != null
          ? UserProfile.fromJson(json['owner'] as Map<String, dynamic>)
          : null,
      averageRating: json['average_rating'] != null
          ? (json['average_rating'] as num).toDouble()
          : null,
      testimonialCount: json['testimonial_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'title': title,
      'description': description,
      'category': category.name,
      'images': images,
      if (videoUrl != null) 'video_url': videoUrl,
      if (externalLink != null) 'external_link': externalLink,
      'contact_info': contactInfo.toJson(),
      if (startsAt != null) 'starts_at': startsAt!.toIso8601String(),
      if (endsAt != null) 'ends_at': endsAt!.toIso8601String(),
      'is_active': isActive,
      'is_featured': isFeatured,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Promo copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? description,
    PromoCategory? category,
    List<String>? images,
    String? videoUrl,
    String? externalLink,
    PromoContactInfo? contactInfo,
    DateTime? startsAt,
    DateTime? endsAt,
    bool? isActive,
    bool? isFeatured,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserProfile? owner,
    double? averageRating,
    int? testimonialCount,
  }) {
    return Promo(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      images: images ?? this.images,
      videoUrl: videoUrl ?? this.videoUrl,
      externalLink: externalLink ?? this.externalLink,
      contactInfo: contactInfo ?? this.contactInfo,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      owner: owner ?? this.owner,
      averageRating: averageRating ?? this.averageRating,
      testimonialCount: testimonialCount ?? this.testimonialCount,
    );
  }

  /// Check if promo has a time-limited availability
  bool get hasDateRange => startsAt != null || endsAt != null;

  /// Check if promo is currently within its date range
  bool get isCurrentlyAvailable {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startsAt != null && now.isBefore(startsAt!)) return false;
    if (endsAt != null && now.isAfter(endsAt!)) return false;
    return true;
  }

  /// Get display string for rating
  String get ratingDisplay {
    if (averageRating == null) return 'No ratings yet';
    return '${averageRating!.toStringAsFixed(1)} (${testimonialCount ?? 0})';
  }
}
