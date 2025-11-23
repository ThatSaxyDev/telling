import 'dart:convert';
import 'dart:math';

String generateUuid() {
  return DateTime.now().millisecondsSinceEpoch.toString() +
      Random().nextInt(10000).toString();
}

String generateApiKey() {
  final bytes = List<int>.generate(32, (_) => Random().nextInt(255));
  return base64Url.encode(bytes);
}

// Generate hash for log event deduplication
String hashLogEvent(Map<String, dynamic> event) {
  final key = '${event['message']}_${event['level']}_${event['stackTrace']}';
  return key.hashCode.toString();
}
