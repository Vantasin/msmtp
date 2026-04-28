SHELL := /bin/bash

.DEFAULT_GOAL := help

ENV_FILE ?= .env
OUTPUT ?= .msmtprc.generated
USER_INSTALL_PATH ?= $(HOME)/.msmtprc
SYSTEM_INSTALL_PATH ?= /etc/msmtprc
INSTALL_PATH ?= $(USER_INSTALL_PATH)
INSTALL_FORCE ?= no
BACKUP ?=
EXAMPLE ?= default
ACCOUNTS_DIR ?=
DEFAULT_ACCOUNT ?=
ACCOUNT_NAME ?= account
SECRET_ENV_FILE ?=
PASSWORD_FILE ?=
GPG_FILE ?=
GPG_RECIPIENT ?=
KEYCHAIN_SERVICE ?=
KEYCHAIN_ACCOUNT ?=

INPUT_ARGS = $(if $(strip $(ACCOUNTS_DIR)),--accounts-dir $(ACCOUNTS_DIR),--env-file $(ENV_FILE))
DEFAULT_ACCOUNT_ARGS = $(if $(strip $(DEFAULT_ACCOUNT)),--default-account $(DEFAULT_ACCOUNT),)
ACCOUNT_ENV_FILE = accounts/$(ACCOUNT_NAME).env
FORCE_ARG = $(if $(filter 1 yes true on,$(INSTALL_FORCE)),--force,)

.PHONY: help account password setup setup-example setup-account setup-account-example generate preview install install-user install-system restore restore-user restore-system link link-user check clean secrets-help secret-check keychain-add password-file-init gpg-file-init quickstart init-env render print-config update test

help: ## Show the common repo commands
	@printf "Common commands:\n"
	@awk 'BEGIN {FS = ":.*## "}; /^[a-zA-Z0-9_.-]+:.*## / {printf "  make %-22s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@printf "\nVariables:\n"
	@printf "  EXAMPLE      default | macos-keychain | linux-gpg | password-file\n"
	@printf "  ENV_FILE     %s\n" "$(ENV_FILE)"
	@printf "  ACCOUNTS_DIR %s\n" "$(ACCOUNTS_DIR)"
	@printf "  DEFAULT_ACCOUNT %s\n" "$(DEFAULT_ACCOUNT)"
	@printf "  ACCOUNT_NAME %s\n" "$(ACCOUNT_NAME)"
	@printf "  SECRET_ENV_FILE %s\n" "$(SECRET_ENV_FILE)"
	@printf "  PASSWORD_FILE %s\n" "$(PASSWORD_FILE)"
	@printf "  GPG_FILE %s\n" "$(GPG_FILE)"
	@printf "  GPG_RECIPIENT %s\n" "$(GPG_RECIPIENT)"
	@printf "  OUTPUT       %s\n" "$(OUTPUT)"
	@printf "  USER_INSTALL_PATH %s\n" "$(USER_INSTALL_PATH)"
	@printf "  SYSTEM_INSTALL_PATH %s\n" "$(SYSTEM_INSTALL_PATH)"
	@printf "  INSTALL_PATH %s\n" "$(INSTALL_PATH)"
	@printf "  INSTALL_FORCE %s\n" "$(INSTALL_FORCE)"
	@printf "  BACKUP       %s\n" "$(BACKUP)"

account: ## Manage single or multi-account env files from one workflow
	./scripts/account-manager.sh --env-file $(ENV_FILE) --accounts-dir $(if $(strip $(ACCOUNTS_DIR)),$(ACCOUNTS_DIR),accounts) $(FORCE_ARG)

password: ## Choose an env file and run the matching password helper
	./scripts/password-helper.sh $(if $(strip $(SECRET_ENV_FILE)),--env-file $(SECRET_ENV_FILE),)

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

