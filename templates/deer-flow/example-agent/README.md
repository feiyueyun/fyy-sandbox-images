# DeerFlow Agent Template

A template for running [DeerFlow](https://github.com/bytedance/deer-flow) agents in the FYY Sandbox environment.

## About DeerFlow

DeerFlow is an open-source long-horizon SuperAgent harness by ByteDance that researches, codes, and creates. It is built on LangGraph and supports multi-agent orchestration, sandbox execution, memory management, tool integration, and message gateways.

## Quick Start

```bash
# Build the DeerFlow sandbox image
docker build -t feiyueyun/fyy-sandbox:deer-flow -f templates/deer-flow/Dockerfile .

# Run the example agent
docker run --rm feiyueyun/fyy-sandbox:deer-flow python3 main.py
```

## What's Included

- **LangGraph runtime**: The core graph execution engine used by DeerFlow
- **LangChain ecosystem**: LLM integration framework supporting multiple providers
- **FastAPI + uvicorn**: API gateway for agent communication
- **FYY CLI**: Pre-installed for skill discovery and network connectivity

## Building a Full DeerFlow Project

This template provides the runtime environment. To build a complete DeerFlow agent:

1. Clone the DeerFlow repository:
   ```bash
   git clone https://github.com/bytedance/deer-flow.git
   ```

2. Install full dependencies:
   ```bash
   cd deer-flow/backend && uv sync
   ```

3. Configure your LLM provider (OpenAI, Anthropic, DeepSeek, etc.) via environment variables.

## FYY Integration

The template integrates with the FYY platform for:
- **Skill discovery**: Find and install reusable agent skills
- **Network connectivity**: Connect agents across distributed environments
- **Sandbox detection**: Automatic runtime environment detection via `FYY_SANDBOX=1`
