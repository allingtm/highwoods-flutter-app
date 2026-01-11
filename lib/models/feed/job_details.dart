enum JobType {
  oneTime,
  recurring,
  partTime,
  fullTime;

  String get displayName {
    switch (this) {
      case JobType.oneTime:
        return 'One-time';
      case JobType.recurring:
        return 'Recurring';
      case JobType.partTime:
        return 'Part-time';
      case JobType.fullTime:
        return 'Full-time';
    }
  }

  String get dbValue {
    switch (this) {
      case JobType.oneTime:
        return 'one_time';
      case JobType.recurring:
        return 'recurring';
      case JobType.partTime:
        return 'part_time';
      case JobType.fullTime:
        return 'full_time';
    }
  }

  static JobType fromString(String value) {
    switch (value) {
      case 'one_time':
        return JobType.oneTime;
      case 'recurring':
        return JobType.recurring;
      case 'part_time':
        return JobType.partTime;
      case 'full_time':
        return JobType.fullTime;
      default:
        return JobType.oneTime;
    }
  }
}

enum ExperienceLevel {
  any,
  beginner,
  intermediate,
  expert;

  String get displayName {
    switch (this) {
      case ExperienceLevel.any:
        return 'Any level';
      case ExperienceLevel.beginner:
        return 'Beginner';
      case ExperienceLevel.intermediate:
        return 'Intermediate';
      case ExperienceLevel.expert:
        return 'Expert';
    }
  }

  String get dbValue => name;

  static ExperienceLevel fromString(String? value) {
    switch (value) {
      case 'beginner':
        return ExperienceLevel.beginner;
      case 'intermediate':
        return ExperienceLevel.intermediate;
      case 'expert':
        return ExperienceLevel.expert;
      default:
        return ExperienceLevel.any;
    }
  }
}

class JobDetails {
  final String id;
  final String postId;
  final JobType jobType;
  final double? hourlyRate;
  final double? fixedPrice;
  final bool isPaid;
  final bool paymentNegotiable;
  final List<String>? skillsRequired;
  final ExperienceLevel experienceLevel;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final List<String>? availableDays;
  final int? hoursPerWeek;
  final bool remotePossible;
  final DateTime createdAt;
  final DateTime updatedAt;

  JobDetails({
    required this.id,
    required this.postId,
    this.jobType = JobType.oneTime,
    this.hourlyRate,
    this.fixedPrice,
    this.isPaid = true,
    this.paymentNegotiable = false,
    this.skillsRequired,
    this.experienceLevel = ExperienceLevel.any,
    this.availableFrom,
    this.availableUntil,
    this.availableDays,
    this.hoursPerWeek,
    this.remotePossible = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JobDetails.fromJson(Map<String, dynamic> json) {
    return JobDetails(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      jobType: JobType.fromString(json['job_type'] as String? ?? 'one_time'),
      hourlyRate: json['hourly_rate'] != null ? (json['hourly_rate'] as num).toDouble() : null,
      fixedPrice: json['fixed_price'] != null ? (json['fixed_price'] as num).toDouble() : null,
      isPaid: json['is_paid'] as bool? ?? true,
      paymentNegotiable: json['payment_negotiable'] as bool? ?? false,
      skillsRequired: json['skills_required'] != null
          ? List<String>.from(json['skills_required'] as List)
          : null,
      experienceLevel: ExperienceLevel.fromString(json['experience_level'] as String?),
      availableFrom: json['available_from'] != null
          ? DateTime.parse(json['available_from'] as String)
          : null,
      availableUntil: json['available_until'] != null
          ? DateTime.parse(json['available_until'] as String)
          : null,
      availableDays: json['available_days'] != null
          ? List<String>.from(json['available_days'] as List)
          : null,
      hoursPerWeek: json['hours_per_week'] as int?,
      remotePossible: json['remote_possible'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Creates from flattened feed view data
  factory JobDetails.fromFeedJson(Map<String, dynamic> json) {
    return JobDetails(
      id: '',
      postId: json['id'] as String,
      jobType: JobType.fromString(json['job_type'] as String? ?? 'one_time'),
      hourlyRate: json['hourly_rate'] != null ? (json['hourly_rate'] as num).toDouble() : null,
      fixedPrice: json['fixed_price'] != null ? (json['fixed_price'] as num).toDouble() : null,
      isPaid: json['is_paid'] as bool? ?? true,
      paymentNegotiable: json['payment_negotiable'] as bool? ?? false,
      skillsRequired: null,
      experienceLevel: ExperienceLevel.fromString(json['experience_level'] as String?),
      availableFrom: null,
      availableUntil: null,
      availableDays: null,
      hoursPerWeek: json['hours_per_week'] as int?,
      remotePossible: json['remote_possible'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'job_type': jobType.dbValue,
      'hourly_rate': hourlyRate,
      'fixed_price': fixedPrice,
      'is_paid': isPaid,
      'payment_negotiable': paymentNegotiable,
      'skills_required': skillsRequired,
      'experience_level': experienceLevel.dbValue,
      'available_from': availableFrom?.toIso8601String().split('T')[0],
      'available_until': availableUntil?.toIso8601String().split('T')[0],
      'available_days': availableDays,
      'hours_per_week': hoursPerWeek,
      'remote_possible': remotePossible,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'job_type': jobType.dbValue,
      'hourly_rate': hourlyRate,
      'fixed_price': fixedPrice,
      'is_paid': isPaid,
      'payment_negotiable': paymentNegotiable,
      'skills_required': skillsRequired,
      'experience_level': experienceLevel.dbValue,
      'available_from': availableFrom?.toIso8601String().split('T')[0],
      'available_until': availableUntil?.toIso8601String().split('T')[0],
      'available_days': availableDays,
      'hours_per_week': hoursPerWeek,
      'remote_possible': remotePossible,
    };
  }

  String get jobTypeDisplay {
    final parts = <String>[jobType.displayName];
    if (remotePossible) parts.add('Remote');
    return parts.join(' • ');
  }

  String get payDisplay {
    if (!isPaid) return 'Unpaid / Volunteer';
    if (hourlyRate != null) {
      final rate = '£${hourlyRate!.toStringAsFixed(hourlyRate! % 1 == 0 ? 0 : 2)}/hour';
      return paymentNegotiable ? '$rate (negotiable)' : rate;
    }
    if (fixedPrice != null) {
      final price = '£${fixedPrice!.toStringAsFixed(fixedPrice! % 1 == 0 ? 0 : 2)}';
      return paymentNegotiable ? '$price (negotiable)' : price;
    }
    return 'Pay negotiable';
  }
}
