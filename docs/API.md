# API reference

Base path: `/api`. Every endpoint except the OAuth flow requires the header:

```
Authorization: Bearer <session-token>
```

Responses are JSON. Errors look like `{"detail": "..."}`.

**Context:** Weeks and the shopping list depend on the user's *active context*, which is either their private space or one of their families (see `PUT /api/context`).

## Auth

| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/auth/google/login` | Redirects to Google OAuth. Add `?platform=ios` for the native app. |
| GET | `/api/auth/google/callback` | OAuth callback. Checks access, creates a session and redirects with `?token=…` (to `weekbite://auth` on iOS). |
| GET | `/api/auth/me` | Current user, their families, pending invites and active context |

Access is granted to verified Google accounts in the `allowed_emails` table and to anyone with a pending family invite. Everyone else gets `403`.

## Families

| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/families` | Families the user belongs to, with their members |
| POST | `/api/families` | Create a family. The creator becomes its first member. |
| PUT | `/api/families/{id}` | Rename (creator only) |
| DELETE | `/api/families/{id}` | Delete the family and its weeks and shopping list (creator only) |
| POST | `/api/families/{id}/invite` | Invite someone by email (members only) |
| POST | `/api/families/invites/{id}/accept` | Accept an invite addressed to you |
| POST | `/api/families/invites/{id}/decline` | Decline an invite addressed to you |
| DELETE | `/api/families/{id}/members/{user_id}` | Leave, or remove a member (creator only) |

## Context

| Method | Endpoint | Description |
|---|---|---|
| PUT | `/api/context` | `{"family_id": 3}` switches to a family, `{"family_id": null}` to private |

## Menus

Menus belong to a single user. In a family context, the list includes the menus of every family member, marked with `is_own` and `owner_name`.

| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/menus` | List menus, sorted by title |
| GET | `/api/menus/{id}` | Get one of your menus |
| POST | `/api/menus` | Create a menu (titles must be unique per user) |
| PUT | `/api/menus/{id}` | Update one of your menus |
| DELETE | `/api/menus/{id}` | Delete one of your menus. It is also removed from any planned days. |

```json
{ "title": "Lasagne", "ingredients": ["Pasta", "Tomatoes"], "note": "", "effort_min": 60, "link": "https://…" }
```

## Weeks

| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/week?date_param=YYYY-MM-DD` | The week containing that date (default: today). The current week is created on first access. |
| GET | `/api/week/next-exists` | Whether next week has been created yet |
| POST | `/api/week/next` | Create next week (`409` if it already exists) |
| PUT | `/api/week/{week_id}/{day}` | Assign a menu to a day: `{"menu_id": 12}`, or `null` to clear it |
| DELETE | `/api/week/{week_id}` | Clear all days of a week |

`day` is the German weekday name (`Montag` … `Sonntag`). A private week accepts only your own menus. A family week accepts menus of any family member.

## Shopping list

| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/shopping` | Items in the active context |
| POST | `/api/shopping` | Add an item. If the name already exists (ignoring case), the existing item is returned with `"created": false`. |
| PUT | `/api/shopping/{id}` | Update name and quantity |
| PATCH | `/api/shopping/{id}/toggle` | Toggle the "bought" state |
| DELETE | `/api/shopping/{id}` | Delete an item |
| DELETE | `/api/shopping` | Clear the list of the active context |

## Admin

Only available to the user whose email matches `ADMIN_EMAIL`.

| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/admin/members` | List allowed emails |
| POST | `/api/admin/members` | Allow an email: `{"email": "…"}` |
| DELETE | `/api/admin/members/{id}` | Revoke access. Existing sessions stop working immediately. |
