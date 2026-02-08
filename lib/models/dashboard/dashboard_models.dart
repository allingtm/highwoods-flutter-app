class ReactionCounts {
  final int like;
  final int love;
  final int helpful;
  final int thanks;

  const ReactionCounts({
    this.like = 0,
    this.love = 0,
    this.helpful = 0,
    this.thanks = 0,
  });

  int get total => like + love + helpful + thanks;

  factory ReactionCounts.fromJson(Map<String, dynamic> json) {
    return ReactionCounts(
      like: (json['like'] as num?)?.toInt() ?? 0,
      love: (json['love'] as num?)?.toInt() ?? 0,
      helpful: (json['helpful'] as num?)?.toInt() ?? 0,
      thanks: (json['thanks'] as num?)?.toInt() ?? 0,
    );
  }
}

class DayCount {
  final DateTime date;
  final int count;

  const DayCount({required this.date, required this.count});

  String get dayLabel {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  factory DayCount.fromJson(Map<String, dynamic> json) {
    return DayCount(
      date: DateTime.parse(json['date'] as String),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class DashboardStats {
  final int activeAlerts;
  final int highPriorityAlerts;
  final int eventsThisWeek;
  final int eventsAttendees;
  final int marketplaceActive;
  final int lostFoundActive;
  final int lostFoundResolved;
  final int jobsActive;
  final int helpRequests;
  final int activeUsersToday;
  final int activeUsersWeek;
  final int totalPostsToday;
  final int totalPostsWeek;
  final int totalPostsLastWeek;
  final ReactionCounts reactionsByType;
  final List<DayCount> postsByDay;

  const DashboardStats({
    this.activeAlerts = 0,
    this.highPriorityAlerts = 0,
    this.eventsThisWeek = 0,
    this.eventsAttendees = 0,
    this.marketplaceActive = 0,
    this.lostFoundActive = 0,
    this.lostFoundResolved = 0,
    this.jobsActive = 0,
    this.helpRequests = 0,
    this.activeUsersToday = 0,
    this.activeUsersWeek = 0,
    this.totalPostsToday = 0,
    this.totalPostsWeek = 0,
    this.totalPostsLastWeek = 0,
    this.reactionsByType = const ReactionCounts(),
    this.postsByDay = const [],
  });

  double get weekOverWeekChange => totalPostsLastWeek > 0
      ? ((totalPostsWeek - totalPostsLastWeek) / totalPostsLastWeek * 100)
      : 0;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      activeAlerts: (json['active_alerts'] as num?)?.toInt() ?? 0,
      highPriorityAlerts: (json['high_priority_alerts'] as num?)?.toInt() ?? 0,
      eventsThisWeek: (json['events_this_week'] as num?)?.toInt() ?? 0,
      eventsAttendees: (json['events_attendees'] as num?)?.toInt() ?? 0,
      marketplaceActive: (json['marketplace_active'] as num?)?.toInt() ?? 0,
      lostFoundActive: (json['lost_found_active'] as num?)?.toInt() ?? 0,
      lostFoundResolved: (json['lost_found_resolved'] as num?)?.toInt() ?? 0,
      jobsActive: (json['jobs_active'] as num?)?.toInt() ?? 0,
      helpRequests: (json['help_requests'] as num?)?.toInt() ?? 0,
      activeUsersToday: (json['active_users_today'] as num?)?.toInt() ?? 0,
      activeUsersWeek: (json['active_users_week'] as num?)?.toInt() ?? 0,
      totalPostsToday: (json['total_posts_today'] as num?)?.toInt() ?? 0,
      totalPostsWeek: (json['total_posts_week'] as num?)?.toInt() ?? 0,
      totalPostsLastWeek: (json['total_posts_last_week'] as num?)?.toInt() ?? 0,
      reactionsByType: json['reactions_by_type'] != null
          ? ReactionCounts.fromJson(json['reactions_by_type'] as Map<String, dynamic>)
          : const ReactionCounts(),
      postsByDay: (json['posts_by_day'] as List<dynamic>?)
              ?.map((e) => DayCount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class UserStreak {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;
  final int totalActiveDays;
  final String? streakMilestone;

  const UserStreak({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    this.totalActiveDays = 0,
    this.streakMilestone,
  });

  factory UserStreak.fromJson(Map<String, dynamic> json) {
    return UserStreak(
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
      lastActiveDate: json['last_active_date'] != null
          ? DateTime.tryParse(json['last_active_date'] as String)
          : null,
      totalActiveDays: (json['total_active_days'] as num?)?.toInt() ?? 0,
      streakMilestone: json['streak_milestone'] as String?,
    );
  }
}

class UserDashboardStats {
  final UserStreak? streak;
  final int postsThisWeek;
  final int postsLastWeek;
  final int commentsThisWeek;
  final int reactionsGivenWeek;
  final int reactionsReceivedWeek;
  final String? topCategory;
  final int totalUsersMissedYesterday;

  const UserDashboardStats({
    this.streak,
    this.postsThisWeek = 0,
    this.postsLastWeek = 0,
    this.commentsThisWeek = 0,
    this.reactionsGivenWeek = 0,
    this.reactionsReceivedWeek = 0,
    this.topCategory,
    this.totalUsersMissedYesterday = 0,
  });

  factory UserDashboardStats.fromJson(Map<String, dynamic> json) {
    return UserDashboardStats(
      streak: json['streak'] != null
          ? UserStreak.fromJson(json['streak'] as Map<String, dynamic>)
          : null,
      postsThisWeek: (json['posts_this_week'] as num?)?.toInt() ?? 0,
      postsLastWeek: (json['posts_last_week'] as num?)?.toInt() ?? 0,
      commentsThisWeek: (json['comments_this_week'] as num?)?.toInt() ?? 0,
      reactionsGivenWeek: (json['reactions_given_week'] as num?)?.toInt() ?? 0,
      reactionsReceivedWeek: (json['reactions_received_week'] as num?)?.toInt() ?? 0,
      topCategory: json['top_category'] as String?,
      totalUsersMissedYesterday: (json['total_users_missed_yesterday'] as num?)?.toInt() ?? 0,
    );
  }
}

// ============================================================
// Stage 2 Models
// ============================================================

class ActivityDay {
  final DateTime date;
  final int posts;
  final int comments;
  final int reactions;

  const ActivityDay({
    required this.date,
    this.posts = 0,
    this.comments = 0,
    this.reactions = 0,
  });

  factory ActivityDay.fromJson(Map<String, dynamic> json) {
    return ActivityDay(
      date: DateTime.parse(json['date'] as String),
      posts: (json['posts'] as num?)?.toInt() ?? 0,
      comments: (json['comments'] as num?)?.toInt() ?? 0,
      reactions: (json['reactions'] as num?)?.toInt() ?? 0,
    );
  }
}

class CategoryBreakdown {
  final String category;
  final int currentCount;
  final int previousCount;

  const CategoryBreakdown({
    required this.category,
    this.currentCount = 0,
    this.previousCount = 0,
  });

  String get displayName {
    switch (category) {
      case 'discussion':
        return 'Discussion';
      case 'marketplace':
        return 'Market';
      case 'recommendations':
        return 'Recs';
      case 'safety':
        return 'Safety';
      case 'lost_found':
        return 'Lost';
      case 'social':
        return 'Events';
      case 'jobs':
        return 'Jobs';
      default:
        return category;
    }
  }

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdown(
      category: json['category'] as String,
      currentCount: (json['current_count'] as num?)?.toInt() ?? 0,
      previousCount: (json['previous_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class AiInsight {
  final String id;
  final String insightType;
  final String? title;
  final String content;
  final String? emoji;
  final DateTime generatedAt;

  const AiInsight({
    required this.id,
    required this.insightType,
    this.title,
    required this.content,
    this.emoji,
    required this.generatedAt,
  });

  factory AiInsight.fromJson(Map<String, dynamic> json) {
    return AiInsight(
      id: json['id'] as String,
      insightType: json['insight_type'] as String,
      title: json['title'] as String?,
      content: json['content'] as String,
      emoji: json['emoji'] as String?,
      generatedAt: DateTime.parse(json['generated_at'] as String),
    );
  }
}

// ============================================================
// Stage 3 Models
// ============================================================

class UserBadge {
  final String badgeType;
  final DateTime earnedAt;

  const UserBadge({
    required this.badgeType,
    required this.earnedAt,
  });

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    return UserBadge(
      badgeType: json['badge_type'] as String,
      earnedAt: DateTime.parse(json['earned_at'] as String),
    );
  }

  String get displayName {
    switch (badgeType) {
      case 'first_post':
        return 'First Post';
      case 'helper':
        return 'Helper';
      case 'marketplace_maven':
        return 'Maven';
      case 'event_organiser':
        return 'Organiser';
      case 'safety_watcher':
        return 'Watcher';
      case 'streak_regular':
        return 'Regular';
      case 'streak_dedicated':
        return 'Dedicated';
      case 'streak_legend':
        return 'Legend';
      case 'booster':
        return 'Booster';
      default:
        return badgeType;
    }
  }
}

class PersonalWrapped {
  final int month;
  final int year;
  final int posts;
  final int comments;
  final int reactionsReceived;
  final int eventsAttended;
  final String? topCategory;
  final int? engagementPercentile;

  const PersonalWrapped({
    required this.month,
    required this.year,
    this.posts = 0,
    this.comments = 0,
    this.reactionsReceived = 0,
    this.eventsAttended = 0,
    this.topCategory,
    this.engagementPercentile,
  });

  String get monthName {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month - 1];
  }

  bool get hasActivity => posts > 0 || comments > 0 || reactionsReceived > 0;

  factory PersonalWrapped.fromJson(Map<String, dynamic> json) {
    return PersonalWrapped(
      month: (json['month'] as num?)?.toInt() ?? 1,
      year: (json['year'] as num?)?.toInt() ?? 2026,
      posts: (json['posts'] as num?)?.toInt() ?? 0,
      comments: (json['comments'] as num?)?.toInt() ?? 0,
      reactionsReceived: (json['reactions_received'] as num?)?.toInt() ?? 0,
      eventsAttended: (json['events_attended'] as num?)?.toInt() ?? 0,
      topCategory: json['top_category'] as String?,
      engagementPercentile: (json['engagement_percentile'] as num?)?.toInt(),
    );
  }
}

class BadgeProgress {
  final int posts;
  final int helpPosts;
  final int marketplacePosts;
  final int eventPosts;
  final int safetyPosts;
  final int reactionsGiven;
  final int currentStreak;

  const BadgeProgress({
    this.posts = 0,
    this.helpPosts = 0,
    this.marketplacePosts = 0,
    this.eventPosts = 0,
    this.safetyPosts = 0,
    this.reactionsGiven = 0,
    this.currentStreak = 0,
  });

  factory BadgeProgress.fromJson(Map<String, dynamic> json) {
    return BadgeProgress(
      posts: (json['posts'] as num?)?.toInt() ?? 0,
      helpPosts: (json['help_posts'] as num?)?.toInt() ?? 0,
      marketplacePosts: (json['marketplace_posts'] as num?)?.toInt() ?? 0,
      eventPosts: (json['event_posts'] as num?)?.toInt() ?? 0,
      safetyPosts: (json['safety_posts'] as num?)?.toInt() ?? 0,
      reactionsGiven: (json['reactions_given'] as num?)?.toInt() ?? 0,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
    );
  }

  /// Returns "current / target" for a given badge type.
  String progressFor(String badgeType) {
    switch (badgeType) {
      case 'first_post':
        return '${posts.clamp(0, 1)} / 1';
      case 'helper':
        return '${helpPosts.clamp(0, 5)} / 5';
      case 'marketplace_maven':
        return '${marketplacePosts.clamp(0, 10)} / 10';
      case 'event_organiser':
        return '${eventPosts.clamp(0, 3)} / 3';
      case 'safety_watcher':
        return '${safetyPosts.clamp(0, 3)} / 3';
      case 'streak_regular':
        return '${currentStreak.clamp(0, 7)} / 7';
      case 'streak_dedicated':
        return '${currentStreak.clamp(0, 30)} / 30';
      case 'streak_legend':
        return '${currentStreak.clamp(0, 100)} / 100';
      case 'booster':
        return '${reactionsGiven.clamp(0, 50)} / 50';
      default:
        return '';
    }
  }
}

// ============================================================
// Stage 4 Models
// ============================================================

class NeighbourhoodGoal {
  final String id;
  final String title;
  final String? description;
  final int targetCount;
  final int currentCount;
  final String goalType;
  final DateTime startsAt;
  final DateTime endsAt;

  const NeighbourhoodGoal({
    required this.id,
    required this.title,
    this.description,
    required this.targetCount,
    this.currentCount = 0,
    required this.goalType,
    required this.startsAt,
    required this.endsAt,
  });

  double get progress => targetCount > 0 ? currentCount / targetCount : 0;
  bool get isComplete => currentCount >= targetCount;

  factory NeighbourhoodGoal.fromJson(Map<String, dynamic> json) {
    return NeighbourhoodGoal(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      targetCount: (json['target_count'] as num?)?.toInt() ?? 0,
      currentCount: (json['current_count'] as num?)?.toInt() ?? 0,
      goalType: json['goal_type'] as String,
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: DateTime.parse(json['ends_at'] as String),
    );
  }
}
