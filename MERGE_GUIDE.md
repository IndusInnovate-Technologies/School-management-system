# Project Merge & Synchronization Guide

This guide ensures that when you merge code from another branch, your Frontend, Backend, and Database connections all stay in sync correctly.

## 🚀 Post-Merge Workflow

Every time you finish a `git merge` or pull updates from another branch, follow these steps:

### 1. Synchronize the Project
Run the automated sync script from the project root:
```powershell
.\sync_project.ps1
```
This script will:
- Check for your `.env` configuration.
- Automatically run Django migrations to update your database schema.
- Run `flutter pub get` across all apps to update frontend dependencies.

### 2. Check Backend Connections (`.env`)
The `.env` file contains your database credentials and is **ignored by Git** (so it doesn't get overwritten or leaked).
- If your backend connection fails after a merge, compare your `backend/.env` with `backend/.env.example`.
- Ensure `SUPABASE_DB_PASSWORD` and other credentials are correct.

### 3. Verify Database State
If you see errors related to missing columns or tables after a merge:
1. Ensure the backend server is stopped.
2. Run `.\sync_project.ps1` again.
3. If issues persist, check the `backend/debug.log` for migration errors.

## 🛠 Troubleshooting Common Merge Issues

### Frontend merges but Backend doesn't work
- **Cause**: The merge included new database models but you didn't run migrations.
- **Fix**: Run `.\sync_project.ps1`.

### "Error: Couldn't resolve the package" in Flutter
- **Cause**: New dependencies were added in the other branch.
- **Fix**: Run `.\sync_project.ps1` or manually run `flutter pub get` in the relevant app folder.

### 401 Unauthorized Errors
- **Cause**: Backend permissions or authentication logic changed.
- **Fix**: Ensure your `SECRET_KEY` in `.env` matches your environment and that you have cleared your browser local storage/run `flutter clean` if necessary.

---
**Tip**: Always keep your `backend/.env.example` updated if you add new environment variables to `settings.py`.
