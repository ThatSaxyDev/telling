import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '../config/api_config.dart';

/// Event received from Pusher channel.
class PusherEvent {
  final String type;
  final Map<String, dynamic> data;
  final DateTime receivedAt;

  PusherEvent({required this.type, required this.data, DateTime? receivedAt})
    : receivedAt = receivedAt ?? DateTime.now();
}

/// Service for connecting to Pusher and receiving real-time events.
class PusherService {
  PusherChannelsFlutter? _pusher;
  String? _token;
  String? _projectId;

  final _eventController = StreamController<PusherEvent>.broadcast();

  /// Stream of events from the Pusher channel.
  Stream<PusherEvent> get events => _eventController.stream;

  /// Whether the service is connected to Pusher.
  bool get isConnected => _pusher != null;

  /// Connect to Pusher and subscribe to the project's private channel.
  Future<void> connect({
    required String token,
    required String projectId,
  }) async {
    // Already connected to this project
    if (_projectId == projectId && _pusher != null) {
      return;
    }

    // Disconnect from previous project if any
    await disconnect();

    _token = token;
    _projectId = projectId;

    try {
      _pusher = PusherChannelsFlutter.getInstance();

      await _pusher!.init(
        apiKey: ApiConfig.pusherKey,
        cluster: ApiConfig.pusherCluster,
        onConnectionStateChange: _onConnectionStateChange,
        onError: _onError,
        onAuthorizer: _onAuthorizer,
      );

      await _pusher!.connect();

      // Subscribe to private channel for this project
      final channelName = 'private-project-$projectId';
      await _pusher!.subscribe(channelName: channelName, onEvent: _onEvent);

      if (kDebugMode) {
        debugPrint('Pusher: Subscribed to $channelName');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Pusher connection error: $e');
      _pusher = null;
    }
  }

  /// Custom authorizer for private channels.
  /// Calls our backend's /pusher/auth endpoint.
  dynamic _onAuthorizer(
    String channelName,
    String socketId,
    dynamic options,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('https://telling-server.onrender.com/pusher/auth'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'socket_id': socketId, 'channel_name': channelName}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (kDebugMode) debugPrint('Pusher auth success: $data');
        return data;
      } else {
        if (kDebugMode) {
          debugPrint(
            'Pusher auth failed: ${response.statusCode} ${response.body}',
          );
        }
        return {'error': 'Auth failed'};
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Pusher auth error: $e');
      return {'error': e.toString()};
    }
  }

  void _onConnectionStateChange(String currentState, String previousState) {
    if (kDebugMode) debugPrint('Pusher: $previousState -> $currentState');
  }

  void _onError(String message, int? code, dynamic e) {
    if (kDebugMode) debugPrint('Pusher error: $message (code: $code)');
  }

  /// Handle incoming Pusher events.
  dynamic _onEvent(dynamic event) {
    // The event comes from Pusher SDK, not our custom PusherEvent class
    if (kDebugMode) debugPrint('Pusher event received: ${event.runtimeType}');

    try {
      // Access properties from the Pusher SDK event
      final eventName = event.eventName as String?;
      final dynamic rawData = event.data;

      if (eventName == null) {
        if (kDebugMode) debugPrint('Pusher: No event name');
        return null;
      }

      if (kDebugMode) debugPrint('Pusher event: $eventName');

      Map<String, dynamic> data;

      // On web, even if rawData looks like a Map, it may be a JS interop object
      // that doesn't properly cast. Always use JSON round-trip for safety.
      try {
        if (rawData is String) {
          data = jsonDecode(rawData) as Map<String, dynamic>;
        } else {
          // Force JSON round-trip to convert JS objects to proper Dart Map
          final jsonStr = jsonEncode(rawData);
          data = jsonDecode(jsonStr) as Map<String, dynamic>;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Data conversion error: $e, type: ${rawData.runtimeType}');
        }
        return null;
      }

      _eventController.add(PusherEvent(type: eventName, data: data));
    } catch (e) {
      if (kDebugMode) debugPrint('Event parse error: $e');
    }

    return null;
  }

  /// Disconnect from Pusher.
  Future<void> disconnect() async {
    if (_pusher != null) {
      try {
        if (_projectId != null) {
          await _pusher!.unsubscribe(
            channelName: 'private-project-$_projectId',
          );
        }
        await _pusher!.disconnect();
      } catch (e) {
        if (kDebugMode) debugPrint('Pusher disconnect error: $e');
      }
    }
    _pusher = null;
    _projectId = null;
  }

  /// Dispose the service.
  void dispose() {
    disconnect();
    _eventController.close();
  }
}
