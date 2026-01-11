class LostFoundDetails {
  final String id;
  final String postId;
  // Pet info
  final String? petName;
  final String? petType;
  final String? petBreed;
  final String? petColor;
  // Item info
  final String? itemDescription;
  // When/where
  final DateTime? dateLostFound;
  final String? lastSeenLocation;
  // Contact
  final String? contactPhone;
  final bool rewardOffered;
  final double? rewardAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  LostFoundDetails({
    required this.id,
    required this.postId,
    this.petName,
    this.petType,
    this.petBreed,
    this.petColor,
    this.itemDescription,
    this.dateLostFound,
    this.lastSeenLocation,
    this.contactPhone,
    this.rewardOffered = false,
    this.rewardAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LostFoundDetails.fromJson(Map<String, dynamic> json) {
    return LostFoundDetails(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      petName: json['pet_name'] as String?,
      petType: json['pet_type'] as String?,
      petBreed: json['pet_breed'] as String?,
      petColor: json['pet_color'] as String?,
      itemDescription: json['item_description'] as String?,
      dateLostFound: json['date_lost_found'] != null
          ? DateTime.parse(json['date_lost_found'] as String)
          : null,
      lastSeenLocation: json['last_seen_location'] as String?,
      contactPhone: json['contact_phone'] as String?,
      rewardOffered: json['reward_offered'] as bool? ?? false,
      rewardAmount: json['reward_amount'] != null
          ? (json['reward_amount'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Creates from flattened feed view data
  factory LostFoundDetails.fromFeedJson(Map<String, dynamic> json) {
    return LostFoundDetails(
      id: '',
      postId: json['id'] as String,
      petName: json['pet_name'] as String?,
      petType: json['pet_type'] as String?,
      petBreed: null,
      petColor: null,
      itemDescription: null,
      dateLostFound: json['date_lost_found'] != null
          ? DateTime.parse(json['date_lost_found'] as String)
          : null,
      lastSeenLocation: null,
      contactPhone: null,
      rewardOffered: json['reward_offered'] as bool? ?? false,
      rewardAmount: null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'pet_name': petName,
      'pet_type': petType,
      'pet_breed': petBreed,
      'pet_color': petColor,
      'item_description': itemDescription,
      'date_lost_found': dateLostFound?.toIso8601String().split('T')[0],
      'last_seen_location': lastSeenLocation,
      'contact_phone': contactPhone,
      'reward_offered': rewardOffered,
      'reward_amount': rewardAmount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'pet_name': petName,
      'pet_type': petType,
      'pet_breed': petBreed,
      'pet_color': petColor,
      'item_description': itemDescription,
      'date_lost_found': dateLostFound?.toIso8601String().split('T')[0],
      'last_seen_location': lastSeenLocation,
      'contact_phone': contactPhone,
      'reward_offered': rewardOffered,
      'reward_amount': rewardAmount,
    };
  }

  bool get isPet => petName != null || petType != null;

  String get rewardDisplay {
    if (!rewardOffered) return '';
    if (rewardAmount == null) return 'Reward offered';
    return 'Reward: £${rewardAmount!.toStringAsFixed(0)}';
  }

  String get petDescription {
    final parts = <String>[];
    if (petColor != null) parts.add(petColor!);
    if (petBreed != null) parts.add(petBreed!);
    if (petType != null) parts.add(petType!);
    return parts.join(' ');
  }
}
