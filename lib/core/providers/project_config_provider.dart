import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';
import 'project_provider.dart';

/// State for project version config
class ProjectConfigState {
  final Map<String, String> config;
  final bool isLoading;
  final String? error;

  ProjectConfigState({
    this.config = const {},
    this.isLoading = false,
    this.error,
  });

  ProjectConfigState copyWith({
    Map<String, String>? config,
    bool? isLoading,
    String? error,
  }) {
    return ProjectConfigState(
      config: config ?? this.config,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing project version config
class ProjectConfigNotifier extends Notifier<ProjectConfigState> {
  @override
  ProjectConfigState build() {
    return ProjectConfigState();
  }

  /// Load config for the selected project
  Future<void> loadConfig() async {
    final projectState = ref.read(projectProvider);
    final project = projectState.selectedProject;
    if (project == null) return;

    final apiClient = ref.read(apiClientProvider);

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.get(
        Uri.parse('${ApiConfig.projectConfigPath}/${project.id}/config'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final configData = data['config'] as Map<String, dynamic>? ?? {};
        
        // Extract values from nested structure
        final config = <String, String>{};
        for (final entry in configData.entries) {
          final value = entry.value;
          if (value is Map<String, dynamic>) {
            config[entry.key] = value['value']?.toString() ?? '';
          } else {
            config[entry.key] = value?.toString() ?? '';
          }
        }

        state = state.copyWith(config: config, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to load config');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _sanitizeError(e));
    }
  }

  /// Update config for the selected project
  Future<bool> updateConfig(Map<String, String> newConfig) async {
    final projectState = ref.read(projectProvider);
    final project = projectState.selectedProject;
    if (project == null) return false;

    final apiClient = ref.read(apiClientProvider);

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.put(
        Uri.parse('${ApiConfig.projectConfigPath}/${project.id}/config'),
        body: jsonEncode(newConfig),
      );

      if (response.statusCode == 200) {
        state = state.copyWith(config: newConfig, isLoading: false);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to save config');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _sanitizeError(e));
      return false;
    }
  }

  void reset() {
    state = ProjectConfigState();
  }

  String _sanitizeError(Object e) {
    final message = e.toString();
    if (message.contains('ClientException') ||
        message.contains('SocketException') ||
        message.contains('Connection refused')) {
      return 'Network error. Please check your internet connection.';
    }
    return 'An unexpected error occurred.';
  }
}

final projectConfigProvider =
    NotifierProvider<ProjectConfigNotifier, ProjectConfigState>(() {
  return ProjectConfigNotifier();
});
