import 'package:flutter/material.dart';

enum PostCategory {
  discussion,
  marketplace,
  recommendations,
  safety,
  lostFound,
  social,
  jobs;

  String get displayName {
    switch (this) {
      case PostCategory.discussion:
        return 'Discussion';
      case PostCategory.marketplace:
        return 'Marketplace';
      case PostCategory.recommendations:
        return 'Recommendations';
      case PostCategory.safety:
        return 'Safety & Alerts';
      case PostCategory.lostFound:
        return 'Lost & Found';
      case PostCategory.social:
        return 'Events & Social';
      case PostCategory.jobs:
        return 'Local Jobs';
    }
  }

  String get dbValue {
    switch (this) {
      case PostCategory.discussion:
        return 'discussion';
      case PostCategory.marketplace:
        return 'marketplace';
      case PostCategory.recommendations:
        return 'recommendations';
      case PostCategory.safety:
        return 'safety';
      case PostCategory.lostFound:
        return 'lost_found';
      case PostCategory.social:
        return 'social';
      case PostCategory.jobs:
        return 'jobs';
    }
  }

  IconData get icon {
    switch (this) {
      case PostCategory.discussion:
        return Icons.forum;
      case PostCategory.marketplace:
        return Icons.shopping_cart;
      case PostCategory.recommendations:
        return Icons.help_outline;
      case PostCategory.safety:
        return Icons.warning;
      case PostCategory.lostFound:
        return Icons.pets;
      case PostCategory.social:
        return Icons.event;
      case PostCategory.jobs:
        return Icons.work;
    }
  }

  Color get color {
    switch (this) {
      case PostCategory.discussion:
        return const Color(0xFF6366F1); // Indigo
      case PostCategory.marketplace:
        return const Color(0xFF22C55E); // Green
      case PostCategory.recommendations:
        return const Color(0xFF3B82F6); // Blue
      case PostCategory.safety:
        return const Color(0xFFEF4444); // Red
      case PostCategory.lostFound:
        return const Color(0xFFF97316); // Orange
      case PostCategory.social:
        return const Color(0xFF8B5CF6); // Purple
      case PostCategory.jobs:
        return const Color(0xFF14B8A6); // Teal
    }
  }

  static PostCategory fromString(String value) {
    switch (value) {
      case 'discussion':
        return PostCategory.discussion;
      case 'marketplace':
        return PostCategory.marketplace;
      case 'recommendations':
        return PostCategory.recommendations;
      case 'safety':
        return PostCategory.safety;
      case 'lost_found':
        return PostCategory.lostFound;
      case 'social':
        return PostCategory.social;
      case 'jobs':
        return PostCategory.jobs;
      default:
        throw ArgumentError('Unknown category: $value');
    }
  }
}
