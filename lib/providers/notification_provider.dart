import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

/// Notification preferences state
class NotificationPreferences {
  final bool posts;
  final bool comments;
  final bool messages;
  final bool connections;
  final bool events;
  final bool safetyAlerts;
  final bool groups;

  const NotificationPreferences({
    this.posts = true,
    this.comments = true,
    this.messages = true,
    this.connections = true,
    this.events = true,
    this.safetyAlerts = true,
    this.groups = true,
  });

  NotificationPreferences copyWith({
    bool? posts,
    bool? comments,
    bool? messages,
    bool? connections,
    bool? events,
    bool? safetyAlerts,
    bool? groups,
  }) {
    return NotificationPreferences(
      posts: posts ?? this.posts,
      comments: comments ?? this.comments,
      messages: messages ?? this.messages,
      connections: connections ?? this.connections,
      events: events ?? this.events,
      safetyAlerts: safetyAlerts ?? this.safetyAlerts,
      groups: groups ?? this.groups,
    );
  }
}

/// Provider for notification preferences with persistence
class NotificationPreferencesNotifier
    extends StateNotifier<NotificationPreferences> {
  NotificationPreferencesNotifier() : super(const NotificationPreferences()) {
    _loadPreferences();
  }

  static const _keyPosts = 'notify_posts';
  static const _keyComments = 'notify_comments';
  static const _keyMessages = 'notify_messages';
  static const _keyConnections = 'notify_connections';
  static const _keyEvents = 'notify_events';
  static const _keySafety = 'notify_safety';
  static const _keyGroups = 'notify_groups';

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    state = NotificationPreferences(
      posts: prefs.getBool(_keyPosts) ?? true,
      comments: prefs.getBool(_keyComments) ?? true,
      messages: prefs.getBool(_keyMessages) ?? true,
      connections: prefs.getBool(_keyConnections) ?? true,
      events: prefs.getBool(_keyEvents) ?? true,
      safetyAlerts: prefs.getBool(_keySafety) ?? true,
      groups: prefs.getBool(_keyGroups) ?? true,
    );
    _syncToOneSignal();
  }

  Future<void> _saveAndSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPosts, state.posts);
    await prefs.setBool(_keyComments, state.comments);
    await prefs.setBool(_keyMessages, state.messages);
    await prefs.setBool(_keyConnections, state.connections);
    await prefs.setBool(_keyEvents, state.events);
    await prefs.setBool(_keySafety, state.safetyAlerts);
    await prefs.setBool(_keyGroups, state.groups);
    _syncToOneSignal();
  }

  void _syncToOneSignal() {
    NotificationService.setNotificationPreferences(
      posts: state.posts,
      comments: state.comments,
      messages: state.messages,
      connections: state.connections,
      events: state.events,
      safetyAlerts: state.safetyAlerts,
      groups: state.groups,
    );
  }

  void togglePosts(bool value) {
    state = state.copyWith(posts: value);
    _saveAndSync();
  }

  void toggleComments(bool value) {
    state = state.copyWith(comments: value);
    _saveAndSync();
  }

  void toggleMessages(bool value) {
    state = state.copyWith(messages: value);
    _saveAndSync();
  }

  void toggleConnections(bool value) {
    state = state.copyWith(connections: value);
    _saveAndSync();
  }

  void toggleEvents(bool value) {
    state = state.copyWith(events: value);
    _saveAndSync();
  }

  void toggleSafetyAlerts(bool value) {
    state = state.copyWith(safetyAlerts: value);
    _saveAndSync();
  }

  void toggleGroups(bool value) {
    state = state.copyWith(groups: value);
    _saveAndSync();
  }
}

/// Provider for notification preferences
final notificationPreferencesProvider =
    StateNotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>(
  (ref) => NotificationPreferencesNotifier(),
);

/// Provider for system notification permission status
final notificationPermissionProvider = StateProvider<bool>((ref) {
  return NotificationService.hasPermission;
});
