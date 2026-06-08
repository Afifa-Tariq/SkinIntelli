# SkinIntel Backend MySQL Integration

## Setup

1. Copy `.env.example` to `.env` and fill in your credentials:
   ```powershell
   Copy-Item .env.example .env
   ```
2. Edit `.env` with your values — at minimum set `SECRET_KEY`, `JWT_SECRET_KEY`, and the mail credentials so OTP emails are delivered.
3. Install dependencies and create the database tables:
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

Example MySQL URL:

```text
mysql+pymysql://username:password@hostname:3306/skinintelli_db
```

### Create the tables
From `backend/`:

```powershell
pip install -r requirements.txt
python db_setup.py
```

This runs `create_app()` and executes `db.create_all()`, which creates the `users` and `skin_profiles` tables on your MySQL database.

## Optional: create the schema directly in MySQL

A SQL script is available at `backend/mysql_skinintelli_schema.sql`.

Run it from PowerShell:

```powershell
mysql -u username -p < mysql_skinintelli_schema.sql
```

Or open `backend/mysql_skinintelli_schema.sql` in your MySQL client and execute it manually.

## API integration

The skin profiling module is registered in `backend/main.py` with the `skin_profile_bp` blueprint.

Routes:
- `POST /api/skin-profile` - submit a new skin profile
- `GET /api/skin-profile` - read the latest profile for the current user
- `GET /api/skin-profile/history` - list all saved profiles for the current user
