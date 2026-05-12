#!/usr/bin/env bash
# DocSync — build + tag for GitHub Container Registry (GHCR) (Sprint #3 · PR11)
#
# Does NOT log in, push, or embed secrets. Run docker login / docker push manually
# using a short-lived PAT or CI-injected token (never commit .env or tokens).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TAG="${1:-local-dev}"
LOCAL_IMAGE="${LOCAL_IMAGE:-docsync:local}"
# Lowercase owner/repo is required for OCI registry references on Docker Engine.
GHCR_IMAGE="${GHCR_IMAGE:-ghcr.io/kalviumcommunity/s59-0426-alpha-devops-k8s-cicd-docsync-system}"

FULL_TAG="${GHCR_IMAGE}:${TAG}"

banner() {
  echo ""
  echo "══════════════════════════════════════════════════════════════"
  echo "  $*"
  echo "══════════════════════════════════════════════════════════════"
}

banner "Build local image: ${LOCAL_IMAGE}"
docker build -t "${LOCAL_IMAGE}" .

banner "Tag for GHCR: ${FULL_TAG}"
docker tag "${LOCAL_IMAGE}" "${FULL_TAG}"

banner "Tagged successfully"
echo "Recent images (top):"
docker images | head -n 15

echo ""
echo "Next steps — run manually (placeholders only; do not paste real tokens into git):"
echo ""
echo "  1) Authenticate (PAT needs at least: write:packages, read:packages):"
echo "       echo \"\${GHCR_TOKEN}\" | docker login ghcr.io -u <GITHUB_USERNAME> --password-stdin"
echo "     # or interactively (not for screenshots with secrets visible):"
echo "       docker login ghcr.io -u <GITHUB_USERNAME>"
echo ""
echo "  2) Push the tag you just created:"
echo "       docker push ${FULL_TAG}"
echo ""
echo "  3) Confirm in GitHub → your org/repo → Packages (container)."
echo ""
echo "  4) Pull on another host (after logging in if private):"
echo "       docker pull ${FULL_TAG}"
echo ""
echo "Override examples:"
echo "  ./scripts/docker-tag-ghcr.sh rc1                         # custom tag (positional arg)"
echo "  GHCR_IMAGE=ghcr.io/<owner>/<image> ./scripts/docker-tag-ghcr.sh rc1"
echo ""
