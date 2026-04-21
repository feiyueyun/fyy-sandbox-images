# ===========================================================================
# fyy-sandbox Base Image
# ===========================================================================
# Multi-stage build for the FYY Sandbox base image.
#
# Stage 1 (builder): Fetch and verify the fyy CLI binary
# Stage 2 (runtime): Minimal runtime with Python 3.12, Node.js 22, fyy CLI
#
# Build args:
#   FYY_VERSION    — fyy CLI version tag (e.g. v1.0.0). Default: latest
#   FYY_BINARY_URL — Custom download URL for fyy binary (overrides default)
#   TARGETARCH     — Target architecture: amd64 or arm64. Default: auto-detect
#   BUILD_MODE     — release or dev. Default: release
#
# Build modes:
#   release — download fyy binary from GitHub Releases (default)
#   dev     — use fyy binary from build context (dev-bin/fyy-linux-{arch})
#             The Makefile copies the binary from ../fyy-src before building.
# ===========================================================================

# ---------------------------------------------------------------------------
# Stage 1: Builder — fetch fyy CLI binary
# ---------------------------------------------------------------------------
FROM python:3.12-slim AS builder

ARG FYY_VERSION=latest
ARG FYY_BINARY_URL=""
ARG TARGETARCH=amd64
ARG BUILD_MODE=release

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# --- Dev mode: copy pre-built binary from build context ---
# For dev mode, the Makefile copies the binary to dev-bin/fyy before building.
# We use a .dockerignore-safe approach: copy the entire dev-bin directory.
COPY dev-bin/ /tmp/dev-bin/

# --- Fetch the binary ---
RUN set -e; \
    if [ "$BUILD_MODE" = "dev" ]; then \
      echo "==> Dev mode: using pre-built binary"; \
      if [ -f "/tmp/dev-bin/fyy-linux-${TARGETARCH}" ]; then \
        cp "/tmp/dev-bin/fyy-linux-${TARGETARCH}" /usr/local/bin/fyy; \
      elif [ -f "/tmp/dev-bin/fyy" ]; then \
        cp /tmp/dev-bin/fyy /usr/local/bin/fyy; \
      else \
        echo "ERROR: No dev binary found in dev-bin/. Run 'make dev-prepare' first." >&2; \
        exit 1; \
      fi; \
    else \
      BINARY_NAME="fyy-linux-${TARGETARCH}"; \
      if [ -n "$FYY_BINARY_URL" ]; then \
        DOWNLOAD_URL="$FYY_BINARY_URL"; \
      else \
        DOWNLOAD_URL="https://github.com/feiyueyun/fyy/releases/download/${FYY_VERSION}/${BINARY_NAME}"; \
      fi; \
      echo "==> Downloading fyy CLI from ${DOWNLOAD_URL}"; \
      HTTP_CODE=$(curl -fsSL -w '%{http_code}' -o /usr/local/bin/fyy "$DOWNLOAD_URL" 2>/dev/null) || { \
        echo "ERROR: Download failed. URL: ${DOWNLOAD_URL}, HTTP status: ${HTTP_CODE:-unknown}" >&2; \
        exit 1; \
      }; \
      SHA256_URL="${DOWNLOAD_URL}.sha256"; \
      if curl -fsSL -o /tmp/fyy.sha256 "$SHA256_URL" 2>/dev/null; then \
        EXPECTED=$(awk '{print $1}' /tmp/fyy.sha256); \
        ACTUAL=$(sha256sum /usr/local/bin/fyy | awk '{print $1}'); \
        if [ "$ACTUAL" != "$EXPECTED" ]; then \
          echo "ERROR: SHA256 mismatch. Expected: ${EXPECTED}, Actual: ${ACTUAL}" >&2; \
          exit 1; \
        fi; \
        echo "    SHA256 verified: ${ACTUAL}"; \
      else \
        echo "    WARNING: SHA256 checksum not available, skipping verification"; \
      fi; \
    fi; \
    chmod +x /usr/local/bin/fyy; \
    echo "==> fyy CLI ready."

# ---------------------------------------------------------------------------
# Stage 2: Runtime — minimal sandbox environment
# ---------------------------------------------------------------------------
FROM python:3.12-slim AS runtime

ARG FYY_VERSION=latest
ARG BUILD_DATE=""
ARG VCS_REF=""

# OCI standard labels
LABEL org.opencontainers.image.title="fyy-sandbox" \
      org.opencontainers.image.description="FYY Sandbox — container image for running AI Agents in sandboxed environments" \
      org.opencontainers.image.url="https://github.com/feiyueyun/fyy-sandbox-images" \
      org.opencontainers.image.source="https://github.com/feiyueyun/fyy-sandbox-images" \
      org.opencontainers.image.vendor="FeiYueYun" \
      org.opencontainers.image.version="${FYY_VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.licenses="MIT"

# Install system tools and Node.js 22 LTS
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      curl \
      git \
      ca-certificates \
      gnupg \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && apt-get purge -y gnupg \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* \
    && node --version && npm --version

# Create non-root user (UID 1000)
RUN groupadd --gid 1000 fyy && \
    useradd --uid 1000 --gid fyy --shell /bin/bash --create-home fyy

# Create fyy CLI workspace directories
RUN mkdir -p /home/fyy/.feiyueyun/identity \
             /home/fyy/.feiyueyun/tsnet \
             /home/fyy/.feiyueyun/skills \
    && chown -R fyy:fyy /home/fyy/.feiyueyun

# Copy fyy CLI binary from builder stage
COPY --from=builder /usr/local/bin/fyy /usr/local/bin/fyy

# Sandbox environment marker
# Used by fyy CLI to detect Layer-1 sandbox and auto-downgrade Layer-2 isolation
ENV FYY_SANDBOX=1 \
    PYTHONUNBUFFERED=1

WORKDIR /home/fyy/workspace

# Health check — verify fyy CLI is functional
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD fyy version || exit 1

# Run as non-root user
USER fyy

# Default entry
CMD ["bash"]
