import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../models/notification_settings.dart';
import '../services/api_client.dart';

/// State for notification settings
class NotificationSettingsState {
  final NotificationSettings? settings;
  final bool isLoading;
  final String? error;
  final String? projectId;

  const NotificationSettingsState({
    this.settings,
    this.isLoading = false,
    this.error,
    this.projectId,
  });

  NotificationSettingsState copyWith({
    NotificationSettings? settings,
    bool? isLoading,
    String? error,
    String? projectId,
  }) {
    return NotificationSettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      projectId: projectId ?? this.projectId,
    );
  }
}

/// Provider for notification settings
class NotificationSettingsNotifier extends Notifier<NotificationSettingsState> {
  @override
  NotificationSettingsState build() {
    return const NotificationSettingsState();
  }

  Future<void> fetchSettings(String projectId) async {
    state = state.copyWith(isLoading: true, error: null, projectId: projectId);

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(
        Uri.parse('${ApiConfig.notificationsPath}/settings?projectId=$projectId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final settings = NotificationSettings.fromJson(data);
        state = NotificationSettingsState(
          settings: settings,
          projectId: projectId,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load settings',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load settings. Please check your connection.',
      );
    }
  }

  Future<bool> updateSettings(NotificationSettings settings) async {
    final projectId = state.projectId;
    if (projectId == null) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.put(
        Uri.parse('${ApiConfig.notificationsPath}/settings'),
        body: jsonEncode({
          'projectId': projectId,
          ...settings.toJson(),
        }),
      );

      if (response.statusCode == 200) {
        state = NotificationSettingsState(
          settings: settings,
          projectId: projectId,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to update settings',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to save settings. Please try again.',
      );
      return false;
    }
  }

  /// Update a single field
  Future<bool> updateField(
    NotificationSettings Function(NotificationSettings) updater,
  ) {
    if (state.settings == null) return Future.value(false);
    return updateSettings(updater(state.settings!));
  }
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettingsState>(
  NotificationSettingsNotifier.new,
);
