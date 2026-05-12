# =============================================================================
# DocSync — optimized production image (Sprint #3 · Assignment 4.14 · PR8)
# =============================================================================
# Multi-stage Dockerfile:
#   • builder — installs locked production dependencies + copies application src
#   • final   — minimal runtime: only node_modules + src + manifests (no npm
#               cache, no devDependencies, no repo docs/tests in the context)
#
# Design goals: layer cache efficiency, smaller attack surface, non-root
# runtime, and a HEALTHCHECK aligned with Kubernetes readiness patterns.
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1 — builder (same Node line as production for native ABI consistency)
# -----------------------------------------------------------------------------
FROM node:20-alpine AS builder

WORKDIR /app

# Copy lockfiles before source so `npm ci` layer stays cached when only src/
# changes (Docker reuses layers when instruction + inputs are unchanged).
COPY package.json package-lock.json ./

# Strict, reproducible install from package-lock.json; omit devDependencies
# (e.g. ESLint) so the runtime image does not ship editor/lint tooling.
RUN npm ci --omit=dev

COPY src/ ./src/

# -----------------------------------------------------------------------------
# Stage 2 — production runtime (minimal filesystem + non-root + health probe)
# -----------------------------------------------------------------------------
FROM node:20-alpine

# wget: used only by HEALTHCHECK (explicit apk keeps behavior stable across
#     minimal base image updates). adduser/addgroup: dedicated UID/GID 1001.
RUN apk add --no-cache wget \
  && addgroup -g 1001 -S appgroup \
  && adduser -S -u 1001 -G appgroup appuser

WORKDIR /app

# Copy artifacts from builder — final image has no package manager metadata
# cache beyond node_modules produced by npm ci.
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/src ./src
COPY --from=builder /app/package.json /app/package-lock.json ./

# Ensure app files are owned by the runtime user (read/execute for Node).
RUN chown -R appuser:appgroup /app

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

USER appuser

# Orchestrator-friendly liveness/readiness style probe (same path as k8s).
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:3000/health || exit 1

CMD ["node", "src/server.js"]
