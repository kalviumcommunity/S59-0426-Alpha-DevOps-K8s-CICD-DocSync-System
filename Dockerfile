# =============================================================================
# DocSync — Node.js production image (Sprint #3 · Assignment 4.14)
# =============================================================================
# Single-stage build suitable for learning Dockerfile basics: base image,
# dependency install with a lockfile, application source, exposed port, and
# a production process command. Later sprints may reintroduce multi-stage
# builds, non-root users, and HEALTHCHECK for hardening.
# =============================================================================

# Official Node.js 20 runtime on Alpine Linux — small image, musl libc.
FROM node:20-alpine

# All following commands run relative to /app; keeps paths predictable.
WORKDIR /app

# Copy manifest files first so this layer can be cached when only src/ changes.
COPY package.json package-lock.json ./

# Reproducible install from lockfile; omit devDependencies for production image.
RUN npm ci --omit=dev

# Application entrypoint and modules (Express + WebSocket service).
COPY src/ ./src/

# Runtime configuration consumed by src/server.js.
ENV NODE_ENV=production
ENV PORT=3000

# Document the port the HTTP server listens on (see EXPOSE in Docker docs).
EXPOSE 3000

# Start the API/WebSocket server directly (matches package.json "start" script).
CMD ["node", "src/server.js"]
