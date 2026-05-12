#!/usr/bin/env bash
# DocSync — local Docker build + run helper (Sprint #3 · Assignment 4.15 / PR9)
# Re-runnable: removes any existing container named docsync-local before starting.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE_TAG="docsync:local"
CONTAINER_NAME="docsync-local"
HOST_PORT="${HOST_PORT:-3000}"

cd "$ROOT"

echo "══════════════════════════════════════════════════════════════"
echo "  DocSync — local Docker build & run"
echo "══════════════════════════════════════════════════════════════"
echo "  Repository: $ROOT"
echo "  Image:      $IMAGE_TAG"
echo "  Container:  $CONTAINER_NAME"
echo "  Port map:   ${HOST_PORT}:3000"
echo "══════════════════════════════════════════════════════════════"

if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
  echo "[info] Removing existing container '$CONTAINER_NAME' …"
  docker rm -f "$CONTAINER_NAME"
else
  echo "[info] No existing container named '$CONTAINER_NAME'."
fi

echo "[step] Building image '$IMAGE_TAG' …"
docker build -t "$IMAGE_TAG" .

echo "[step] Starting detached container '$CONTAINER_NAME' …"
docker run -d --name "$CONTAINER_NAME" -p "${HOST_PORT}:3000" "$IMAGE_TAG"

echo "[step] Container status:"
docker ps --filter "name=^${CONTAINER_NAME}$" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo "══════════════════════════════════════════════════════════════"
echo "  OK — DocSync should be listening on http://localhost:${HOST_PORT}"
echo "  Health check:"
echo "    curl -sSf http://localhost:${HOST_PORT}/health"
echo "  Logs:"
echo "    docker logs -f $CONTAINER_NAME"
echo "  Stop & remove:"
echo "    docker stop $CONTAINER_NAME && docker rm $CONTAINER_NAME"
echo "══════════════════════════════════════════════════════════════"
