# FYY Sandbox Base Image
# Pre-installs FYY CLI for Agent mesh networking
#
# Build: docker build -t feiyueyun/fyy-sandbox:latest -f base/Dockerfile .
# Run:   docker run -it feiyueyun/fyy-sandbox:latest fyy status

FROM ubuntu:24.04

LABEL org.opencontainers.image.title="FYY Sandbox Base"
LABEL org.opencontainers.image.description="Base sandbox image with FYY CLI pre-installed"
LABEL org.opencontainers.image.vendor="Feiyueyun"
LABEL org.opencontainers.image.url="https://fyy.dev"
LABEL org.opencontainers.image.source="https://github.com/feiyueyun/fyy-sandbox-images"

ENV DEBIAN_FRONTEND=noninteractive
ENV FYY_SANDBOX=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

# TODO: Install FYY CLI when v1.0-alpha is released
# RUN curl -fsSL https://fyy.dev/install | sh

WORKDIR /workspace

CMD ["bash"]
