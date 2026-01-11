import 'user_profile.dart';

/// Status of a testimonial
enum TestimonialStatus {
  pending,
  approved,
  rejected;

  static TestimonialStatus fromString(String value) {
    return TestimonialStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TestimonialStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case TestimonialStatus.pending:
        return 'Pending Review';
      case TestimonialStatus.approved:
        return 'Approved';
      case TestimonialStatus.rejected:
        return 'Rejected';
    }
  }
}

/// Represents a testimonial/review for a promo
class Testimonial {
  final String id;
  final String promoId;
  final String authorId;
  final int rating;
  final String content;
  final TestimonialStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  /// Optional: populated when fetching with author data
  final UserProfile? author;

  Testimonial({
    required this.id,
    required this.promoId,
    required this.authorId,
    required this.rating,
    required this.content,
    this.status = TestimonialStatus.pending,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.author,
  });

  factory Testimonial.fromJson(Map<String, dynamic> json) {
    return Testimonial(
      id: json['id'] as String,
      promoId: json['promo_id'] as String,
      authorId: json['author_id'] as String,
      rating: json['rating'] as int,
      content: json['content'] as String,
      status: TestimonialStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      reviewedBy: json['reviewed_by'] as String?,
      author: json['author'] != null
          ? UserProfile.fromJson(json['author'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'promo_id': promoId,
      'author_id': authorId,
      'rating': rating,
      'content': content,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      if (reviewedAt != null) 'reviewed_at': reviewedAt!.toIso8601String(),
      if (reviewedBy != null) 'reviewed_by': reviewedBy,
    };
  }

  /// Create payload for insert (excludes server-generated fields)
  Map<String, dynamic> toInsertJson() {
    return {
      'promo_id': promoId,
      'author_id': authorId,
      'rating': rating,
      'content': content,
    };
  }

  Testimonial copyWith({
    String? id,
    String? promoId,
    String? authorId,
    int? rating,
    String? content,
    TestimonialStatus? status,
    DateTime? createdAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    UserProfile? author,
  }) {
    return Testimonial(
      id: id ?? this.id,
      promoId: promoId ?? this.promoId,
      authorId: authorId ?? this.authorId,
      rating: rating ?? this.rating,
      content: content ?? this.content,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      author: author ?? this.author,
    );
  }

  /// Check if testimonial is approved and visible
  bool get isApproved => status == TestimonialStatus.approved;

  /// Check if testimonial is pending moderation
  bool get isPending => status == TestimonialStatus.pending;

  /// Check if testimonial was rejected
  bool get isRejected => status == TestimonialStatus.rejected;

  /// Get stars display (e.g., "★★★★☆")
  String get starsDisplay {
    return '★' * rating + '☆' * (5 - rating);
  }
}
