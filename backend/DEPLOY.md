# Deployment Guide for Telling Backend

## 1. Deploy to Globe
Run the deploy command:
```bash
cd backend
globe deploy
```

Follow the prompts to create your project (e.g., name it `telling-backend`).

## 2. Database Persistence
Your backend uses SQLite with the `sqlite_async` package.

> [!IMPORTANT]
> **Data Persistence**: By default, the database file will be stored in the container's filesystem. Data will persist across restarts but will be reset on redeployment. 
>
> To enable permanent persistence, add a **Volume** in the Globe Dashboard:
> 1. Go to your project Settings → Volumes
> 2. Create a volume mounted to `/data`
> 3. The `DB_PATH` environment variable (already set in `globe.yaml`) will use `/data/telling.db`

## 3. Environment Variables
The `globe.yaml` file already configures:
- `DB_PATH=/data/telling.db` (uses volume if mounted, otherwise uses container filesystem)

## 4. Future: PostgreSQL Migration
For production scale, consider migrating to PostgreSQL:
1. Get a connection string from Supabase or Neon
2. Set `DATABASE_URL` in Globe secrets
3. Update code to use `postgres` package

## 4. Future: Switching to Postgres
When you are ready to scale, we can switch to a hosted PostgreSQL database.
1.  Get a Postgres connection string (e.g., from Supabase).
2.  Update `globe.yaml` or Dashboard secrets with `DATABASE_URL`.
3.  We will need to update the code to use `postgres` package.
