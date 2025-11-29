import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../models/user_properties.dart';
import '../services/api_client.dart';
import './project_provider.dart';

final userPropertiesProvider =
    FutureProvider.family<UserProperties, String>((ref, userId) async {
  final apiClient = ref.read(apiClientProvider);
  final projectState = ref.watch(projectProvider);
  
  final apiKey = projectState.selectedProject?.apiKey;
  if (apiKey == null) {
    throw Exception('No project selected');
  }
  
  final response = await apiClient.get(
    Uri.parse('${ApiConfig.baseUrl}/users/$userId/properties'),
    headers: {'x-api-key': apiKey},
  );
  return UserProperties.fromJson(jsonDecode(response.body));
});

final updateUserPropertiesProvider = Provider((ref) {
  return (String userId, Map<String, dynamic> properties) async {
    final apiClient = ref.read(apiClientProvider);
    final projectState = ref.read(projectProvider);
    
    final apiKey = projectState.selectedProject?.apiKey;
    if (apiKey == null) {
      throw Exception('No project selected');
    }
    
    await apiClient.post(
      Uri.parse('${ApiConfig.baseUrl}/users/$userId/properties'),
      body: jsonEncode({'properties': properties}),
      headers: {'x-api-key': apiKey},
    );
    ref.invalidate(userPropertiesProvider(userId));
  };
});
