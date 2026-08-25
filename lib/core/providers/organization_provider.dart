import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/organization.dart';
import '../config/api_config.dart';
import '../services/api_client.dart';
import 'auth_provider.dart';

class OrganizationState {
  final Organization? organization;
  final bool isLoading;
  final bool isLoaded;
  final String? error;
  final List<OrganizationMember> members;
  final bool membersLoading;
  final String? membersError;

  OrganizationState({
    this.organization,
    this.isLoading = false,
    this.isLoaded = false,
    this.error,
    this.members = const [],
    this.membersLoading = false,
    this.membersError,
  });

  bool get isOwner => organization?.isOwner ?? false;

  OrganizationState copyWith({
    Organization? organization,
    bool? isLoading,
    bool? isLoaded,
    String? error,
    List<OrganizationMember>? members,
    bool? membersLoading,
    String? membersError,
  }) {
    return OrganizationState(
      organization: organization ?? this.organization,
      isLoading: isLoading ?? this.isLoading,
      isLoaded: isLoaded ?? this.isLoaded,
      error: error,
      members: members ?? this.members,
      membersLoading: membersLoading ?? this.membersLoading,
      membersError: membersError,
    );
  }
}

class OrganizationNotifier extends Notifier<OrganizationState> {
  static const _baseUrl = ApiConfig.organizationsPath;

  @override
  OrganizationState build() {
    final authState = ref.watch(authProvider);
    if (authState.isAuthenticated) {
      Future.microtask(load);
    }
    return OrganizationState();
  }

  Future<void> load() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return;

    final apiClient = ref.read(apiClientProvider);

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final org = Organization.fromJson(jsonDecode(response.body));
        state = state.copyWith(
          organization: org,
          isLoading: false,
          isLoaded: true,
          members: const [],
        );
        if (org.isOwner) {
          loadMembers();
        }
      } else if (response.statusCode == 404) {
        // No team yet — new user onboarding
        state = state.copyWith(
          organization: null,
          isLoading: false,
          isLoaded: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isLoaded: true,
          error: 'Failed to load team',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoaded: true,
        error: _sanitizeError(e),
      );
    }
  }

  Future<bool> createOrganization({String? name}) async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return false;

    final apiClient = ref.read(apiClientProvider);

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.post(
        Uri.parse(_baseUrl),
        body: jsonEncode({'name': name}),
      );

      if (response.statusCode == 200) {
        final org = Organization.fromJson(jsonDecode(response.body));
        state = state.copyWith(
          organization: org,
          isLoading: false,
          isLoaded: true,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: _extractError(response.body) ?? 'Failed to create team',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _sanitizeError(e));
      return false;
    }
  }

  Future<bool> joinOrganization(String code) async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return false;

    final apiClient = ref.read(apiClientProvider);

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.post(
        Uri.parse('$_baseUrl/join'),
        body: jsonEncode({'code': code}),
      );

      if (response.statusCode == 200) {
        await load();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: _extractError(response.body) ?? 'Failed to join team',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _sanitizeError(e));
      return false;
    }
  }

  Future<void> loadMembers() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return;
    if (!state.isOwner) return;

    final apiClient = ref.read(apiClientProvider);

    state = state.copyWith(membersLoading: true, membersError: null);
    try {
      final response = await apiClient.get(Uri.parse('$_baseUrl/me/members'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        state = state.copyWith(
          members: data
              .map((e) => OrganizationMember.fromJson(e as Map<String, dynamic>))
              .toList(),
          membersLoading: false,
        );
      } else {
        state = state.copyWith(
          membersLoading: false,
          membersError: 'Failed to load members',
        );
      }
    } catch (e) {
      state = state.copyWith(
        membersLoading: false,
        membersError: _sanitizeError(e),
      );
    }
  }

  Future<bool> removeMember(String memberId) async {
    final apiClient = ref.read(apiClientProvider);

    try {
      final response = await apiClient.delete(
        Uri.parse('$_baseUrl/me/members/$memberId'),
      );

      if (response.statusCode == 200) {
        await loadMembers();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<String?> regenerateCode() async {
    final apiClient = ref.read(apiClientProvider);

    try {
      final response = await apiClient.post(
        Uri.parse('$_baseUrl/me/regenerate-code'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newCode = data['inviteCode'] as String;
        final org = state.organization;
        if (org != null) {
          state = state.copyWith(
            organization: Organization(
              id: org.id,
              name: org.name,
              slug: org.slug,
              plan: org.plan,
              role: org.role,
              inviteCode: newCode,
            ),
          );
        }
        return newCode;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String? _extractError(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic> && data['error'] != null) {
        return data['error'] as String;
      }
    } catch (_) {}
    return null;
  }

  String _sanitizeError(Object e) {
    final message = e.toString();
    if (message.contains('ClientException') ||
        message.contains('SocketException') ||
        message.contains('Connection refused') ||
        message.contains('Failed to host lookup')) {
      return 'Network error. Please check your internet connection.';
    }
    return 'An unexpected error occurred. Please try again later.';
  }
}

final organizationProvider =
    NotifierProvider<OrganizationNotifier, OrganizationState>(() {
  return OrganizationNotifier();
});
