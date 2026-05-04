# La Bestia — Makefile
# Standard targets so contributors don't guess which bash file to run.
# Mirror of CI gates. Anything that passes locally should pass in CI.

.PHONY: help install install-project install-check test test-hooks test-schemas \
        lint verify check clean release-prep agents-table version

VERSION := $(shell sed -n 's/.*"version": "\([^"]*\)".*/\1/p' .claude-plugin/plugin.json 2>/dev/null || echo "1.1.0")

help: ## Show this help
	@echo "La Bestia v$(VERSION) — make targets"
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "Tip: 'make all' = lint + test + verify."

install: ## Install globally to ~/.claude/
	bash install.sh global

install-project: ## Install project-local to ./.claude/
	bash install.sh project ./.claude

install-check: ## Run installer in --check mode (no writes)
	bash install.sh --check

test: test-schemas test-hooks ## Run all tests (schemas + hooks)

test-hooks: ## Run bats hook tests
	@command -v bats >/dev/null 2>&1 || { echo "✗ bats not installed (brew install bats-core)" >&2; exit 1; }
	bats --tap tests/hooks/

test-schemas: ## Validate JSON schemas + agent/skill frontmatter
	bash tests/run.sh schemas

lint: ## shellcheck on hooks + scripts + bin
	@command -v shellcheck >/dev/null 2>&1 || { echo "✗ shellcheck not installed" >&2; exit 1; }
	shellcheck -e SC1091 config/hooks/*.sh config/scripts/*.sh tests/run.sh install.sh bin/*.sh 2>/dev/null || \
	  shellcheck -e SC1091 config/hooks/*.sh config/scripts/*.sh tests/run.sh install.sh

verify: ## Run ~/.claude/scripts/verify.sh against current install
	bash ~/.claude/scripts/verify.sh

check: lint test verify ## Full pre-commit check (lint + test + verify)

test-quality: ## Run quality measurement: routing tests + parallelism + latency
	@echo "=== route-prompt 16 canonical cases ==="
	@command -v bats >/dev/null 2>&1 || { echo "✗ bats not installed" >&2; exit 1; }
	@bats --tap tests/hooks/route-prompt.bats
	@echo ""
	@echo "=== parallelism check (against your live agents.jsonl) ==="
	@if [ -f "$$HOME/.claude/logs/agents.jsonl" ]; then \
		bash bin/parallelism-check.sh "$$HOME/.claude/logs/agents.jsonl" || true ; \
	else \
		echo "(no live agents.jsonl yet — run /flow first to populate)" ; \
	fi
	@echo ""
	@echo "=== latency report (against your live agents.jsonl) ==="
	@if [ -f "$$HOME/.claude/logs/agents.jsonl" ]; then \
		bash bin/latency-report.sh "$$HOME/.claude/logs/agents.jsonl" || true ; \
	else \
		echo "(no live agents.jsonl yet)" ; \
	fi

clean: ## Remove generated artifacts (logs, eval reports)
	rm -rf evals/_reports/ tests/_tmp/ .claude/logs/*.jsonl .claude/logs/.agent_start_*

release-prep: ## Print release checklist for v$(VERSION)
	@echo "Release prep for v$(VERSION):"
	@echo "  [ ] Update CHANGELOG.md: move [Unreleased] -> [$(VERSION)] - $$(date +%Y-%m-%d)"
	@echo "  [ ] Update README version row"
	@echo "  [ ] Update .claude-plugin/plugin.json version"
	@echo "  [ ] git commit -m 'release: v$(VERSION)'"
	@echo "  [ ] git tag v$(VERSION) && git push --tags"

agents-table: ## Print a current table of agents (for README updates)
	@printf "| Agent | Model | Tools |\n|---|---|---|\n"
	@for f in config/agents/*.md; do \
	  name=$$(basename "$$f" .md); \
	  [ "$$name" = "_TEMPLATE" ] && continue; \
	  model=$$(grep -m1 '^model:' "$$f" | sed 's/model: //;s/"//g' | tr -d "[:space:]"); \
	  tools=$$(grep -m1 '^tools:' "$$f" | sed 's/tools: //'); \
	  printf "| \`%s\` | %s | %s |\n" "$$name" "$$model" "$$tools"; \
	done

version: ## Print current version
	@echo "$(VERSION)"

all: check ## Alias for check
