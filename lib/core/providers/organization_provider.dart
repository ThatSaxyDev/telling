import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/organization.dart';
import '../config/api_config.dart';
import '../services/api_client.dart';
import 'auth_provider.dart';

class OrganizationState {
  /// All units the user belongs to (commanded + joined).
  final List<Organization> units;

  /// Server-side active unit preference (scopes project APIs).
  final String? activeUnitId;

  final bool isLoading;
  final bool isLoaded;
  final String? error;
  final List<OrganizationMember> members;
  final bool membersLoading;
  final String? membersError;

  /// Limits from the server (GET /organizations → `limits`). Fall back to
  /// known defaults when absent (e.g. older backend).
  final int maxOwnedUnits;
  final int maxProjectsPerUnit;

  OrganizationState({
    this.units = const [],
    this.activeUnitId,
    this.isLoading = false,
    this.isLoaded = false,
    this.error,
    this.members = const [],
    this.membersLoading = false,
    this.membersError,
    int? maxOwnedUnits,
    int? maxProjectsPerUnit,
  })  : maxOwnedUnits = maxOwnedUnits ?? fallbackMaxOwnedUnits,
        maxProjectsPerUnit = maxProjectsPerUnit ?? fallbackMaxProjectsPerUnit;

  /// Fallbacks used until the server-provided limits arrive.
  static const fallbackMaxOwnedUnits = 2;
  static const fallbackMaxProjectsPerUnit = 4;

  /// The ACTIVE unit — falls back to the first known unit.
  Organization? get organization {
    if (units.isEmpty) return null;
    for (final unit in units) {
      if (unit.id == activeUnitId) return unit;
    }
    return units.first;
  }

  bool get isOwner => organization?.isOwner ?? false;
  int get ownedCount => units.where((u) => u.isOwner).length;
  bool get canCreateUnit => ownedCount < maxOwnedUnits;

  OrganizationState copyWith({
    List<Organization>? units,
    String? activeUnitId,
    bool clearActiveUnitId = false,
    bool? isLoading,
    bool? isLoaded,
    String? error,
    List<OrganizationMember>? members,
    bool? membersLoading,
    String? membersError,
    int? maxOwnedUnits,
    int? maxProjectsPerUnit,
  }) {
    return OrganizationState(
      units: units ?? this.units,
      activeUnitId: clearActiveUnitId ? null : (activeUnitId ?? this.activeUnitId),
      isLoading: isLoading ?? this.isLoading,
      isLoaded: isLoaded ?? this.isLoaded,
      error: error,
      members: members ?? this.members,
      membersLoading: membersLoading ?? this.membersLoading,
      membersError: membersError,
      maxOwnedUnits: maxOwnedUnits ?? this.maxOwnedUnits,
      maxProjectsPerUnit: maxProjectsPerUnit ?? this.maxProjectsPerUnit,
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
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final units = (data['units'] as List<dynamic>? ?? [])
            .map((e) => Organization.fromJson(e as Map<String, dynamic>))
            .toList();
        final limits = data['limits'] as Map<String, dynamic>?;
        state = state.copyWith(
          units: units,
          activeUnitId: data['activeUnitId'] as String?,
          isLoading: false,
          isLoaded: true,
          members: const [],
          maxOwnedUnits: limits?['maxOwnedUnits'] as int?,
          maxProjectsPerUnit: limits?['maxProjectsPerUnit'] as int?,
        );
        loadMembers();
      } else if (response.statusCode == 404) {
        // No unit yet — new user onboarding
        state = state.copyWith(
          units: const [],
          clearActiveUnitId: true,
          isLoading: false,
          isLoaded: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isLoaded: true,
          error: 'Failed to load unit',
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
        await load();
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: _extractError(response.body) ?? 'Failed to create unit',
      );
      return false;
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
      }
      state = state.copyWith(
        isLoading: false,
        error: _extractError(response.body) ?? 'Failed to join unit',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _sanitizeError(e));
      return false;
    }
  }

  /// Switches the server-side ACTIVE unit and reloads its members.
  /// Callers should reload projects afterwards (they are scoped per unit).
  Future<bool> switchUnit(String organizationId) async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return false;
    if (organizationId == state.activeUnitId) return true;

    final apiClient = ref.read(apiClientProvider);

    try {
      final response = await apiClient.post(
        Uri.parse('$_baseUrl/me/switch'),
        body: jsonEncode({'organizationId': organizationId}),
      );

      if (response.statusCode == 200) {
        state = state.copyWith(
          activeUnitId: organizationId,
          members: const [],
        );
        loadMembers();
        return true;
      }
      state = state.copyWith(
        error: _extractError(response.body) ?? 'Failed to switch unit',
      );
      return false;
    } catch (e) {
      state = state.copyWith(error: _sanitizeError(e));
      return false;
    }
  }

  /// Returns the unit owning [projectId], provided the user belongs to it.
  /// Used by deep links targeting a project outside the active unit.
  Future<String?> resolveProjectUnit(String projectId) async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return null;

    final apiClient = ref.read(apiClientProvider);

    try {
      final response = await apiClient.get(
        Uri.parse('$_baseUrl/resolve-project/$projectId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['organizationId'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<void> loadMembers() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return;

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

  /// Rotates the ACTIVE unit's invite code. [expiryDays] null (or omitted)
  /// makes the code valid until rotated again; 1–365 sets a window.
  Future<String?> regenerateCode({int? expiryDays}) async {
    final apiClient = ref.read(apiClientProvider);

    try {
      final response = await apiClient.post(
        Uri.parse('$_baseUrl/me/regenerate-code'),
        body: jsonEncode({'expiryDays': expiryDays}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newCode = data['inviteCode'] as String;
        final newExpiry = data['inviteCodeExpiresAt'] != null
            ? DateTime.tryParse(data['inviteCodeExpiresAt'] as String)
            : null;
        final org = state.organization;
        if (org != null) {
          final updated = Organization(
            id: org.id,
            name: org.name,
            slug: org.slug,
            plan: org.plan,
            role: org.role,
            inviteCode: newCode,
            inviteCodeExpiresAt: newExpiry,
          );
          state = state.copyWith(
            units: [
              for (final u in state.units)
                if (u.id == org.id) updated else u,
            ],
          );
        }
        return newCode;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> rename(String name) async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return false;

    final apiClient = ref.read(apiClientProvider);

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.patch(
        Uri.parse(_baseUrl),
        body: jsonEncode({'name': name}),
      );

      if (response.statusCode == 200) {
        await load();
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: _extractError(response.body) ?? 'Failed to rename unit',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _sanitizeError(e));
      return false;
    }
  }

  Future<bool> transferOwnership(String newOwnerId) async {
    final apiClient = ref.read(apiClientProvider);

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.post(
        Uri.parse('$_baseUrl/transfer'),
        body: jsonEncode({'userId': newOwnerId}),
      );

      if (response.statusCode == 200) {
        await load();
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: _extractError(response.body) ?? 'Failed to transfer unit',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _sanitizeError(e));
      return false;
    }
  }

  Future<bool> leave() async {
    final apiClient = ref.read(apiClientProvider);

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.post(Uri.parse('$_baseUrl/leave'));

      if (response.statusCode == 200) {
        // Reload remaining units. If none remain, the router sends the
        // user back to onboarding.
        await load();
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: _extractError(response.body) ?? 'Failed to leave unit',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _sanitizeError(e));
      return false;
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
