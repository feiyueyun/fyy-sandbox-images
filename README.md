# FYY Sandbox Images

OCI container images for running AI Agents in sandboxed environments.

Pre-built images with FYY CLI and popular Agent frameworks — ready to use with any OCI-compatible runtime.

## Available Images

| Image | Description |
|-------|-------------|
| `feiyueyun/fyy-sandbox:latest` | Base image with FYY CLI pre-installed |
| `feiyueyun/fyy-sandbox:crewai` | CrewAI framework + FYY CLI |
| `feiyueyun/fyy-sandbox:langgraph` | LangGraph framework + FYY CLI |
| `feiyueyun/fyy-sandbox:openclaw` | OpenClaw framework + FYY CLI |

## Quick Start

```bash
# Pull the base image
docker pull feiyueyun/fyy-sandbox:latest

# Run with your auth key
docker run -it feiyueyun/fyy-sandbox:latest fyy network join --authkey=tskey-auth-xxx

# Use a framework-specific image
docker pull feiyueyun/fyy-sandbox:crewai
```

## Integration Guides

See [fyy-sandbox-guides](https://github.com/feiyueyun/fyy-sandbox-guides) for integration with popular sandbox runtimes (E2B, Daytona, Devcontainer, Kata, Firecracker, Docker, gVisor, Kubernetes).

## Structure

```
fyy-sandbox-images/
├── base/Dockerfile              # Base image (FYY CLI pre-installed)
└── templates/
    ├── crewai/Dockerfile        # CrewAI framework template
    ├── langgraph/Dockerfile     # LangGraph framework template
    └── openclaw/Dockerfile      # OpenClaw framework template
```

## License

BSD 3-Clause — see [LICENSE](LICENSE).

> 🚧 Images will be published to Docker Hub when FYY CLI v1.0-alpha is released (2026 Q3).
