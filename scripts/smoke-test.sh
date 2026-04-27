#!/usr/bin/env bash
# smoke-test.sh — Smoke tests for FYY Sandbox container images
#
# Usage:
#   ./scripts/smoke-test.sh --image feiyueyun/fyy-sandbox:latest --type base
#   ./scripts/smoke-test.sh --image feiyueyun/fyy-sandbox:crewai  --type crewai
#   ./scripts/smoke-test.sh --image feiyueyun/fyy-sandbox:langgraph --type langgraph
#   ./scripts/smoke-test.sh --image feiyueyun/fyy-sandbox:deer-flow --type deer-flow
#
# Exit codes:
#   0 — all tests passed
#   1 — one or more tests failed

set -euo pipefail

# ---------------------------------------------------------------------------
# Defaults & globals
# ---------------------------------------------------------------------------
IMAGE=""
TYPE="base"
PASS_COUNT=0
FAIL_COUNT=0
TOTAL_COUNT=0

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
usage() {
    cat <<'EOF'
Usage: smoke-test.sh --image <image:tag> --type <base|crewai|langgraph|deer-flow>

Options:
  --image <image:tag>   Docker image to test (required)
  --type <type>         Image type: base, crewai, langgraph, deer-flow (default: base)
  -h, --help            Show this help message
EOF
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --image) IMAGE="$2"; shift 2 ;;
        --type)  TYPE="$2";  shift 2 ;;
        -h|--help) usage ;;
        *) echo "ERROR: Unknown argument: $1" >&2; usage ;;
    esac
done

if [[ -z "$IMAGE" ]]; then
    echo "ERROR: --image is required" >&2
    usage
fi

# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------
docker_run() {
    docker run --rm "$IMAGE" "$@"
}

pass() {
    PASS_COUNT=$((PASS_COUNT + 1))
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
    echo "  ✅ PASS: $1"
}

fail() {
    FAIL_COUNT=$((FAIL_COUNT + 1))
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
    echo "  ❌ FAIL: $1"
    if [[ -n "${2:-}" ]]; then
        echo "         Detail: $2"
    fi
}

run_test() {
    local description="$1"
    shift
    local output
    output=$(docker_run "$@" 2>&1) && {
        pass "$description"
        echo "$output"
        return 0
    } || {
        fail "$description" "$output"
        return 1
    }
}

run_test_output_contains() {
    local description="$1"
    local expected="$2"
    shift 2
    local output
    output=$(docker_run "$@" 2>&1) && {
        if echo "$output" | grep -q "$expected"; then
            pass "$description"
            return 0
        else
            fail "$description" "Expected output to contain '$expected', got: $output"
            return 1
        fi
    } || {
        fail "$description" "$output"
        return 1
    }
}

run_test_output_not_contains() {
    local description="$1"
    local unexpected="$2"
    shift 2
    local output
    output=$(docker_run "$@" 2>&1) && {
        if echo "$output" | grep -q "$unexpected"; then
            fail "$description" "Output should NOT contain '$unexpected', got: $output"
            return 1
        else
            pass "$description"
            return 0
        fi
    } || {
        fail "$description" "$output"
        return 1
    }
}

# ---------------------------------------------------------------------------
# Base image tests (REQ-8)
# ---------------------------------------------------------------------------
test_base_image() {
    echo ""
    echo "=== Base Image Tests ==="

    # Test 1: Container starts successfully
    run_test "Container starts and exits cleanly" true

    # Test 2: fyy CLI is executable
    run_test_output_contains "fyy CLI is executable" "version" fyy version

    # Test 3: Python 3.12 runtime
    run_test_output_contains "Python 3.12 available" "3.12" python3 --version

    # Test 4: Node.js 22 LTS
    run_test_output_contains "Node.js 22 available" "v22" node --version

    # Test 5: pip3 available
    run_test "pip3 available" pip3 --version

    # Test 6: npm available
    run_test "npm available" npm --version

    # Test 7: FYY_SANDBOX=1 environment variable
    run_test_output_contains "FYY_SANDBOX=1 env var set" "1" sh -c 'echo $FYY_SANDBOX'

    # Test 8: /.dockerenv exists (Docker runtime)
    run_test "Container is running in Docker (/.dockerenv)" sh -c 'test -f /.dockerenv'

    # Test 9: Non-root user
    run_test_output_not_contains "Running as non-root user (not root)" "root" whoami

    # Test 10: fyy CLI workspace directories exist
    run_test "fyy workspace ~/.feiyueyun/ exists" sh -c 'test -d ~/.feiyueyun'
    run_test "fyy workspace ~/.feiyueyun/identity/ exists" sh -c 'test -d ~/.feiyueyun/identity'
    run_test "fyy workspace ~/.feiyueyun/tsnet/ exists" sh -c 'test -d ~/.feiyueyun/tsnet'

    # Test 11: System tools available
    run_test "ca-certificates available" sh -c 'test -d /usr/share/ca-certificates'
    run_test "curl available" which curl
    run_test "git available" which git
}

