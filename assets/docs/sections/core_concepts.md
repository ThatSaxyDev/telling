# Core Concepts

## Log Levels
Control the severity and visibility of your logs:

| Level | Use Case | Severity |
| :--- | :--- | :--- |
| `LogLevel.trace` | Extremely detailed debugging | 0 |
| `LogLevel.debug` | Detailed diagnostic information | 1 |
| `LogLevel.info` | General informational messages | 2 |
| `LogLevel.warning` | Potentially harmful situations | 3 |
| `LogLevel.error` | Runtime errors that allow continuation | 4 |
| `LogLevel.fatal` | Critical errors causing termination | 5 |

## Log Types
Categorize logs for better filtering and analytics:

| Type | Purpose |
| :--- | :--- |
| `LogType.general` | Standard application logs, debug, operational |
| `LogType.analytics` | User events, funnels, screen views, tracking |
| `LogType.crash` | Errors, exceptions, and crashes |
| `LogType.performance` | Performance metrics and benchmarks |
