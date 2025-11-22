import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models/log_event.dart';
import 'models/device_metadata.dart';
import 'models/session.dart';
import 'device_info_collector.dart';
import 'rate_limiter.dart';

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
  Timer? _cleanupTimer;

  // Rate limiter
  final LogRateLimiter _rateLimiter = LogRateLimiter();
  
  // Session tracking
  Session? _currentSession;

  Telling._internal();

  /// Initialize the Telling SDK
  Future<void> init(
    String apiKey, {
    String? baseUrl,
    String? userId,
    String? userName,
    String? userEmail,
    // Rate limiting configuration
    Duration? deduplicationWindow,
    Duration? crashThrottleWindow,
    int? maxLogsPerSecond,
  }) async {
    _apiKey = apiKey;
    if (baseUrl != null) {
      _baseUrl = baseUrl;
    }
    _userId = userId;
    _userName = userName;
    _userEmail = userEmail;
    
    // Configure rate limiter
    if (deduplicationWindow != null) {
      _rateLimiter.deduplicationWindow = deduplicationWindow;
    }
    if (crashThrottleWindow != null) {
      _rateLimiter.crashThrottleWindow = crashThrottleWindow;
    }
    if (maxLogsPerSecond != null) {
      _rateLimiter.maxLogsPerSecond = maxLogsPerSecond;
    }
    _initialized = true;
    
    // Collect device metadata
    _deviceMetadata = await DeviceInfoCollector.collect();
    
    // Start new session
    _startNewSession();
    
    // Load persisted logs
    await _loadPersistedLogs();
    
    _startFlushTimer();
    
    // Setup app lifecycle listeners
    _setupAppLifecycleListeners();
    
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
      
      // Determine severity based on error type
      final errorString = details.exception.toString().toLowerCase();
      final isRenderIssue =
          errorString.contains('overflow') ||
          errorString.contains('renderflex') ||
          errorString.contains('renderbox') ||
          errorString.contains('disposed') ||
          errorString.contains('trying to render');

      final isLayoutIssue =
          errorString.contains('constraints') ||
          errorString.contains('size') ||
          errorString.contains('layout');

      // Framework/render issues are warnings, actual crashes are fatal
      final level = (isRenderIssue || isLayoutIssue)
          ? LogLevel.warning
          : LogLevel.fatal;
      final type = (isRenderIssue || isLayoutIssue)
          ? LogType.general
          : LogType.crash;
      
      log(
        'Flutter Error: ${details.exception}',
        level: level,
        error: details.exception,
        stackTrace: details.stack,
        type: type,
      );
      
      // Still print to console in debug mode
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
    };
    
    // Catch async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      print('Telling: CAUGHT PLATFORM ERROR: $error');

      // Platform errors are usually fatal
      log(
        'Platform Error: $error',
        level: LogLevel.fatal,
        error: error,
        stackTrace: stack,
        type: LogType.crash,
      );
      return true;
    };
    
    print('Telling: Crash reporting enabled');
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
      sessionId: _currentSession?.sessionId,
    );

    // Check rate limiter
    if (!_rateLimiter.shouldSendLog(event)) {
      if (kDebugMode) {
        print('Telling: Rate limited log (${event.level}/${event.type})');
      }
      return; // Drop rate-limited log
    }

    _buffer.add(event);
    _rateLimiter.markLogSent(event);
    _persistLogs(); // Save to disk immediately
    
    // If error, flush immediately
    if (level == LogLevel.error) {
      _flush();
    }
  }

  void _startFlushTimer() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(const Duration(seconds: 5), (_) => _flush());
    
    // Periodic cleanup for rate limiter
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _rateLimiter.cleanup();
    });
  }

  Future<void> _flush() async {
    if (_buffer.isEmpty) return;

    // Deduplicate buffer by hash before sending
    final uniqueLogs = <String, LogEvent>{};
    for (var log in _buffer) {
      final hash = '${log.message}_${log.level}_${log.stackTrace ?? ""}'
          .hashCode
          .toString();
      uniqueLogs[hash] = log; // Keeps last occurrence
    }

    final eventsToSend = uniqueLogs.values.toList();
    _buffer.clear();

    if (kDebugMode && eventsToSend.length < _buffer.length) {
      print(
        'Telling: Deduplicated buffer: ${_buffer.length} → ${eventsToSend.length} unique logs',
      );
    }

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
  
  // ===== Session Management =====

  /// Start a new session
  void _startNewSession() {
    _currentSession = Session(
      sessionId: _generateSessionId(),
      startTime: DateTime.now(),
      userId: _userId,
      userEmail: _userEmail,
      userName: _userName,
    );

    if (kDebugMode) {
      print('Telling: Started session ${_currentSession!.sessionId}');
    }

    // Track session start event
    log(
      'Session started',
      level: LogLevel.info,
      type: LogType.analytics,
      metadata: {
        'sessionId': _currentSession!.sessionId,
        'startTime': _currentSession!.startTime.toIso8601String(),
      },
    );
  }

  /// End the current session
  void _endSession() {
    if (_currentSession != null && _currentSession!.isActive) {
      _currentSession!.endTime = DateTime.now();

      if (kDebugMode) {
        print(
          'Telling: Ended session ${_currentSession!.sessionId} (duration: ${_currentSession!.duration?.inSeconds}s)',
        );
      }

      // Track session end event
      log(
        'Session ended',
        level: LogLevel.info,
        type: LogType.analytics,
        metadata: _currentSession!.toJson(),
      );

      // Flush logs immediately
      _flush();
    }
  }

  /// Generate a unique session ID
  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final userPrefix = _userId ?? 'anon';
    return '${userPrefix}_$timestamp';
  }

  /// Setup app lifecycle listeners for session tracking
  void _setupAppLifecycleListeners() {
    WidgetsBinding.instance.addObserver(
      _AppLifecycleObserver(onPause: _endSession, onResume: _startNewSession),
    );
  }
  
  void dispose() {
    _flushTimer?.cancel();
  }
}

/// Observer for app lifecycle changes to manage sessions
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback onPause;
  final VoidCallback onResume;

  _AppLifecycleObserver({required this.onPause, required this.onResume});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      onPause();
    } else if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}
