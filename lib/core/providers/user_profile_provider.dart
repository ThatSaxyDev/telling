import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/user_profile_model.dart';
import '../config/api_config.dart';
import './auth_provider.dart';

final userProfileProvider = FutureProvider.autoDispose<UserProfile>((ref) async {
  // Keep the provider alive after successful fetches to avoid re-fetching
  final link = ref.keepAlive();
  
  // Cancel keep alive after 5 minutes of inactivity
  Timer(const Duration(minutes: 5), () {
    link.close();
  });
  
  final authState = ref.watch(authProvider);
  
  if (authState.token == null) {
    throw Exception('Not authenticated');
  }
  
  final response = await http.get(
    Uri.parse('${ApiConfig.authPath}/profile'),
    headers: {
      'Authorization': 'Bearer ${authState.token}',
    },
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return UserProfile.fromJson(data);
  } else {
    throw Exception('Failed to load user profile: ${response.body}');
  }
});
