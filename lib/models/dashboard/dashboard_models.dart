class MoodCounts {
  final int buzzing;
  final int tickingAlong;
  final int quiet;

  const MoodCounts({
    this.buzzing = 0,
    this.tickingAlong = 0,
    this.quiet = 0,
  });

  int get total => buzzing + tickingAlong + quiet;

  factory MoodCounts.fromJson(Map<String, dynamic> json) {
    return MoodCounts(
      buzzing: (json['buzzing'] as num?)?.toInt() ?? 0,
      tickingAlong: (json['ticking_along'] as num?)?.toInt() ?? 0,
      quiet: (json['quiet'] as num?)?.toInt() ?? 0,
    );
  }
}

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
  final MoodCounts moodToday;
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
    this.moodToday = const MoodCounts(),
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
      moodToday: json['mood_today'] != null
          ? MoodCounts.fromJson(json['mood_today'] as Map<String, dynamic>)
          : const MoodCounts(),
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
  final String? todaysMood;
  final int postsThisWeek;
  final int postsLastWeek;
  final int commentsThisWeek;
  final int reactionsGivenWeek;
  final int reactionsReceivedWeek;
  final String? topCategory;
  final int totalUsersMissedYesterday;

  const UserDashboardStats({
    this.streak,
    this.todaysMood,
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
      todaysMood: json['todays_mood'] as String?,
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
