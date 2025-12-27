# WebSocket Integration Plan (Archived)

> **Status**: Archived - Globe hosting does not currently support WebSocket connections.  
> **Alternative**: See [SSE Implementation Plan](../sse_implementation_plan.md) for the active approach.

---

## Overview

This document outlines a WebSocket-based approach to replace HTTP polling with real-time updates in the Telling dashboard. This plan is preserved for future reference when Globe adds WebSocket support.

---

## Why WebSockets

| Scenario | HTTP Polling | WebSocket |
|----------|-------------|-----------|
| Dashboard idle 1 hour | 120+ requests | 0 data requests |
| 10 new logs arrive | 120 requests, delayed | 10 instant pushes |
| Request overhead | TCP + TLS + headers | None after handshake |

---

## Architecture

### Server Dependencies
```yaml
dependencies:
  shelf_web_socket: ^3.0.0
```

### Client Dependencies
```yaml
dependencies:
  web_socket_channel: ^3.0.2
```

### Server Handler

```dart
class WebSocketHandler {
  final Map<String, Set<WebSocketChannel>> _projectClients = {};
  static final instance = WebSocketHandler._();
  
  Handler get handler => webSocketHandler((webSocket, request) async {
    final token = request.requestedUri.queryParameters['token'];
    final projectId = request.requestedUri.queryParameters['projectId'];
    
    // Authenticate, register client, handle messages
    // ...
  });
  
  void broadcast(String projectId, String eventType, Map<String, dynamic> data) {
    // Send to all connected clients for project
  }
}
```

### Client Service

```dart
class WebSocketService {
  WebSocketChannel? _channel;
  final _eventController = StreamController<WebSocketEvent>.broadcast();
  
  Future<void> connect({
    required String baseUrl,
    required String token,
    required String projectId,
  }) async {
    final uri = Uri.parse('${baseUrl.replaceFirst('http', 'ws')}/ws?token=$token&projectId=$projectId');
    _channel = WebSocketChannel.connect(uri);
    // Handle messages, reconnection...
  }
  
  Stream<WebSocketEvent> get events => _eventController.stream;
}
```

---

## Event Types

| Event | Direction | Description |
|-------|-----------|-------------|
| `log_created` | Server → Client | New log ingested |
| `stats_updated` | Server → Client | Stats changed |
| `ping/pong` | Both | Keepalive |

---

## Migration Phases

1. **Foundation**: Server WebSocket handler + Client service
2. **Logs Stream**: Real-time log appearance
3. **Dashboard**: Stats + activity timeline
4. **Analytics**: Summary + charts
5. **Cleanup**: Remove `ref.invalidate()` calls

---

## Blocker

**Globe hosting does not support WebSocket connections** (as of December 2024).

### Alternatives
- **Server-Sent Events (SSE)**: Works over HTTP, one-way push ✅
- **Switch hosting**: Railway, Fly.io, DigitalOcean
- **Wait for Globe**: They may add WebSocket support later

---

## References

- [shelf_web_socket](https://pub.dev/packages/shelf_web_socket)
- [web_socket_channel](https://pub.dev/packages/web_socket_channel)
