# FYY Sandbox — OpenClaw Template
# OpenClaw framework + FYY CLI for Agent mesh networking
#
# Build: docker build -t feiyueyun/fyy-sandbox:openclaw -f templates/openclaw/Dockerfile .

FROM feiyueyun/fyy-sandbox:latest

LABEL org.opencontainers.image.title="FYY Sandbox OpenClaw"
LABEL org.opencontainers.image.description="OpenClaw framework with FYY CLI for distributed Agent workflows"

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# TODO: Install OpenClaw when image is ready for release
# RUN pip3 install openclaw

WORKDIR /workspace
CMD ["bash"]
