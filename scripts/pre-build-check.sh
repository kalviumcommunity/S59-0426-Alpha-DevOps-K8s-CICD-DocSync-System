#!/usr/bin/env bash
# Pre-build environment validation script
# Ensures all required tools are available before attempting a Docker build.
# Portable — no hardcoded paths. Works on Linux, macOS, and CI runners.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

check() {
  local name="$1"
  local cmd="$2"
  local min_version="${3:-}"

  if command -v "$cmd" &>/dev/null; then
    local version
    version=$("$cmd" --version 2>/dev/null | head -n1) || version="(version unknown)"
    echo -e "  ${GREEN}✔${NC} $name found: $version"
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}✘${NC} $name not found — install '$cmd' before proceeding"
    FAIL=$((FAIL + 1))
  fi
}

check_docker_running() {
  if docker info &>/dev/null; then
    echo -e "  ${GREEN}✔${NC} Docker daemon is running"
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}✘${NC} Docker is installed but the daemon is not running"
    echo -e "     ${YELLOW}→${NC} Start Docker Desktop or run 'sudo systemctl start docker'"
    FAIL=$((FAIL + 1))
  fi
}

check_dockerfile() {
  if [ -f "Dockerfile" ]; then
    echo -e "  ${GREEN}✔${NC} Dockerfile found in project root"
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}✘${NC} No Dockerfile found — cannot build image"
    FAIL=$((FAIL + 1))
  fi
}

check_package_json() {
  if [ -f "package.json" ]; then
    local name version
    name=$(node -e "console.log(require('./package.json').name)" 2>/dev/null) || name="unknown"
    version=$(node -e "console.log(require('./package.json').version)" 2>/dev/null) || version="unknown"
    echo -e "  ${GREEN}✔${NC} package.json found — $name@$version"
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}✘${NC} No package.json found — cannot install dependencies"
    FAIL=$((FAIL + 1))
  fi
}

check_tests_exist() {
  if ls tests/*.test.js &>/dev/null || ls tests/*.spec.js &>/dev/null; then
    local count
    count=$(ls tests/*.test.js tests/*.spec.js 2>/dev/null | wc -l)
    echo -e "  ${GREEN}✔${NC} Found $count test file(s) in tests/"
    PASS=$((PASS + 1))
  else
    echo -e "  ${YELLOW}⚠${NC} No test files found in tests/ — pipeline will have nothing to validate"
    FAIL=$((FAIL + 1))
  fi
}

echo ""
echo "═══════════════════════════════════════════"
echo "  DocSync Pre-Build Environment Check"
echo "═══════════════════════════════════════════"
echo ""

echo "Checking required tools..."
check "Node.js" "node"
check "npm" "npm"
check "Docker" "docker"
check "Git" "git"

echo ""
echo "Checking Docker daemon..."
check_docker_running

echo ""
echo "Checking project files..."
check_dockerfile
check_package_json
check_tests_exist

echo ""
echo "═══════════════════════════════════════════"
if [ "$FAIL" -gt 0 ]; then
  echo -e "  ${RED}RESULT: $FAIL check(s) failed, $PASS passed${NC}"
  echo -e "  Fix the issues above before building."
  echo "═══════════════════════════════════════════"
  exit 1
else
  echo -e "  ${GREEN}RESULT: All $PASS checks passed${NC}"
  echo -e "  Environment is ready for build."
  echo "═══════════════════════════════════════════"
  exit 0
fi
