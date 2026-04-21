# Contributing to FYY Sandbox Images

Thank you for your interest in contributing! This guide covers how to set up your development environment and submit changes.

## Development Setup

### Prerequisites

- Docker with Buildx support
- GNU Make
- Git
- Go 1.25+ (for dev mode — cross-compiling fyy CLI from source)

### Quick Start

```bash
# Clone the repository
git clone https://github.com/feiyueyun/fyy-sandbox-images.git
cd fyy-sandbox-images

# Build the base image (dev mode uses local fyy-src)
make dev-prepare BUILD_MODE=dev
BUILD_MODE=dev make build-base

# Run smoke tests
make smoke-test-base

# Build all images
make build-all

# Run all smoke tests
make smoke-test
```

## Adding a New Framework Template

1. Create a directory under `templates/<framework>/`
2. Write a `Dockerfile` that starts `FROM feiyueyun/fyy-sandbox:latest`
3. Add an `example-agent/` subdirectory with:
   - `main.py` — agent entry point with fyy CLI integration
   - `requirements.txt` — Python dependencies
   - `skill.json` — skill manifest following [skill-manifest-spec](https://github.com/feiyueyun/skill-manifest-spec)
   - `README.md` — usage instructions
4. Update the CI workflow to include the new template in the build matrix
5. Update `scripts/smoke-test.sh` to handle the new `--type` option
6. Update `README.md` to list the new image

### Template Dockerfile Guidelines

- Always start from `FROM feiyueyun/fyy-sandbox:latest`
- Switch to root only for package installation: `USER root` → install → `USER fyy`
- Use `pip3 install --no-cache-dir` to minimize image size
- Set `WORKDIR /home/fyy/example-agent`
- Include OCI labels (`org.opencontainers.image.title`, `org.opencontainers.image.description`)

## Running Tests

```bash
# Base image tests
bash scripts/smoke-test.sh --image feiyueyun/fyy-sandbox:latest --type base

# Framework template tests
bash scripts/smoke-test.sh --image feiyueyun/fyy-sandbox:crewai --type crewai
bash scripts/smoke-test.sh --image feiyueyun/fyy-sandbox:langgraph --type langgraph
```

All smoke tests must pass before submitting a PR.

## CI Pipeline

The CI pipeline (`.github/workflows/build-and-publish.yml`) runs on:

- **Push to main** — build, test, scan, and push with `latest` tag
- **Pull request** — build and test only (no push)
- **Tag push (v\*)** — build, test, scan, push with version tag + `latest`, and sign with Cosign
- **Manual dispatch** — build with custom fyy version and tag

## Commit Messages

Use conventional commit format:

- `feat: add new framework template`
- `fix: resolve Python version in base image`
- `ci: update build workflow for multi-arch`
- `docs: update README with new image tag`

## License

By contributing, you agree that your contributions will be licensed under the BSD 3-Clause License.