# WeekBite

A weekly meal planning application. Assign menus to weekdays, archive past weeks and plan ahead.

## Features

- **Weekly planner** — 7 weekdays displayed vertically; tap a day to open a fullscreen menu picker and assign a meal
- **Menu picker** — scrollable fullscreen popup showing all available menus; tap to assign, detail button to view ingredients
- **Menu management** — create, edit and delete menus with title and ingredients via a form
- **Week archiving** — browse past and future weeks via a datepicker; date range displayed in the header
- **Auto-creation** — the current week is created automatically on first visit each Monday
- **Next week** — create next week in advance or navigate to it if it already exists
- **Week reset** — clear all assigned menus of the displayed week (confirmation dialog)
- **CSV export** — download all menus as a semicolon-separated CSV file (desktop only)
- **CSV import** — import menus from a CSV file with structure validation and user-friendly error messages (desktop only)
- **Google OAuth** — login via Google account, avatar with email display and logout
- **Persistence** — all data (menus, weeks, assignments) stored in SQLite and survives page reloads
- **Mobile first** — touch-optimized, responsive layout that scales up on desktop
- **Dark mode** — Angular Material dark theme throughout

## Tech Stack

| Layer    | Technology                                        |
|----------|---------------------------------------------------|
| Frontend | Angular 19, Angular Material, Material Datepicker, SCSS |
| Backend  | Python 3.12, FastAPI, SQLAlchemy, Pydantic, Authlib |
| Database | SQLite                                            |
| Server   | Nginx (reverse proxy), Uvicorn                    |
| Docker   | Docker Compose, multi-stage builds                |

## Getting Started

### Local Development

**Backend:**
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0
```

Create a `.env` file in `backend/` with your Google OAuth credentials:
```
GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-client-secret
ALLOWED_ORIGINS=http://localhost:4200
FRONTEND_URL=http://localhost:4200
SESSION_SECRET=some-random-secret
```

Backend API runs at `http://localhost:8000/api`.

**Frontend:**
```bash
cd frontend
npm install
ng serve
```

Frontend runs at `http://localhost:4200`.

> The Angular dev server proxies `/api` requests to the backend automatically (see `proxy.conf.json` if configured, otherwise set `ALLOWED_ORIGINS` accordingly).

### Docker

```bash
docker-compose up --build
```

App available on port `80`, API on port `8000`.

## API Endpoints

### Menus

| Method | Endpoint          | Description    |
|--------|-------------------|----------------|
| GET    | `/api/menus`      | List all menus |
| POST   | `/api/menus`      | Create a menu  |
| PUT    | `/api/menus/{id}` | Update a menu  |
| DELETE | `/api/menus/{id}` | Delete a menu  |

### Auth

| Method | Endpoint                     | Description                                      |
|--------|------------------------------|--------------------------------------------------|
| GET    | `/api/auth/google/login`     | Redirect to Google OAuth consent screen          |
| GET    | `/api/auth/google/callback`  | OAuth callback, creates session, redirects with token |
| GET    | `/api/auth/me`               | Get current user info (email, name, avatar)      |

All other endpoints require `Authorization: Bearer <token>` header.

### Weeks

| Method | Endpoint                          | Description                               |
|--------|-----------------------------------|-------------------------------------------|
| GET    | `/api/week?date_param=YYYY-MM-DD` | Get week containing date (default: today) |
| GET    | `/api/week/next-exists`           | Check if next week exists                 |
| POST   | `/api/week/next`                  | Create next week                          |
| PUT    | `/api/week/{week_id}/{day}`       | Assign menu to a day in a week            |
| DELETE | `/api/week/{week_id}`             | Reset (clear) a specific week             |

@Author Severin Goddon, 2026
