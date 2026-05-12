#!/usr/bin/env bash
# DocSync — read-only container diagnostics (Sprint #3 · Assignment 4.15 / PR10)
# Safe to run repeatedly: does NOT stop, remove, or modify the container.

set -uo pipefail

CONTAINER_NAME="${CONTAINER_NAME:-docsync-local}"
HOST_PORT="${HOST_PORT:-3000}"

banner() {
  echo ""
  echo "══════════════════════════════════════════════════════════════"
  echo "  $*"
  echo "══════════════════════════════════════════════════════════════"
}

banner "DocSync debug check (read-only) — container: ${CONTAINER_NAME}"

if ! docker container inspect "$CONTAINER_NAME" &>/dev/null; then
  echo "[info] No container named '${CONTAINER_NAME}' exists on this Docker host."
  banner "Running containers (docker ps)"
  docker ps
  banner "Recent containers (docker ps -a, first 15 lines)"
  docker ps -a --no-trunc 2>/dev/null | head -n 15 || docker ps -a | head -n 15
  echo ""
  echo "[hint] Start one with: ./scripts/docker-local-run.sh"
  exit 0
fi

banner "docker ps — filter ${CONTAINER_NAME}"
docker ps -a --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

banner "Inspect — state & exit code"
docker inspect "$CONTAINER_NAME" --format \
  "Status={{.State.Status}}  Running={{.State.Running}}  ExitCode={{.State.ExitCode}}  OOMKilled={{.State.OOMKilled}}  Error={{.State.Error}}"

banner "Inspect — health (if defined)"
# Health block exists for Dockerfile HEALTHCHECK; may be empty on very old images.
docker inspect "$CONTAINER_NAME" --format '{{if .State.Health}}Health={{.State.Health.Status}} (FailingStreak={{.State.Health.FailingStreak}}){{else}}Health=(not reported — image may lack HEALTHCHECK){{end}}' 2>/dev/null || echo "Health=(inspect format unsupported)"

banner "Inspect — config excerpt (User, Cmd)"
docker inspect "$CONTAINER_NAME" --format 'User={{.Config.User}}  Cmd={{json .Config.Cmd}}  Image={{.Config.Image}}'

banner "Recent logs (last 80 lines): docker logs ${CONTAINER_NAME}"
docker logs --tail 80 "$CONTAINER_NAME" 2>&1

if docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
  banner "Host curl — http://localhost:${HOST_PORT}/health"
  if curl -sS -m 5 "http://localhost:${HOST_PORT}/health"; then
    echo ""
  else
    echo ""
    echo "[warn] curl failed — check port mapping (-p) and HOST_PORT (current ${HOST_PORT})."
  fi

  banner "In-container probe (non-interactive): wget /health"
  if docker exec "$CONTAINER_NAME" wget -qO- "http://127.0.0.1:3000/health" 2>/dev/null; then
    echo ""
  else
    echo "[warn] docker exec wget probe failed (wget missing or app not listening)."
  fi

  banner "Process identity inside container: docker exec ${CONTAINER_NAME} id"
  docker exec "$CONTAINER_NAME" id 2>/dev/null || echo "[warn] docker exec id failed."
else
  echo ""
  echo "[info] Container exists but is NOT running — skipped host curl and docker exec probes."
  echo "        Try: docker start ${CONTAINER_NAME}   OR   inspect exit logs above."
fi

banner "Done — no stop/rm/start was performed."
