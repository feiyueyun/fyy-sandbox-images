# FYY Sandbox — LangGraph Template
# LangGraph framework + FYY CLI for Agent mesh networking
#
# Build: docker build -t feiyueyun/fyy-sandbox:langgraph -f templates/langgraph/Dockerfile .

FROM feiyueyun/fyy-sandbox:latest

LABEL org.opencontainers.image.title="FYY Sandbox LangGraph"
LABEL org.opencontainers.image.description="LangGraph framework with FYY CLI for distributed Agent workflows"

USER root

# Install LangGraph framework
RUN pip3 install --no-cache-dir langgraph langchain-core

# Copy example agent project
COPY templates/langgraph/example-agent/ /home/fyy/example-agent/
RUN chown -R fyy:fyy /home/fyy/example-agent/

USER fyy
WORKDIR /home/fyy/example-agent
CMD ["bash"]
