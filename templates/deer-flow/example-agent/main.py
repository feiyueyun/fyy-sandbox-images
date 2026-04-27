"""
Example DeerFlow Agent with FYY CLI integration.

DeerFlow (https://github.com/bytedance/deer-flow) is a LangGraph-based
SuperAgent harness by ByteDance for long-horizon tasks like research,
coding, and content creation.

This example demonstrates how to build a DeerFlow-compatible agent that
leverages the FYY platform for skill discovery and network connectivity.
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
    print(f"Running in FYY sandbox: {sandbox}")

    # Show fyy version
    version = run_fyy(["version"])
    print(f"fyy version: {version}")

    # Verify LangGraph runtime (DeerFlow's foundation)
    try:
        import langgraph  # noqa: F401
        print(f"LangGraph version: {langgraph.__version__}")
    except ImportError:
        print("WARNING: langgraph not installed", file=sys.stderr)

    try:
        import langchain_core  # noqa: F401
        print(f"LangChain Core version: {langchain_core.__version__}")
    except ImportError:
        print("WARNING: langchain-core not installed", file=sys.stderr)

    # Discover available skills
    print("\nDiscovering FYY skills...")
    try:
        skills = run_fyy(["skill", "search", "--tag", "system-skill"])
        print(f"Available system skills:\n{skills}")
    except SystemExit:
        print("No skills found (not connected to a network yet).")

    print("\n--- DeerFlow Agent Template ---")
    print("DeerFlow is a LangGraph-based SuperAgent framework by ByteDance.")
    print("It supports multi-agent orchestration, sandbox execution,")
    print("memory management, and long-horizon task decomposition.")
    print("")
    print("To set up a full DeerFlow project, run:")
    print("  git clone https://github.com/bytedance/deer-flow.git")
    print("  cd deer-flow && make install")
    print("")
    print("Use 'fyy skill install <name>' to add skills to your agent.")


if __name__ == "__main__":
    main()
