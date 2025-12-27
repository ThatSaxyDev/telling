# Real-Time Updates: Evolution from Polling to Pusher

A technical journey through three approaches to real-time log updates in the Telling dashboard.

---

## The Problem

The Telling dashboard needs real-time updates when new logs arrive. Users shouldn't have to manually refresh to see new data.

---

## Approach 1: Polling + ref.invalidate

### How It Worked

```dart
// Every tab switch forced a full refetch
onTap: () {
  ref.invalidate(logsProvider);
  ref.invalidate(logStatsProvider);
  ref.invalidate(activityTimelineProvider);
  context.go('/logs');
}
```

### Issues

| Problem | Impact |
|---------|--------|
| **Excessive API calls** | ~5-12 calls per navigation session |
| **No true real-time** | Data stale until user action |
| **Poor UX** | Loading spinners on every tab switch |
| **Server load** | Unnecessary repeated queries |

---

## Approach 2: Server-Sent Events (SSE)

### Architecture

```
┌─────────┐                    ┌──────────┐
│ Server  │ ─── SSE stream ──→ │Dashboard │
└─────────┘                    └──────────┘
```

### Implementation

Server maintained open HTTP connections, pushing events when logs arrived.

### Why It Failed

> [!CAUTION]
> **SSE is fundamentally incompatible with serverless hosting.**

| Issue | Explanation |
|-------|-------------|
| **Stateful connections** | SSE requires persistent TCP connections |
| **Instance volatility** | Globe/serverless can spin up/down instances |
| **Connection handoff** | No way to migrate SSE streams between instances |
| **Memory pressure** | Each connection holds server memory |

When the serverless platform scaled or restarted instances, all SSE connections dropped with no recovery mechanism.

---

## Approach 3: Pusher Channels ✅

### Why Pusher Works

| Feature | Benefit |
|---------|---------|
| **Managed infrastructure** | Pusher handles WebSocket connections |
| **Serverless compatible** | Server just makes HTTP POST to trigger |
| **Private channels** | Per-project isolation with JWT auth |
| **Automatic reconnection** | SDK handles network issues |

### Architecture

```
┌─────────────┐      ┌────────────────┐      ┌──────────────┐
│ SDK sends   │ POST │  Dart Server   │ HTTP │   Pusher     │
│ logs        │─────►│ (serverless)   │─────►│   Channels   │
└─────────────┘      └────────────────┘      └──────┬───────┘
                                                    │
                            ┌───────────────────────┘
                            │ WebSocket
                            ▼
                     ┌──────────────┐
                     │  Dashboard   │
                     │  (Flutter)   │
                     └──────────────┘
```

### Key Insight

The server no longer manages connections—it just triggers events:

```dart
// Server: fire and forget
await pusher.trigger(
  channel: 'private-project-$projectId',
  event: 'log_created',
  data: logData,
);
```

The dashboard subscribes to its project channel and receives events instantly.

---

## Implementation Summary

### Server Changes

| File | Change |
|------|--------|
| `pusher_service.dart` | New - triggers events, handles auth |
| `pusher_handler.dart` | New - `/pusher/auth` endpoint |
| `log_handler.dart` | Modified - broadcasts via Pusher |
| `sse_handler.dart` | Deleted |

### Client Changes

| File | Change |
|------|--------|
| `pusher_service.dart` | New - connects, handles auth callback |
| `pusher_provider.dart` | New - manages connection lifecycle |
| `logs_provider.dart` | Modified - listens for `log_created` |
| `activity_timeline_provider.dart` | Modified - prepends new logs |
| `log_stats_provider.dart` | Modified - refreshes on `stats_updated` |
| `bottom_nav.dart` | Removed redundant invalidates |
| `sidebar_nav.dart` | Removed redundant invalidates |

---

## Results

| Metric | Before | After |
|--------|--------|-------|
| API calls per tab switch | 1-5 | **0** |
| Data freshness | Manual refresh | **Real-time** |
| Loading spinners | Every navigation | **Initial only** |

### Before: Polling

```
Overview → Logs → Overview → Logs
= 8-12 API calls, loading spinners each time
```

### After: Pusher

```
Same navigation pattern
= 0 API calls, instant cached data
= New logs appear in real-time
```

---

## Security

Private channels ensure users only receive events for projects they own:

1. Dashboard subscribes to `private-project-{id}`
2. Pusher SDK calls server's `/pusher/auth` endpoint
3. Server validates JWT + verifies project ownership
4. Server returns signed auth token
5. Pusher allows subscription

---

## Lessons Learned

1. **SSE ≠ Serverless** — Don't use stateful protocols on stateless infrastructure
2. **Managed services win** — Pusher handles the hard parts (reconnection, scaling)
3. **Event-driven is simpler** — Server just fires events, no connection management
4. **Cache + real-time** — Provider caching + Pusher events = best of both worlds
