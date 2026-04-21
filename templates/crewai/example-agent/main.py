"""
Example CrewAI Agent with FYY CLI integration.

This example demonstrates how to build a CrewAI agent that leverages
the FYY platform for skill discovery and network connectivity.
"""

import os
import subprocess
import sys


def run_fyy(args: list[str]) -> str:
    """Run a fyy CLI command and return its output."""
    result = subprocess.run(
        ["fyy"] + args,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"fyy error: {result.stderr}", file=sys.stderr)
        sys.exit(result.returncode)
    return result.stdout.strip()


def main() -> None:
    # Verify sandbox environment
    sandbox = os.environ.get("FYY_SANDBOX", "0")
    print(f"Running in sandbox: {sandbox}")

    # Show fyy version
    version = run_fyy(["version"])
    print(f"fyy version: {version}")

    # Discover available skills
    print("\nDiscovering skills...")
    try:
        skills = run_fyy(["skill", "search", "--tag", "system-skill"])
        print(f"Available system skills:\n{skills}")
    except SystemExit:
        print("No skills found (not connected to a network yet).")

    print("\n--- CrewAI Agent Template ---")
    print("Edit main.py to build your own CrewAI agent.")
    print("Use 'fyy skill install <name>' to add skills to your agent.")


if __name__ == "__main__":
    main()
