# fyy-sandbox-images — Makefile
# ======================================

.PHONY: dev-prepare build-base build-crewai build-langgraph build-all \
        smoke-test smoke-test-base smoke-test-crewai smoke-test-langgraph \
        trivy-scan clean help

# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------
DOCKER   ?= docker
IMAGE_NS := feiyueyun/fyy-sandbox
FYY_VERSION ?= latest
BUILD_MODE  ?= release
TARGETARCH  ?= $(shell uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/')
BUILD_DATE  ?= $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
VCS_REF     ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
FYY_SRC     ?= ../fyy-src

# ---------------------------------------------------------------------------
# Dev mode: prepare binary from local fyy-src
# ---------------------------------------------------------------------------

## dev-prepare: Cross-compile fyy for Linux from local fyy-src
dev-prepare:
	@echo "==> Cross-compiling fyy for linux/$(TARGETARCH) from ${FYY_SRC}..."
	@mkdir -p dev-bin
	@if [ -f "${FYY_SRC}/Makefile" ]; then \
		cd "${FYY_SRC}" && \
		GOOS=linux GOARCH=$(TARGETARCH) go build \
			-ldflags "-X main.version=$$(git describe --tags --always --dirty 2>/dev/null || echo dev) -X main.commit=$$(git rev-parse --short HEAD 2>/dev/null || echo unknown) -X main.buildTime=$$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
			-o "$(CURDIR)/dev-bin/fyy" ./cmd/fyy/; \
		echo "    Built $(CURDIR)/dev-bin/fyy (linux/$(TARGETARCH))"; \
	else \
		echo "ERROR: ${FYY_SRC}/Makefile not found. Is FYY_SRC correct?" >&2; \
		exit 1; \
	fi
	@echo "==> Done."

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------

## build-base: Build the base sandbox image
build-base:
	@echo "==> Building base image ($(BUILD_MODE) mode, version $(FYY_VERSION))..."
	$(DOCKER) build \
		--build-arg FYY_VERSION=$(FYY_VERSION) \
		--build-arg BUILD_MODE=$(BUILD_MODE) \
		--build-arg TARGETARCH=$(TARGETARCH) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg VCS_REF=$(VCS_REF) \
		-t $(IMAGE_NS):latest \
		-f base/Dockerfile .
	@echo "==> Done."

## build-crewai: Build the CrewAI template image
build-crewai: build-base
	@echo "==> Building CrewAI template image..."
	$(DOCKER) build \
		-t $(IMAGE_NS):crewai \
		-f templates/crewai/Dockerfile .
	@echo "==> Done."

## build-langgraph: Build the LangGraph template image
build-langgraph: build-base
	@echo "==> Building LangGraph template image..."
	$(DOCKER) build \
		-t $(IMAGE_NS):langgraph \
		-f templates/langgraph/Dockerfile .
	@echo "==> Done."

## build-all: Build all images (base + templates)
build-all: build-base build-crewai build-langgraph

# ---------------------------------------------------------------------------
# Smoke Tests
# ---------------------------------------------------------------------------

## smoke-test-base: Run smoke tests on base image
smoke-test-base:
	@echo "==> Running smoke tests on base image..."
	bash scripts/smoke-test.sh --image $(IMAGE_NS):latest --type base

## smoke-test-crewai: Run smoke tests on CrewAI template
smoke-test-crewai:
	@echo "==> Running smoke tests on CrewAI template..."
	bash scripts/smoke-test.sh --image $(IMAGE_NS):crewai --type crewai

## smoke-test-langgraph: Run smoke tests on LangGraph template
smoke-test-langgraph:
	@echo "==> Running smoke tests on LangGraph template..."
	bash scripts/smoke-test.sh --image $(IMAGE_NS):langgraph --type langgraph

## smoke-test: Run all smoke tests
smoke-test: smoke-test-base smoke-test-crewai smoke-test-langgraph

# ---------------------------------------------------------------------------
# Security Scan
# ---------------------------------------------------------------------------

## trivy-scan: Run Trivy security scan on base image
trivy-scan:
	@echo "==> Running Trivy scan on base image..."
	trivy image --severity CRITICAL,HIGH --exit-code 0 $(IMAGE_NS):latest

# ---------------------------------------------------------------------------
# Clean
# ---------------------------------------------------------------------------

## clean: Remove built images and dev artifacts
clean:
	@echo "==> Removing built images..."
	-$(DOCKER) rmi $(IMAGE_NS):latest 2>/dev/null
	-$(DOCKER) rmi $(IMAGE_NS):crewai 2>/dev/null
	-$(DOCKER) rmi $(IMAGE_NS):langgraph 2>/dev/null
	rm -rf dev-bin/
	@echo "==> Done."

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------

## help: Show this help message
help:
	@echo "Available targets:"
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/^## /  /'
