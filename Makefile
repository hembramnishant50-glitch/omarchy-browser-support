# omarchy-browser-support — development tasks.
#
#   make check    static analysis + every test suite
#   make test     the suites only
#   make lint     bash -n + shellcheck
#   make icon     rebuild the Helium menu font (needs fonttools)
#   make clean    remove test scratch directories

SHELL := /bin/bash
.DEFAULT_GOAL := check

SCRIPTS := bin/omarchy-browsers install.sh uninstall.sh $(wildcard lib/*.sh) $(wildcard tests/*.sh) tests/helpers/env.sh
SUITES  := $(sort $(wildcard tests/test_*.sh))

# Use the local shellcheck if present, otherwise skip with a note rather than
# failing a developer who has not installed it. CI always has it.
SHELLCHECK := $(shell command -v shellcheck 2>/dev/null)

.PHONY: check lint test syntax shellcheck icon clean help

help:
	@sed -n '2,9p' Makefile | sed -E 's/^# ?//'

check: lint test

lint: syntax shellcheck

syntax:
	@echo "==> bash -n"
	@failed=0; for f in $(SCRIPTS); do \
	  bash -n "$$f" || { echo "  syntax error: $$f"; failed=1; }; \
	done; \
	[ $$failed -eq 0 ] && echo "  all scripts parse"

shellcheck:
	@if [ -n "$(SHELLCHECK)" ]; then \
	  echo "==> shellcheck $(shell $(SHELLCHECK) --version 2>/dev/null | sed -n '2p')"; \
	  $(SHELLCHECK) --shell=bash --severity=warning $(SCRIPTS); \
	  echo "  clean"; \
	else \
	  echo "==> shellcheck not installed — skipping (pacman -S shellcheck)"; \
	fi

test:
	@echo "==> tests/run.sh"
	@tests/run.sh

icon:
	@echo "==> rebuilding assets/OmarchyHeliumIcon.ttf"
	@python3 assets/build-helium-icon-font.py
	@git status --short assets/OmarchyHeliumIcon.ttf || true

clean:
	@rm -rf "$${TMPDIR:-/tmp}"/obs-test.*
	@echo "==> test scratch directories removed"
