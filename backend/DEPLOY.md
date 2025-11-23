# Deployment Guide for Telling Backend

## 1. Prerequisites
Install the Globe CLI:
```bash
dart pub global activate globe_cli
```

Login to your Globe account:
```bash
globe login
```

## 2. Deploying to Globe
Run the deploy command from the `backend` directory:
```bash
globe deploy
```
Globe will detect your `Dockerfile` and build your application.

## 3. Database & Persistence (CRITICAL)
Your application currently uses **SQLite** (`telling.db`), which saves data to a local file.

**⚠️ IMPORTANT:** On serverless platforms like Globe, the file system is **ephemeral**. This means:
- Every time you redeploy, your database is reset.
- If the server restarts, your data might be lost.

### Option A: Use a Globe Volume (For Persistence with SQLite)
If you want to keep using SQLite, you must create a persistent volume.
1. Create a volume:
   ```bash
   globe volume create telling-data
   ```
2. Configure your deployment to mount this volume to `/app/data` (or wherever you want).
3. Update `lib/db/database.dart` to look for the DB in that mounted path if needed, or mount it to where the app expects it.
   * Currently, the app expects `telling.db` in the current working directory (`/app/bin/` or `/app/`).
   * You might need to update the `init` call in `bin/server.dart` to use a path from an environment variable like `DB_PATH`.

### Option B: Use a Hosted Database (Recommended for Production)
Switch to a hosted PostgreSQL database (e.g., Supabase, Neon, Railway).
1. Create a project on Supabase.
2. Get the connection string.
3. Update the backend code to use the `postgres` package instead of `sqlite3`.
4. Set the connection string as a secret in Globe:
   ```bash
   globe secret set DATABASE_URL=postgresql://...
   ```

## 4. Recent Changes
I have made the following changes to prepare your app for deployment:
- **`bin/server.dart`**: Updated to listen on `0.0.0.0` (required for Docker) and use the `PORT` environment variable.
- **`Dockerfile`**: Switched to `debian:stable-slim` to ensure the `sqlite3` library is available.
- **`.dockerignore`**: Added `telling.db` so you don't accidentally deploy your local test data.
