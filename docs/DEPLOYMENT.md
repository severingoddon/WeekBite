# Deployment

In production WeekBite runs on a Raspberry Pi with Docker Compose. Deployments run from a Mac with Ansible, and the Pi is reachable from the internet through a Cloudflare Tunnel.

```
Clients ──HTTPS──▶ Cloudflare Tunnel ──▶ nginx (TLS, port 3003) ──┬─▶ Angular SPA (static files)
                                                                    └─▶ /api ──▶ FastAPI ──▶ SQLite (Docker volume)
```

The `frontend` image is a multi-stage build: Node builds the Angular app, and nginx serves it and proxies `/api` to the backend.

## Configuration

Two files hold the deployment-specific values. Both are gitignored:

| File | Template | Contents |
|---|---|---|
| `backend/.env` | `backend/.env.example` | OAuth credentials, `ALLOWED_EMAILS`, `ADMIN_EMAIL`, session secret, production URLs |
| `ansible/inventory.ini` | `ansible/inventory.example.ini` | The Pi's address and SSH user |

Also set your own domain in `SwiftApp/WeekBite/Network/APIEndpoints.swift` (`baseURL`).

## Prerequisites (local machine)

```bash
pip install ansible
ansible-galaxy collection install community.docker
ssh-copy-id pi@<RASPI_IP>
```

## First-time setup on the Pi

```bash
ssh pi@<RASPI_IP>
mkdir -p ~/WeekBite/Certs
cd ~/WeekBite
git clone https://github.com/severingoddon/WeekBite.git WeekBite
```

Copy the environment file, which is not in git:

```bash
scp backend/.env pi@<RASPI_IP>:~/WeekBite/WeekBite/backend/.env
```

On the very first deploy the database volume doesn't exist yet. Run it once with `-e first_deploy=true` to skip the volume check.

## Deploying

```bash
ansible-playbook ansible/deploy.yml -i ansible/inventory.ini
```

The playbook runs these steps in order:

1. Pulls the latest code on the Pi.
2. Aborts if the database volume `weekbite_db-data` is missing, so it never starts with an empty database by accident.
3. Backs up the SQLite database to `~/WeekBite/backups/`.
4. Stops this project's containers. Volumes are kept.
5. Removes and rebuilds only this project's images.
6. Checks that the backend has the database volume mounted again.

The Pi also runs other services, so the playbook never runs global `docker prune`, `docker rmi` or `docker volume rm` commands.

## TLS certificates

The certificates come from Let's Encrypt:

```bash
sudo certbot certonly --standalone -d <your-domain>
sudo cp /etc/letsencrypt/live/<your-domain>/{fullchain,privkey}.pem ~/WeekBite/Certs/
sudo chown pi:pi ~/WeekBite/Certs/*.pem
```

## Cloudflare Tunnel

The domain is published through a Cloudflare Tunnel that routes to `https://127.0.0.1:3003`. The tunnel only makes outbound connections, so the router needs no port forwarding.

## Access management

- `ALLOWED_EMAILS` and `ADMIN_EMAIL` are added to the `allowed_emails` table on every start. Entries are only added, never removed.
- To revoke access permanently, remove the email from `.env` and delete it via `DELETE /api/admin/members/{id}`.
- Anyone invited to a family can sign in and is added to the allowlist automatically.
