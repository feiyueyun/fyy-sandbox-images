# FYY Sandbox — CrewAI Template
# CrewAI framework + FYY CLI for Agent mesh networking
#
# Build: docker build -t feiyueyun/fyy-sandbox:crewai -f templates/crewai/Dockerfile .

FROM feiyueyun/fyy-sandbox:latest

LABEL org.opencontainers.image.title="FYY Sandbox CrewAI"
LABEL org.opencontainers.image.description="CrewAI framework with FYY CLI for distributed Agent workflows"

USER root

# Install CrewAI framework
RUN pip3 install --no-cache-dir crewai crewai-tools

# Copy example agent project
COPY templates/crewai/example-agent/ /home/fyy/example-agent/
RUN chown -R fyy:fyy /home/fyy/example-agent/

USER fyy
WORKDIR /home/fyy/example-agent
CMD ["bash"]