# ---------------------------------------------------------------------------
# Framework template tests (REQ-10, REQ-11)
# ---------------------------------------------------------------------------
test_crewai_template() {
    echo ""
    echo "=== CrewAI Template Tests ==="

    # Run all base tests first
    test_base_image

    # CrewAI-specific tests
    run_test "CrewAI framework importable" python3 -c "import crewai; print('crewai ok')"
    run_test "Example agent directory exists" sh -c 'test -d /home/fyy/example-agent'
    run_test "Example agent main.py exists" sh -c 'test -f /home/fyy/example-agent/main.py'
    run_test "Example agent skill.json exists" sh -c 'test -f /home/fyy/example-agent/skill.json'
}

test_langgraph_template() {
    echo ""
    echo "=== LangGraph Template Tests ==="

    # Run all base tests first
    test_base_image

    # LangGraph-specific tests
    run_test "LangGraph framework importable" python3 -c "import langgraph; print('langgraph ok')"
    run_test "Example agent directory exists" sh -c 'test -d /home/fyy/example-agent'
    run_test "Example agent main.py exists" sh -c 'test -f /home/fyy/example-agent/main.py'
    run_test "Example agent skill.json exists" sh -c 'test -f /home/fyy/example-agent/skill.json'
}

test_deer_flow_template() {
    echo ""
    echo "=== DeerFlow Template Tests ==="

    # Run all base tests first
    test_base_image

    # DeerFlow-specific tests (DeerFlow is built on LangGraph)
    run_test "LangGraph framework importable (DeerFlow foundation)" python3 -c "import langgraph; print('langgraph ok')"
    run_test "LangChain core importable" python3 -c "import langchain_core; print('langchain_core ok')"
    run_test "FastAPI importable (DeerFlow gateway)" python3 -c "import fastapi; print('fastapi ok')"
    run_test "Pydantic importable (DeerFlow data models)" python3 -c "import pydantic; print('pydantic ok')"
    run_test "Example agent directory exists" sh -c 'test -d /home/fyy/example-agent'
    run_test "Example agent main.py exists" sh -c 'test -f /home/fyy/example-agent/main.py'
    run_test "Example agent skill.json exists" sh -c 'test -f /home/fyy/example-agent/skill.json'
}

# ---------------------------------------------------------------------------
# Invariant verification (REQ-16)
# ---------------------------------------------------------------------------
test_invariants() {
    echo ""
    echo "=== Invariant Verification ==="

    # Property 7: Environment variable persistence across contexts
    run_test_output_contains "FYY_SANDBOX persists in shell context" "1" \
        sh -c 'echo $FYY_SANDBOX'
    run_test_output_contains "FYY_SANDBOX persists in Python context" "1" \
        python3 -c "import os; print(os.environ.get('FYY_SANDBOX', 'unset'))"
    run_test_output_contains "FYY_SANDBOX persists in Node.js context" "1" \
        node -e "console.log(process.env.FYY_SANDBOX || 'unset')"

    # Property 8: Non-root user constraint
    run_test "Default user UID is not 0" sh -c '[ "$(id -u)" != "0" ]'
    run_test "Workspace is writable by default user" sh -c 'touch ~/.feiyueyun/test-write && rm ~/.feiyueyun/test-write'
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
echo "============================================"
echo "Smoke Test: ${IMAGE}"
echo "Type:       ${TYPE}"
echo "============================================"

case "$TYPE" in
    base)
        test_base_image
        test_invariants
        ;;
    crewai)
        test_crewai_template
        test_invariants
        ;;
    langgraph)
        test_langgraph_template
        test_invariants
        ;;
    deer-flow)
        test_deer_flow_template
        test_invariants
        ;;
    *)
        echo "ERROR: Unknown type: ${TYPE}" >&2
        usage
        ;;
esac

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "============================================"
echo "Results: ${PASS_COUNT} passed, ${FAIL_COUNT} failed (total: ${TOTAL_COUNT})"
echo "============================================"

if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
fi
exit 0
