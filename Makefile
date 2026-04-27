SHELL := /bin/bash

.DEFAULT_GOAL := help

ENV_FILE ?= .env
OUTPUT ?= .msmtprc.generated
INSTALL_PATH ?= $(HOME)/.msmtprc
EXAMPLE ?= default
ACCOUNTS_DIR ?=
DEFAULT_ACCOUNT ?=
ACCOUNT_NAME ?= account

INPUT_ARGS = $(if $(strip $(ACCOUNTS_DIR)),--accounts-dir $(ACCOUNTS_DIR),--env-file $(ENV_FILE))
DEFAULT_ACCOUNT_ARGS = $(if $(strip $(DEFAULT_ACCOUNT)),--default-account $(DEFAULT_ACCOUNT),)
ACCOUNT_ENV_FILE = accounts/$(ACCOUNT_NAME).env

.PHONY: help setup setup-example setup-account setup-account-example generate preview install link check clean quickstart init-env render print-config update test

help: ## Show the common repo commands
	@printf "Common commands:\n"
	@awk 'BEGIN {FS = ":.*## "}; /^[a-zA-Z0-9_.-]+:.*## / {printf "  make %-14s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@printf "\nVariables:\n"
	@printf "  EXAMPLE      default | macos-keychain | linux-gpg | password-file\n"
	@printf "  ENV_FILE     %s\n" "$(ENV_FILE)"
	@printf "  ACCOUNTS_DIR %s\n" "$(ACCOUNTS_DIR)"
	@printf "  DEFAULT_ACCOUNT %s\n" "$(DEFAULT_ACCOUNT)"
	@printf "  ACCOUNT_NAME %s\n" "$(ACCOUNT_NAME)"
	@printf "  OUTPUT       %s\n" "$(OUTPUT)"
	@printf "  INSTALL_PATH %s\n" "$(INSTALL_PATH)"

setup: ## Run the interactive setup wizard and write a local .env
	./scripts/setup.sh --env-file $(ENV_FILE) --output $(OUTPUT) --target $(INSTALL_PATH)

setup-example: ## Copy a starter .env example (set EXAMPLE=...)
	./scripts/quickstart.sh --example $(EXAMPLE) --env-file $(ENV_FILE)

setup-account: ## Run the interactive setup wizard for accounts/$(ACCOUNT_NAME).env
	./scripts/setup.sh --env-file $(ACCOUNT_ENV_FILE) --output $(OUTPUT) --target $(INSTALL_PATH)

setup-account-example: ## Copy a starter example to accounts/$(ACCOUNT_NAME).env
	./scripts/quickstart.sh --example $(EXAMPLE) --env-file $(ACCOUNT_ENV_FILE)

generate: ## Render the generated msmtprc from ENV_FILE or ACCOUNTS_DIR
	./scripts/render-config.sh $(INPUT_ARGS) $(DEFAULT_ACCOUNT_ARGS) --output $(OUTPUT)

preview: ## Print the rendered msmtprc from ENV_FILE or ACCOUNTS_DIR
	./scripts/render-config.sh $(INPUT_ARGS) $(DEFAULT_ACCOUNT_ARGS) --stdout

install: ## Copy the rendered config into your active msmtp path
	./scripts/install.sh $(INPUT_ARGS) $(DEFAULT_ACCOUNT_ARGS) --output $(OUTPUT) --target $(INSTALL_PATH) --mode copy

link: ## Symlink your active msmtp path to the repo-managed output file
	./scripts/install.sh $(INPUT_ARGS) $(DEFAULT_ACCOUNT_ARGS) --output $(OUTPUT) --target $(INSTALL_PATH) --mode symlink

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
