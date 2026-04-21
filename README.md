# FYY Sandbox Images

OCI container images for running AI Agents in sandboxed environments.

Pre-built images with FYY CLI and popular Agent frameworks — ready to use with any OCI-compatible runtime (Docker, Podman, containerd, gVisor, Kata Containers, and more).

## Available Images

| Image | Tag | Description | Architectures |
|-------|-----|-------------|---------------|
| Base | `latest` | fyy CLI + Python 3.12 + Node.js 22 LTS | amd64, arm64 |
| CrewAI | `crewai` | CrewAI framework + fyy CLI + example agent | amd64, arm64 |
| LangGraph | `langgraph` | LangGraph framework + fyy CLI + example agent | amd64, arm64 |

Versioned tags are also available (e.g. `v1.0.0`, `crewai-v1.0.0`).

## Quick Start

```bash
# Pull the base image
docker pull feiyueyun/fyy-sandbox:latest

# Run and connect to an FYY network
docker run -it feiyueyun/fyy-sandbox:latest fyy network join --authkey=tskey-auth-xxx

# Use a framework-specific image
docker pull feiyueyun/fyy-sandbox:crewai
docker run -it feiyueyun/fyy-sandbox:crewai
```

## What's Inside

### Base Image (`feiyueyun/fyy-sandbox:latest`)

- **fyy CLI** — pre-installed at `/usr/local/bin/fyy`
- **Python 3.12** — with `pip3` and `venv`
- **Node.js 22 LTS** — with `npm`
- **System tools** — `curl`, `git`, `ca-certificates`
- **Non-root user** — runs as `fyy` (UID 1000) by default
- **Sandbox marker** — `FYY_SANDBOX=1` environment variable

### Framework Templates

Each template extends the base image with a specific AI Agent framework and includes a runnable example agent project at `/home/fyy/example-agent/`.

## Runtime Detection

The base image sets `ENV FYY_SANDBOX=1`, which tells the fyy CLI it is running inside a Layer-1 sandbox. When detected, the Layer-2 Skill Process Sandbox (gVisor) automatically downgrades to process-level isolation, since gVisor cannot nest inside a container.

Three detection methods are available (in priority order):

1. `FYY_SANDBOX=1` environment variable — most reliable, works with all OCI runtimes
2. `/.dockerenv` file — Docker-specific
3. `/proc/1/cgroup` container markers — Linux kernel-level

## Building Locally

```bash
# Build base image (release mode — downloads fyy from GitHub Releases)
make build-base

# Build base image (dev mode — cross-compiles fyy from ../fyy-src)
make dev-prepare
BUILD_MODE=dev make build-base

# Build all images
make build-all

# Run smoke tests
make smoke-test

# Run Trivy security scan
make trivy-scan
```

See `make help` for all available targets.

## Image Signing

Published images are signed with [Cosign](https://github.com/sigstore/cosign) using keyless signing (Sigstore Fulcio + Rekor).

```bash
# Verify image signature
cosign verify feiyueyun/fyy-sandbox:latest \
  --certificate-identity=https://github.com/feiyueyun/fyy-sandbox-images/.github/workflows/build-and-publish.yml@refs/tags/v1.0.0 \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com
```

## fyy CLI License

fyy CLI is closed-source and free to distribute. This does not conflict with the BSD 3-Clause license of the Dockerfiles and build scripts in this repository — similar to how Docker images can pre-install proprietary tools like `curl` while the image definition remains open source.

## Integration Guides

See [fyy-sandbox-guides](https://github.com/feiyueyun/fyy-sandbox-guides) for integration with popular sandbox runtimes (E2B, Daytona, Devcontainer, Kata, Firecracker, Docker, gVisor, Kubernetes).

## Repository Structure

```
fyy-sandbox-images/
├── base/Dockerfile                    # Base image (multi-stage build)
├── templates/
│   ├── crewai/
│   │   ├── Dockerfile                 # CrewAI template
│   │   └── example-agent/            # Example CrewAI agent
│   ├── langgraph/
│   │   ├── Dockerfile                 # LangGraph template
│   │   └── example-agent/            # Example LangGraph agent
│   └── openclaw/
│       └── Dockerfile                 # OpenClaw template (Phase 2)
├── scripts/
│   ├── fetch-fyy-binary.sh            # fyy CLI binary fetcher
│   └── smoke-test.sh                  # Smoke test suite
├── .github/workflows/
│   └── build-and-publish.yml          # CI/CD pipeline
├── Makefile                           # Local build commands
└── .trivyignore                       # Trivy vulnerability exceptions
```

## License

BSD 3-Clause — see [LICENSE](LICENSE).
