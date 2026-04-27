# FYY Sandbox — DeerFlow Template
# DeerFlow (ByteDance) multi-agent framework + FYY CLI for Agent mesh networking
# DeerFlow is a LangGraph-based SuperAgent harness for long-horizon tasks.
#
# Build: docker build -t feiyueyun/fyy-sandbox:deer-flow -f templates/deer-flow/Dockerfile .

FROM feiyueyun/fyy-sandbox:latest

LABEL org.opencontainers.image.title="FYY Sandbox DeerFlow"
LABEL org.opencontainers.image.description="DeerFlow multi-agent framework with FYY CLI for distributed Agent workflows"

USER root

# Install DeerFlow core runtime dependencies
# DeerFlow is built on LangGraph, so we install the compatible versions
# Reference: https://github.com/bytedance/deer-flow/blob/main/backend/packages/harness/pyproject.toml
RUN pip3 install --no-cache-dir \
    langgraph>=1.0.6,<1.0.10 \
    langchain>=1.2.3 \
    langchain-core \
    langchain-mcp-adapters>=0.1.0 \
    langgraph-sdk>=0.1.51 \
    langgraph-cli>=0.4.14 \
    langgraph-runtime-inmem>=0.22.1 \
    langgraph-checkpoint-sqlite>=3.0.3 \
    fastapi>=0.115.0 \
    uvicorn[standard]>=0.34.0 \
    httpx>=0.28.0 \
    pydantic>=2.12.5 \
    pyyaml>=6.0.3 \
    tiktoken>=0.8.0

# Copy example agent project
COPY templates/deer-flow/example-agent/ /home/fyy/example-agent/
RUN chown -R fyy:fyy /home/fyy/example-agent/

USER fyy
WORKDIR /home/fyy/example-agent
CMD ["bash"]
