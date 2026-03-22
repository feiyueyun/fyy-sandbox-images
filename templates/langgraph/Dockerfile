# FYY Sandbox — LangGraph Template
# LangGraph framework + FYY CLI for Agent mesh networking
#
# Build: docker build -t feiyueyun/fyy-sandbox:langgraph -f templates/langgraph/Dockerfile .

FROM feiyueyun/fyy-sandbox:latest

LABEL org.opencontainers.image.title="FYY Sandbox LangGraph"
LABEL org.opencontainers.image.description="LangGraph framework with FYY CLI for distributed Agent workflows"

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# TODO: Install LangGraph when image is ready for release
# RUN pip3 install langgraph

WORKDIR /workspace
CMD ["bash"]
