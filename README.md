# WeekBite

A weekly meal planning application. Assign menus to weekdays, archive past weeks and plan ahead. Share weekly plans and shopping lists with your family.

## Features

- **Weekly planner** — 7 weekdays displayed vertically; tap a day to open a fullscreen menu picker and assign a meal
- **Menu picker** — scrollable fullscreen popup showing all available menus; tap to assign, detail button to view ingredients
- **Menu management** — create, edit and delete menus with title and ingredients via a form (personal per user)
- **Shopping list** — add items manually or from recipe ingredients; toggle bought status; clear list
- **Families** — create groups ("Familien"), invite members by email, share weekly plans and shopping lists within a family
- **Context switcher** — toolbar chip to switch between "Privat" (personal) and family contexts; all data (weeks, shopping) follows the active context
- **Auto-join on invite** — invited users are automatically added to the family on their next login
- **Week archiving** — browse past and future weeks via a datepicker; date range displayed in the header
- **Auto-creation** — the current week is created automatically on first visit each Monday
- **Next week** — create next week in advance or navigate to it if it already exists
- **Week reset** — clear all assigned menus of the displayed week via three-dot menu (confirmation dialog)
- **CSV export** — download all menus as a semicolon-separated CSV file (desktop only)
- **CSV import** — import menus from a CSV file with structure validation and user-friendly error messages (desktop only)
- **Google OAuth** — login via Google account, avatar with email display and logout
- **Open registration** — anyone with a Google account can sign up (no invite required)
- **Persistence** — all data (menus, weeks, assignments, shopping lists) stored in SQLite and survives page reloads
- **Mobile first** — touch-optimized, responsive layout that scales up on desktop
- **Dark mode** — Angular Material dark theme throughout

## Clients

The app has two frontends that share the same backend:

- **Web App** (`frontend/`) — Angular 19 SPA, served via Nginx, runs in browser
- **iOS App** (`SwiftApp/`) — Native SwiftUI app for iPhone (iOS 17+)

Both clients are feature-equivalent: week plan, menu management, shopping list, families, context switching, Google OAuth.

## Tech Stack

| Layer    | Technology                                        |
|----------|---------------------------------------------------|
| Web      | Angular 19, Angular Material, Material Datepicker, SCSS |
| iOS      | SwiftUI, Observation (`@Observable`), async/await, zero dependencies |
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

Create a `.env` file in `backend/` with your configuration:
```
GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-client-secret
ADMIN_EMAIL=your-admin@example.com
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

**iOS App:**

Requires Xcode 16+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
cd SwiftApp
xcodegen generate
open WeekBite.xcodeproj
```

In Xcode, select your development team under **Signing & Capabilities**, then build to a simulator or device.

The API base URL is configured in `SwiftApp/WeekBite/Network/APIEndpoints.swift`. For local development, change it to `http://localhost:8000`. For production it points to `https://weekbite.goddoni.org:3003`.

The iOS OAuth flow uses `ASWebAuthenticationSession` with the `weekbite://` URL scheme. The backend detects `?platform=ios` on the login endpoint and redirects the OAuth callback to `weekbite://auth?token=...` instead of the web frontend.

### Docker (local)

```bash
docker-compose up --build
```

App available on port `80`, API on port `8000`.

### Deployment (Ansible → Raspberry Pi)

Prerequisites on your local machine:
- `ansible` installed (`pip install ansible`)
- `community.docker` collection: `ansible-galaxy collection install community.docker`
- SSH key on the Raspi: `ssh-copy-id pi@192.168.1.51`
- Key loaded in agent (if passphrase): `ssh-add ~/.ssh/id_ed25519`

Deploy:
```bash
ansible-playbook ansible/deploy.yml -i ansible/inventory.ini
```

This will pull the latest code on the Raspi, rebuild all Docker images from scratch, and restart the containers.

## API Endpoints

### Auth

| Method | Endpoint                     | Description                                      |
|--------|------------------------------|--------------------------------------------------|
| GET    | `/api/auth/google/login`     | Redirect to Google OAuth consent screen (`?platform=ios` for native app) |
| GET    | `/api/auth/google/callback`  | OAuth callback, creates session, redirects with token |
| GET    | `/api/auth/me`               | Get current user info (email, name, avatar, families, active context) |

All other endpoints require `Authorization: Bearer <token>` header.

### Families

| Method | Endpoint                                | Description                              |
|--------|-----------------------------------------|------------------------------------------|
| GET    | `/api/families`                         | List families the user belongs to        |
| POST   | `/api/families`                         | Create a new family (creator = member)   |
| PUT    | `/api/families/{id}`                    | Rename a family (creator only)           |
| DELETE | `/api/families/{id}`                    | Delete a family (creator only)           |
| POST   | `/api/families/{id}/invite`             | Invite a member by email                 |
| DELETE | `/api/families/{id}/members/{user_id}`  | Remove a member or leave the family      |

### Context

| Method | Endpoint       | Description                                          |
|--------|----------------|------------------------------------------------------|
| PUT    | `/api/context`  | Switch active context (`family_id: null` = private)  |

### Menus (personal per user)

| Method | Endpoint          | Description           |
|--------|-------------------|-----------------------|
| GET    | `/api/menus`      | List user's menus     |
| POST   | `/api/menus`      | Create a menu         |
| PUT    | `/api/menus/{id}` | Update a menu         |
| DELETE | `/api/menus/{id}` | Delete a menu         |

### Weeks (scoped by active context)

| Method | Endpoint                          | Description                               |
|--------|-----------------------------------|-------------------------------------------|
| GET    | `/api/week?date_param=YYYY-MM-DD` | Get week containing date (default: today) |
| GET    | `/api/week/next-exists`           | Check if next week exists                 |
| POST   | `/api/week/next`                  | Create next week                          |
| PUT    | `/api/week/{week_id}/{day}`       | Assign menu to a day in a week            |
| DELETE | `/api/week/{week_id}`             | Reset (clear) a specific week             |

### Shopping List (scoped by active context)

| Method | Endpoint                          | Description                     |
|--------|-----------------------------------|---------------------------------|
| GET    | `/api/shopping`                   | List shopping items             |
| POST   | `/api/shopping`                   | Add a shopping item             |
| PUT    | `/api/shopping/{id}`              | Update a shopping item          |
| PATCH  | `/api/shopping/{id}/toggle`       | Toggle bought status            |
| DELETE | `/api/shopping/{id}`              | Delete a shopping item          |
| DELETE | `/api/shopping`                   | Clear all shopping items        |

@Author Severin Goddon, 2026
