# Deployment Guide for Telling Backend

## 1. Initial Deployment
Run the deploy command to create your project on Globe:
```bash
globe deploy
```
*   Follow the prompts to create a new project (e.g., name it `telling-backend`).
*   **Note:** This first deployment will use a temporary database. Any data created now will be lost until we set up the volume.

## 2. Set Up Persistence (Globe Volume)
Since the Globe CLI doesn't support volume management yet, you must do this in the dashboard.

1.  **Open Dashboard:** Go to [https://globe.dev/dashboard](https://globe.dev/dashboard) and open your new project.
2.  **Create Volume:**
    *   Navigate to **Settings** > **Volumes** (or similar storage section).
    *   Create a new volume.
    *   **Mount Path:** `/data`
    *   **Name:** `telling-data` (or any name you prefer).
3.  **Verify Environment Variable:**
    *   I have created a `globe.yaml` that sets `DB_PATH` to `/data/telling.db`.
    *   Check **Settings** > **Environment Variables** in the dashboard to ensure `DB_PATH` is set to `/data/telling.db`. If not, add it manually.

## 3. Redeploy
Once the volume is mounted and the environment variable is set:
```bash
globe deploy
```
Now your database will be stored in `/data/telling.db`, which lives on the persistent volume. Your users and logs will survive restarts and redeployments!

## 4. Future: Switching to Postgres
When you are ready to scale, we can switch to a hosted PostgreSQL database.
1.  Get a Postgres connection string (e.g., from Supabase).
2.  Update `globe.yaml` or Dashboard secrets with `DATABASE_URL`.
3.  We will need to update the code to use `postgres` package.
