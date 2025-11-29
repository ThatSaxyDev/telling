import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project.dart';
import 'auth_provider.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';

class ProjectState {
  final List<Project> projects;
  final Project? selectedProject;
  final bool isLoading;
  final String? error;

  ProjectState({
    this.projects = const [],
    this.selectedProject,
    this.isLoading = false,
    this.error,
  });

  ProjectState copyWith({
    List<Project>? projects,
    Project? selectedProject,
    bool? isLoading,
    String? error,
  }) {
    return ProjectState(
      projects: projects ?? this.projects,
      selectedProject: selectedProject ?? this.selectedProject,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProjectNotifier extends Notifier<ProjectState> {
  static const _baseUrl = ApiConfig.projectsPath;

  @override
  ProjectState build() {
    // Watch auth state and auto-load projects when user logs in
    final authState = ref.watch(authProvider);
    if (authState.isAuthenticated) {
      Future.microtask(() => loadProjects());
    }
    return ProjectState();
  }

  Future<void> loadProjects() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return;

    final apiClient = ref.read(apiClientProvider);

    state = state.copyWith(isLoading: true, error: null);
    try {
      // ApiClient handles Authorization header
      final response = await apiClient.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final projects = data.map((e) => Project.fromJson(e)).toList();
        
        // DO NOT auto-select any project - force user to choose
        state = state.copyWith(
          projects: projects,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to load projects');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createProject(String name) async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return;

    final apiClient = ref.read(apiClientProvider);

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.post(
        Uri.parse(_baseUrl),
        body: jsonEncode({'name': name}),
      );

      if (response.statusCode == 200) {
        final newProject = Project.fromJson(jsonDecode(response.body));
        state = state.copyWith(
          projects: [...state.projects, newProject],
          selectedProject: newProject,
          isLoading: false,
        );
      } else if (response.statusCode == 403) {
        state = state.copyWith(isLoading: false, error: 'Project limit reached (Max 3)');
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to create project');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteProject(String projectId) async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return;

    final apiClient = ref.read(apiClientProvider);

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.delete(
        Uri.parse('$_baseUrl/$projectId'),
      );

      if (response.statusCode == 200) {
        final updatedProjects = state.projects.where((p) => p.id != projectId).toList();
        Project? newSelected = state.selectedProject;
        
        if (state.selectedProject?.id == projectId) {
          newSelected = updatedProjects.isNotEmpty ? updatedProjects.first : null;
        }

        state = state.copyWith(
          projects: updatedProjects,
          selectedProject: newSelected,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to delete project');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<String?> regenerateApiKey(String projectId) async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return null;

    final apiClient = ref.read(apiClientProvider);

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.post(
        Uri.parse('$_baseUrl/$projectId/regenerate-key'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newApiKey = data['apiKey'] as String;

        // Update the selected project with the new API key
        final updatedProjects = state.projects.map((p) {
          if (p.id == projectId) {
            return Project(
              id: p.id,
              name: p.name,
              apiKey: newApiKey,
              createdAt: p.createdAt,
            );
          }
          return p;
        }).toList();

        Project? updatedSelected = state.selectedProject;
        if (state.selectedProject?.id == projectId) {
          updatedSelected = updatedProjects.firstWhere(
            (p) => p.id == projectId,
          );
        }

        state = state.copyWith(
          projects: updatedProjects,
          selectedProject: updatedSelected,
          isLoading: false,
        );

        return newApiKey;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to regenerate API key',
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  void selectProject(Project project) {
    state = state.copyWith(selectedProject: project);
  }

  void reset() {
    state = ProjectState();
  }
}

final projectProvider = NotifierProvider<ProjectNotifier, ProjectState>(() {
  return ProjectNotifier();
});
