# SkinIntel Backend MySQL Integration

## Quick Start

1. From `backend/`, copy `.env.example` to `.env` and fill in these values:
   - `SECRET_KEY` = any random string
   - `JWT_SECRET_KEY` = any random string
   - `DATABASE_URL` = `mysql+pymysql://root:yourpassword@localhost:3306/Skinintelli`
   - leave `MAIL_SERVER`, `MAIL_USERNAME`, and `MAIL_PASSWORD` empty for local development
2. Install dependencies:
   ```powershell
   pip install -r requirements.txt
   ```
3. Run the backend:
   ```powershell
   python main.py
   ```
   Or use the helper scripts on your platform:
   - Windows: `run.bat`
   - macOS/Linux: `run.sh`
4. Confirm the API is running by opening:
   ```text
   http://127.0.0.1:5000/
   ```
   You should see:
   ```json
   {"status": "SkinIntel API running"}
   ```

## Setup

1. Copy `.env.example` to `.env` and fill in your credentials:
   ```powershell
   Copy-Item .env.example .env
   ```
2. Edit `.env` with your values — at minimum set `SECRET_KEY`, `JWT_SECRET_KEY`, and `DATABASE_URL` pointing at your MySQL instance.
3. Install dependencies and create the database tables (this runs `db.create_all()` using the ORM models):
   ```powershell
   pip install -r requirements.txt
   python db_setup.py
   ```



## Skin Profiling Tables

### `users`
Existing table used by authentication and skin profile relationships.

Columns:
- `id` - integer primary key
- `full_name` - string
- `username` - string, unique
- `email` - string, unique
- `password_hash` - string
- `gender` - string
- `is_verified` - boolean
- `otp_code` - string
- `otp_expires_at` - datetime
- `skin_type` - string
- `skin_concerns` - JSON
- `allergies` - text
- `environment` - string
- `goals` - JSON
- `created_at` - datetime
- `updated_at` - datetime

### `skin_profiles`
New skin profiling table added for saved user profile submissions.

Columns:
- `id` - integer primary key
- `user_id` - foreign key to `users.id`
- `skin_type` - string
- `skin_concerns` - JSON
- `allergies` - text
- `environment` - string
- `goals` - JSON
- `created_at` - datetime
- `updated_at` - datetime

Relationships:
- `users.skin_profiles` (one-to-many)
- `skin_profiles.user` (many-to-one)

## MySQL Integration

The backend uses SQLAlchemy and can connect to MySQL via a standard database URL.

### Required dependency
- `PyMySQL` is already listed in `backend/requirements.txt`

### Set the connection URL
Use one of these environment variables:
- `DATABASE_URL`
- `DEV_DATABASE_URL`

Example MySQL URL (use this format in `.env`):

```text
mysql+pymysql://root:yourpassword@localhost:3306/Skinintelli
```

### Create the tables
From `backend/`:

```powershell
pip install -r requirements.txt
python db_setup.py
```

This runs `create_app()` and executes `db.create_all()`, which creates the backend ORM tables on your MySQL database without dropping existing tables. If your Workbench database already contains additional tables for your own features, they will remain intact.

### Safe migration script
If you want to create the full SkinIntelli schema from `backend/.env`, use the safe migration script:

```powershell
pip install -r requirements.txt
python skinintelli_migrate.py
```

The script reads your `backend/.env` credentials, creates the `Skinintelli` database if needed, and only adds missing tables and indexes. Existing tables are not modified.

## Optional: create the schema directly in MySQL

A SQL script is available at `backend/mysql_skinintelli_schema.sql`.

This file now contains a full SkinIntelli database model with all tables, relationships, and indexes.

To apply it in MySQL Workbench or another client:

```sql
SOURCE backend/mysql_skinintelli_schema.sql;
```

Or from PowerShell:

```powershell
mysql -u root -p < backend\mysql_skinintelli_schema.sql
```

If you want to preserve existing data and existing WordPress tables, use a MySQL client to execute the script manually. The script uses `CREATE TABLE IF NOT EXISTS` so it will not overwrite existing tables with the same names.

## API integration

The skin profiling module is registered in `backend/main.py` with the `skin_profile_bp` blueprint.

Routes:
- `POST /api/skin-profile` - submit a new skin profile
- `GET /api/skin-profile` - read the latest profile for the current user
- `GET /api/skin-profile/history` - list all saved profiles for the current user
