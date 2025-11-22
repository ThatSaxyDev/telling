# Telling Backend

A lightweight log ingestion server built with [Shelf](https://pub.dev/packages/shelf) and [SQLite](https://pub.dev/packages/sqlite3).

## 🚀 Features

- **Log Ingestion**: Accepts logs, events, and crash reports via HTTP POST.
- **Persistence**: Stores all data in a local SQLite database (`telling.db`).
- **Querying**: Provides endpoints to fetch, filter, and delete logs.
- **CORS Support**: Enabled for web dashboard access.

## 🛠 API Endpoints

### `POST /api/v1/logs`
Ingest a new log event.
- **Body**: JSON object matching `LogEvent` structure.

### `GET /api/v1/logs`
Retrieve all logs.
- **Response**: JSON array of logs.

### `GET /api/v1/logs/<id>`
Retrieve a specific log by ID.

### `DELETE /api/v1/logs/<id>`
Delete a specific log by ID.

## 🏃‍♂️ Running the Server

### 1. Install Dependencies

```bash
dart pub get
```

### 2. Run the Server

```bash
dart run bin/server.dart
```

The server will start on `0.0.0.0:8080`.

## 🗄️ Database

The server uses a SQLite database file named `telling.db` located in the `backend/` directory.
**Note**: This file is git-ignored to prevent large file issues in version control.

## 🐳 Docker

You can also run the server with Docker:

```bash
docker build . -t telling-backend
docker run -it -p 8080:8080 telling-backend
```
