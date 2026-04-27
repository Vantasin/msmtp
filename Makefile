SHELL := /bin/bash

.DEFAULT_GOAL := help

ENV_FILE ?= .env
OUTPUT ?= .msmtprc.generated
INSTALL_PATH ?= $(HOME)/.msmtprc
EXAMPLE ?= default

.PHONY: help setup setup-example generate preview install link check clean quickstart init-env render print-config update test

help: ## Show the common repo commands
	@printf "Common commands:\n"
	@awk 'BEGIN {FS = ":.*## "}; /^[a-zA-Z0-9_.-]+:.*## / {printf "  make %-14s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@printf "\nVariables:\n"
	@printf "  EXAMPLE      default | macos-keychain | linux-gpg | password-file\n"
	@printf "  ENV_FILE     %s\n" "$(ENV_FILE)"
	@printf "  OUTPUT       %s\n" "$(OUTPUT)"
	@printf "  INSTALL_PATH %s\n" "$(INSTALL_PATH)"

setup: ## Run the interactive setup wizard and write a local .env
	./scripts/setup.sh --env-file $(ENV_FILE) --output $(OUTPUT) --target $(INSTALL_PATH)

setup-example: ## Copy a starter .env example (set EXAMPLE=...)
	./scripts/quickstart.sh --example $(EXAMPLE) --env-file $(ENV_FILE)

generate: ## Render the generated msmtprc file from your env settings
	./scripts/render-config.sh --env-file $(ENV_FILE) --output $(OUTPUT)

preview: ## Print the rendered msmtprc to stdout
	./scripts/render-config.sh --env-file $(ENV_FILE) --stdout

install: ## Copy the rendered config into your active msmtp path
	./scripts/install.sh --env-file $(ENV_FILE) --output $(OUTPUT) --target $(INSTALL_PATH) --mode copy

link: ## Symlink your active msmtp path to the repo-managed output file
	./scripts/install.sh --env-file $(ENV_FILE) --output $(OUTPUT) --target $(INSTALL_PATH) --mode symlink

check: ## Run the repo smoke tests
	./tests/test.sh

clean: ## Remove generated files from the repo root
	rm -f $(OUTPUT)

quickstart:
	./scripts/quickstart.sh --example $(EXAMPLE) --env-file $(ENV_FILE)

init-env:
	./scripts/quickstart.sh --example default --env-file $(ENV_FILE)

render: generate

print-config: preview

update: install

test: check
