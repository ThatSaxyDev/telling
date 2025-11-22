import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models/log_event.dart';
import 'models/device_metadata.dart';
import 'device_info_collector.dart';

class Telling {
  static final Telling _instance = Telling._internal();
  static Telling get instance => _instance;

  String? _apiKey;
  String _baseUrl = 'http://localhost:8080/api/v1/logs'; // Placeholder
  bool _initialized = false;
  DeviceMetadata? _deviceMetadata;
  static const String _storageKey = 'telling_logs_buffer';
  
  // User context
  String? _userId;
  String? _userName;
  String? _userEmail;
  
  // Simple buffer to avoid spamming network
  final List<LogEvent> _buffer = [];
  Timer? _flushTimer;

  Telling._internal();

  /// Initialize the Telling SDK
  Future<void> init(
    String apiKey, {
    String? baseUrl,
    String? userId,
    String? userName,
    String? userEmail,
  }) async {
    _apiKey = apiKey;
    if (baseUrl != null) {
      _baseUrl = baseUrl;
    }
    _userId = userId;
    _userName = userName;
    _userEmail = userEmail;
    _initialized = true;
    
    // Collect device metadata
    _deviceMetadata = await DeviceInfoCollector.collect();
    
    // Load persisted logs
    await _loadPersistedLogs();
    
    _startFlushTimer();
    print('Telling SDK Initialized');
  }

  /// Enable automatic crash reporting
  void enableCrashReporting() {
    if (!_initialized) {
      print('Telling SDK not initialized. Call Telling.instance.init() first.');
      return;
    }
    
    // Catch Flutter framework errors
    FlutterError.onError = (details) {
      print('Telling: CAUGHT FLUTTER ERROR: ${details.exception}');
      log(
        'Crash: ${details.exception}',
        level: LogLevel.fatal,
        error: details.exception,
        stackTrace: details.stack,
        type: LogType.crash,
      );
      
      // Pass to original handler if it exists (e.g. to print to console)
      FlutterError.presentError(details);
    };
    
    // Catch async platform errors
    PlatformDispatcher.instance.onError = (error, stack) {
      print('Telling: CAUGHT ASYNC ERROR: $error');
      log(
        'Async Crash: $error',
        level: LogLevel.fatal,
        error: error,
        stackTrace: stack,
        type: LogType.crash,
      );
      return true; // Prevent app crash
    };
    
    print('Telling Crash Reporting Enabled');
  }

  /// Track an analytics event
  void event(String name, {Map<String, dynamic>? properties}) {
    log(
      name,
      level: LogLevel.info,
      metadata: properties,
      type: LogType.analytics,
    );
  }

  /// Log a message
  void log(
    String message, {
    LogLevel level = LogLevel.info,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
    LogType type = LogType.general,
  }) {
    if (!_initialized) {
      print('Telling SDK not initialized. Call Telling.instance.init() first.');
      return;
    }

    final event = LogEvent(
      type: type,
      level: level,
      message: message,
      timestamp: DateTime.now(),
      stackTrace: stackTrace?.toString() ?? (error is Error ? error.stackTrace?.toString() : null),
      metadata: metadata,
      deviceMetadata: _deviceMetadata,
      userId: _userId,
      userName: _userName,
      userEmail: _userEmail,
    );

    _buffer.add(event);
    _persistLogs(); // Save to disk immediately
    
    // If error, flush immediately
    if (level == LogLevel.error) {
      _flush();
    }
  }

  void _startFlushTimer() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(const Duration(seconds: 5), (_) => _flush());
  }

  Future<void> _flush() async {
    if (_buffer.isEmpty) return;

    final eventsToSend = List<LogEvent>.from(_buffer);
    _buffer.clear();

    try {
      // Batch sending
      print('Telling: Sending ${eventsToSend.length} logs to $_baseUrl');
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey!,
        },
        body: jsonEncode(eventsToSend.map((e) => e.toJson()).toList()),
      );
      
      if (response.statusCode != 200) {
        print('Telling: Failed to send logs. Status: ${response.statusCode}');
        // Put back in buffer/storage to retry later
        _buffer.addAll(eventsToSend);
        _persistLogs();
      } else {
        // Success! Clear from persistence
        _persistLogs();
      }
      
    } catch (e) {
      print('Telling: Failed to send logs: $e');
      // Restore buffer on failure
      _buffer.addAll(eventsToSend);
      _persistLogs();
    }
  }

  Future<void> _persistLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = _buffer.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_storageKey, logsJson);
    } catch (e) {
      print('Telling: Failed to persist logs: $e');
    }
  }

  Future<void> _loadPersistedLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = prefs.getStringList(_storageKey);

      if (logsJson != null && logsJson.isNotEmpty) {
        print('Telling: Found ${logsJson.length} unsent logs on disk.');
        for (var logString in logsJson) {
          try {
            final map = jsonDecode(logString);
            // Reconstruct LogEvent (simplified for now, assuming structure matches)
            // Note: You might need a fromJson method in LogEvent
            final event = LogEvent(
              type: LogType.values.firstWhere(
                (e) => e.toString().split('.').last == map['type'],
                orElse: () => LogType.general,
              ),
              level: LogLevel.values.firstWhere(
                (e) => e.toString().split('.').last == map['level'],
                orElse: () => LogLevel.info,
              ),
              message: map['message'],
              timestamp: DateTime.parse(map['timestamp']),
              stackTrace: map['stackTrace'],
              metadata: map['metadata'],
              // deviceMetadata is usually re-attached or stored in the log.
              // For simplicity, we'll assume it's in the log or we attach current.
              // If stored in log:
              // deviceMetadata: map['device'] != null ? DeviceMetadata.fromJson(map['device']) : null,
            );
            _buffer.add(event);
          } catch (e) {
            print('Telling: Error parsing persisted log: $e');
          }
        }
        // Try to send immediately
        _flush();
      }
    } catch (e) {
      print('Telling: Failed to load persisted logs: $e');
    }
  }
  
  void dispose() {
    _flushTimer?.cancel();
  }
}
