# Driver Portal Backend

## Overview

- **Driver role** is supported in `main_login`: drivers log in via `POST /api/auth/role-login/` with `{ "email", "password", "role": "driver" }`.
- **Driver profile** is in `management_admin`: model `Driver` links a User (driver role) to an optional assigned `Bus`.
- **Driver APIs** are under `POST /api/driver/` and require an authenticated driver with an assigned bus.

## Setup

1. **Run migrations**
   - `python manage.py migrate main_login`   (creates `driver` role if missing)
   - `python manage.py migrate management_admin` (creates `Driver` model and `BusStop.notes`)

2. **Create a driver user**
   - Option A: `python manage.py create_dummy_users` (creates `driver@school.com` / `driver123` with driver role).
   - Option B: In Django admin, create a User with role "Driver", then in Management Admin → Drivers create a Driver linking that user to a Bus.

3. **Assign bus to driver**
   - In Django admin: **Management Admin → Drivers** → edit the driver and set **Bus** to the bus they drive.

## Driver API Endpoints (all require `Authorization: Bearer <access_token>`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/driver/route/` | Assigned bus and route (morning/afternoon stops). Returns 403 if no bus assigned. |
| GET | `/api/driver/stops/?route_type=morning\|afternoon\|all` | Stops with students for tracking. |
| PATCH | `/api/driver/stops/<stop_id>/` | Update stop notes. Body: `{ "notes": "string" }`. |
| POST | `/api/driver/ride/start/` | Start ride (stub: returns success). |
| POST | `/api/driver/ride/end/` | End ride (stub: returns success). |

## Frontend (Driver portal app)

- Login uses `POST /api/auth/role-login/` with `role: 'driver'`.
- Default API base URL is `http://10.0.2.2:8000` (Android emulator). Override with `--dart-define=API_BASE_URL=http://your-server:8000` when building.
