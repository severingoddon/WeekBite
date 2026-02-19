#!/bin/bash
set -e

cd ~/WeekBite/WeekBite

echo "==> Pulling latest code..."
git pull

echo "==> Stopping containers..."
docker compose down

echo "==> Removing all images..."
docker rmi $(docker images -q) 2>/dev/null || true

echo "==> Removing all volumes..."
docker volume rm $(docker volume ls -q) 2>/dev/null || true

echo "==> Building from scratch..."
docker compose build --no-cache

echo "==> Starting containers..."
docker compose up -d

echo "==> Waiting for startup..."
sleep 5

echo "==> Backend logs:"
docker logs weekbite-backend --tail 20

echo "==> Done!"