install: ## Guided install flow for choosing source, target, and copy vs symlink
	./scripts/install-helper.sh $(if $(strip $(ACCOUNTS_DIR)),--accounts-dir $(ACCOUNTS_DIR),$(if $(strip $(ENV_FILE)),--env-file $(ENV_FILE),)) $(DEFAULT_ACCOUNT_ARGS) --output $(OUTPUT) --target $(INSTALL_PATH) $(FORCE_ARG)

install-user: ## Explicitly copy the rendered config into ~/.msmtprc
	./scripts/install.sh $(INPUT_ARGS) $(DEFAULT_ACCOUNT_ARGS) --output $(OUTPUT) --target $(USER_INSTALL_PATH) --mode copy $(FORCE_ARG)

install-system: ## Explicitly copy the rendered config into /etc/msmtprc
	./scripts/install.sh $(INPUT_ARGS) $(DEFAULT_ACCOUNT_ARGS) --output $(SYSTEM_INSTALL_PATH) --target $(SYSTEM_INSTALL_PATH) --mode copy $(FORCE_ARG)

restore: ## Guided restore flow for choosing a target and backup
	./scripts/restore-helper.sh $(if $(strip $(BACKUP)),--backup $(BACKUP),) --target $(INSTALL_PATH) $(FORCE_ARG)

restore-user: ## Restore ~/.msmtprc from BACKUP or choose one interactively
	./scripts/restore-helper.sh $(if $(strip $(BACKUP)),--backup $(BACKUP),) --target $(USER_INSTALL_PATH) $(FORCE_ARG)

restore-system: ## Restore /etc/msmtprc from BACKUP or choose one interactively
	./scripts/restore-helper.sh $(if $(strip $(BACKUP)),--backup $(BACKUP),) --target $(SYSTEM_INSTALL_PATH) $(FORCE_ARG)

link: ## Explicitly symlink your active msmtp path to the repo-managed output file
	./scripts/install.sh $(INPUT_ARGS) $(DEFAULT_ACCOUNT_ARGS) --output $(OUTPUT) --target $(INSTALL_PATH) --mode symlink $(FORCE_ARG)

link-user: ## Symlink ~/.msmtprc to the repo-managed output file
	./scripts/install.sh $(INPUT_ARGS) $(DEFAULT_ACCOUNT_ARGS) --output $(OUTPUT) --target $(USER_INSTALL_PATH) --mode symlink $(FORCE_ARG)

check: ## Run the repo smoke tests
	./tests/test.sh

secrets-help: ## Show the supported secret backends and helper commands
	./scripts/secrets-help.sh

secret-check: ## Validate that the configured passwordeval command works
	./scripts/secret-check.sh $(INPUT_ARGS)

keychain-add: ## Add or update a macOS Keychain secret for one env file
	./scripts/keychain-add.sh --env-file $(if $(strip $(SECRET_ENV_FILE)),$(SECRET_ENV_FILE),$(ENV_FILE)) $(if $(strip $(KEYCHAIN_SERVICE)),--service $(KEYCHAIN_SERVICE),) $(if $(strip $(KEYCHAIN_ACCOUNT)),--account $(KEYCHAIN_ACCOUNT),)

password-file-init: ## Create a password file with strict permissions
	./scripts/password-file-init.sh --env-file $(if $(strip $(SECRET_ENV_FILE)),$(SECRET_ENV_FILE),$(ENV_FILE)) $(if $(strip $(PASSWORD_FILE)),--password-file $(PASSWORD_FILE),)

gpg-file-init: ## Create a GPG-encrypted password file without plaintext args
	./scripts/gpg-file-init.sh --env-file $(if $(strip $(SECRET_ENV_FILE)),$(SECRET_ENV_FILE),$(ENV_FILE)) $(if $(strip $(GPG_FILE)),--gpg-file $(GPG_FILE),) $(if $(strip $(GPG_RECIPIENT)),--recipient $(GPG_RECIPIENT),)

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
