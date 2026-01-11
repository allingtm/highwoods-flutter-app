enum PostStatus {
  draft,
  active,
  resolved,
  expired,
  removed;

  String get displayName {
    switch (this) {
      case PostStatus.draft:
        return 'Draft';
      case PostStatus.active:
        return 'Active';
      case PostStatus.resolved:
        return 'Resolved';
      case PostStatus.expired:
        return 'Expired';
      case PostStatus.removed:
        return 'Removed';
    }
  }

  String get dbValue {
    return name;
  }

  static PostStatus fromString(String value) {
    switch (value) {
      case 'draft':
        return PostStatus.draft;
      case 'active':
        return PostStatus.active;
      case 'resolved':
        return PostStatus.resolved;
      case 'expired':
        return PostStatus.expired;
      case 'removed':
        return PostStatus.removed;
      default:
        throw ArgumentError('Unknown post status: $value');
    }
  }
}
