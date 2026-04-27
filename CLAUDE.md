# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

OCI container images for running AI Agents in sandboxed environments (飞越云 FYY Sandbox). The base image pre-installs the FYY CLI alongside Python 3.12 and Node.js 22 LTS. Framework-specific templates (CrewAI, LangGraph, DeerFlow) layer on top of the base image.

Published to Docker Hub as `feiyueyun/fyy-sandbox` with tags: `latest`, `crewai`, `langgraph`, `deer-flow`, `openclaw`.

**Status**: Pre-release. Images will be published when FYY CLI v1.0-alpha is released (2026 Q3). Framework template Dockerfiles currently have package installs commented out (`# TODO: Install ... when image is ready for release`).

## Build Commands

```bash
# Build base image locally
docker build -t feiyueyun/fyy-sandbox:latest base/

# Build a template image (requires base image to exist locally or in registry)
docker build -t feiyueyun/fyy-sandbox:crewai -f templates/crewai/Dockerfile templates/crewai/
docker build -t feiyueyun/fyy-sandbox:langgraph -f templates/langgraph/Dockerfile templates/langgraph/
docker build -t feiyueyun/fyy-sandbox:deer-flow -f templates/deer-flow/Dockerfile templates/deer-flow/

# Run base image
docker run -it feiyueyun/fyy-sandbox:latest
```

There is no Makefile or test suite yet — both are planned per the design spec.

## Architecture

**Image layer hierarchy:**
```
python:3.12-slim
  └── base/Dockerfile → feiyueyun/fyy-sandbox:latest
        ├── templates/crewai/Dockerfile → feiyueyun/fyy-sandbox:crewai
        ├── templates/langgraph/Dockerfile → feiyueyun/fyy-sandbox:langgraph
        ├── templates/deer-flow/Dockerfile → feiyueyun/fyy-sandbox:deer-flow
        └── templates/openclaw/Dockerfile → feiyueyun/fyy-sandbox:openclaw
```

**Base image** (`base/Dockerfile`): Multi-stage build from `python:3.12-slim`. Installs Node.js 22 LTS via NodeSource, includes a placeholder fyy CLI binary (replaced by CI with actual release binary). Runs as non-root user `fyy`. Sets `ENV FYY_SANDBOX=1` for runtime detection.

**Template images**: Each `FROM feiyueyun/fyy-sandbox:latest` and adds framework-specific dependencies. They inherit the `FYY_SANDBOX=1` env var, non-root user, and CLI binary.

## CI

GitHub Actions workflow at `.github/workflows/ci.yml`:
- Triggers on push/PR to `main`
- Builds base image, then template images in a matrix
- Uses Docker Buildx with GitHub Actions cache (`type=gha`)
- Does not push to Docker Hub yet (no publishing steps configured)

## Key Design Decisions

- **fyy CLI is a placeholder** in the current base Dockerfile (shell script that echoes a message). The real binary will be injected during CI from GitHub Releases.
- **Runtime detection**: Three methods — `/.dockerenv` file, `/proc/1/cgroup` container markers, `FYY_SANDBOX=1` env var. When detected, the Layer 2 Skill Process Sandbox auto-downgrades to process-level isolation.
- **OpenClaw template** is included but is a Phase 2 deliverable — not part of Phase 1 requirements.
- The design spec in `.kiro/specs/` describes planned components not yet implemented: `scripts/smoke-test.sh`, `scripts/fetch-fyy-binary.sh`, `Makefile`, `CONTRIBUTING.md`, `.trivyignore`, Cosign signing, Trivy scanning, and multi-arch builds.

## Language

Repository documentation and specs are written in Chinese (中文). Code comments and Dockerfiles are in English.
