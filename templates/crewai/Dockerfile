# FYY Sandbox — CrewAI Template
# CrewAI framework + FYY CLI for Agent mesh networking
#
# Build: docker build -t feiyueyun/fyy-sandbox:crewai -f templates/crewai/Dockerfile .

FROM feiyueyun/fyy-sandbox:latest

LABEL org.opencontainers.image.title="FYY Sandbox CrewAI"
LABEL org.opencontainers.image.description="CrewAI framework with FYY CLI for distributed Agent workflows"

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# TODO: Install CrewAI when image is ready for release
# RUN pip3 install crewai

WORKDIR /workspace
CMD ["bash"]
