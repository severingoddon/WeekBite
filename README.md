# WeekBite

A weekly meal planning application. Assign menus to weekdays and manage your recipes.

## Features

- **Weekly planner** — 7 weekdays displayed vertically; tap a day to open a fullscreen menu picker and assign a meal
- **Menu picker** — scrollable fullscreen popup showing all available menus; tap to assign, detail button to view ingredients
- **Menu management** — create, edit and delete menus with title and ingredients via a form
- **Week reset** — clear all assigned menus with a single button (confirmation dialog)
- **CSV export** — download all menus as a semicolon-separated CSV file (desktop only)
- **CSV import** — import menus from a CSV file with structure validation and error feedback (desktop only)
- **Persistence** — all data (menus, weekly assignments) stored in SQLite and survives page reloads
- **Mobile first** — touch-optimized, responsive layout that scales up on desktop
- **Dark mode** — Angular Material dark theme throughout

## Tech Stack

| Layer    | Technology                          |
|----------|-------------------------------------|
| Frontend | Angular 19, Angular Material, SCSS  |
| Backend  | Python 3.12, FastAPI, SQLAlchemy    |
| Database | SQLite                              |
| Server   | Nginx (reverse proxy), Uvicorn      |
| Docker   | Docker Compose, multi-stage builds  |

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

**Frontend:**
```bash
cd frontend
npm install
ng serve
```

Frontend: `http://localhost:4200` | Backend API: `http://localhost:8000/api`

### Docker

```bash
docker-compose up --build
```

App available on port `80`, API on port `8000`.

## API Endpoints

| Method | Endpoint             | Description              |
|--------|----------------------|--------------------------|
| GET    | `/api/menus`         | List all menus           |
| POST   | `/api/menus`         | Create a menu            |
| PUT    | `/api/menus/{id}`    | Update a menu            |
| DELETE | `/api/menus/{id}`    | Delete a menu            |
| GET    | `/api/week`          | Get weekly plan          |
| PUT    | `/api/week/{day}`    | Assign menu to a weekday |
| DELETE | `/api/week`          | Reset entire week        |

@Author Severin Goddon, 2026