# CrewAI Example Agent

A minimal CrewAI agent template with FYY CLI integration.

## Quick Start

```bash
# Run the example agent
python3 main.py

# Connect to an FYY network first to discover skills
fyy network join --authkey=tskey-auth-xxx

# Search for available skills
fyy skill search "weather"
```

## Project Structure

```
example-agent/
├── main.py             # Agent entry point with FYY CLI integration
├── requirements.txt    # Python dependencies
├── skill.json          # Skill manifest (skill-manifest-spec)
└── README.md           # This file
```

## Adding Skills

Use `fyy skill install <name>` to install skills from the FYY network.
Installed skills are available via the FYY CLI or MCP gateway.
