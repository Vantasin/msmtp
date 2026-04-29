SHELL := /bin/bash

.DEFAULT_GOAL := help

ACCOUNTS_DIR ?= accounts
ACCOUNT_NAME ?= default
ACCOUNT_FILE ?= $(ACCOUNTS_DIR)/$(ACCOUNT_NAME).env
DEFAULT_ACCOUNT ?=
OUTPUT ?= .msmtprc.generated
USER_INSTALL_PATH ?= $(HOME)/.msmtprc
SYSTEM_INSTALL_PATH ?= /etc/msmtprc
INSTALL_PATH ?=
INSTALL_MODE ?=
INSTALL_FORCE ?= no
ROTATE_FORCE ?= no
BACKUP ?=
EXAMPLE ?= default
PASSWORD_FILE ?=
GPG_FILE ?=
GPG_RECIPIENT ?=
KEYCHAIN_SERVICE ?=
KEYCHAIN_ACCOUNT ?=
TEST_RECIPIENT ?=
TEST_SUBJECT ?=
TEST_BODY ?=
LIVE_CONFIG_PATH ?=

ACCOUNT_NAME_ORIGIN := $(firstword $(origin ACCOUNT_NAME))
ACCOUNT_FILE_ORIGIN := $(firstword $(origin ACCOUNT_FILE))
DEFAULT_ACCOUNT_ARGS = $(if $(strip $(DEFAULT_ACCOUNT)),--default-account $(DEFAULT_ACCOUNT),)
FORCE_ARG = $(if $(filter 1 yes true on,$(INSTALL_FORCE)),--force,)
ROTATE_FORCE_ARG = $(if $(filter 1 yes true on,$(ROTATE_FORCE)),--force,)
MODE_ARG = $(if $(strip $(INSTALL_MODE)),--mode $(INSTALL_MODE),)
TARGET_ARG = $(if $(strip $(INSTALL_PATH)),--target $(INSTALL_PATH),)
ACCOUNT_SELECTION_ARG = $(if $(filter command environment,$(ACCOUNT_FILE_ORIGIN)),--env-file $(ACCOUNT_FILE),$(if $(filter command environment,$(ACCOUNT_NAME_ORIGIN)),--env-file $(ACCOUNT_FILE),--accounts-dir $(ACCOUNTS_DIR)))

.PHONY: help account configure password rotate-password test-email test-live-email setup setup-example generate preview install install-user install-system restore restore-config restore-user-config restore-system-config restore-account restore-secret link link-user check clean secrets-help secret-check keychain-add password-file-init gpg-file-init

help: ## Show the common repo commands
	@printf "Common commands:\n"
	@awk 'BEGIN {FS = ":.*## "}; /^[a-zA-Z0-9_.-]+:.*## / {printf "  make %-22s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@printf "\nVariables:\n"
	@printf "  EXAMPLE      default | macos-keychain | linux-gpg | password-file\n"
	@printf "  ACCOUNTS_DIR %s\n" "$(ACCOUNTS_DIR)"
	@printf "  ACCOUNT_NAME %s\n" "$(ACCOUNT_NAME)"
	@printf "  ACCOUNT_FILE %s\n" "$(ACCOUNT_FILE)"
	@printf "  DEFAULT_ACCOUNT %s  # one-off render/install override; otherwise use accounts/.default-account\n" "$(DEFAULT_ACCOUNT)"
	@printf "  PASSWORD_FILE %s\n" "$(PASSWORD_FILE)"
	@printf "  GPG_FILE %s\n" "$(GPG_FILE)"
	@printf "  GPG_RECIPIENT %s\n" "$(GPG_RECIPIENT)"
	@printf "  TEST_RECIPIENT %s\n" "$(TEST_RECIPIENT)"
	@printf "  TEST_SUBJECT %s\n" "$(TEST_SUBJECT)"
	@printf "  TEST_BODY    %s\n" "$(TEST_BODY)"
	@printf "  LIVE_CONFIG_PATH %s\n" "$(LIVE_CONFIG_PATH)"
	@printf "  OUTPUT       %s\n" "$(OUTPUT)"
	@printf "  USER_INSTALL_PATH %s\n" "$(USER_INSTALL_PATH)"
	@printf "  SYSTEM_INSTALL_PATH %s\n" "$(SYSTEM_INSTALL_PATH)"
	@printf "  INSTALL_PATH %s\n" "$(INSTALL_PATH)"
	@printf "  INSTALL_MODE %s\n" "$(INSTALL_MODE)"
	@printf "  INSTALL_FORCE %s\n" "$(INSTALL_FORCE)"
	@printf "  ROTATE_FORCE %s\n" "$(ROTATE_FORCE)"
	@printf "  BACKUP       %s\n" "$(BACKUP)"

account: ## Manage account files in ACCOUNTS_DIR from one workflow
	./scripts/account-manager.sh --accounts-dir $(ACCOUNTS_DIR) $(FORCE_ARG)

configure: ## Guided human workflow for account, secret, validation, and install
	./scripts/configure.sh --accounts-dir $(ACCOUNTS_DIR) $(DEFAULT_ACCOUNT_ARGS) $(TARGET_ARG) $(MODE_ARG) $(FORCE_ARG)

password: ## Choose an account file and run the matching password helper
	./scripts/password-helper.sh $(ACCOUNT_SELECTION_ARG)

rotate-password: ## Rotate the secret for one account file safely
	./scripts/rotate-password.sh $(ACCOUNT_SELECTION_ARG) $(if $(strip $(GPG_RECIPIENT)),--recipient $(GPG_RECIPIENT),) $(ROTATE_FORCE_ARG)

test-email: ## Send a real test email with one selected account
	./scripts/test-email.sh $(ACCOUNT_SELECTION_ARG) $(if $(strip $(TEST_RECIPIENT)),--recipient "$(TEST_RECIPIENT)",) $(if $(strip $(TEST_SUBJECT)),--subject "$(TEST_SUBJECT)",) $(if $(strip $(TEST_BODY)),--body "$(TEST_BODY)",)

test-live-email: ## Send a real test email using the installed live config path
	./scripts/test-live-email.sh $(ACCOUNT_SELECTION_ARG) $(if $(strip $(LIVE_CONFIG_PATH)),--target "$(LIVE_CONFIG_PATH)",) $(if $(strip $(TEST_RECIPIENT)),--recipient "$(TEST_RECIPIENT)",) $(if $(strip $(TEST_SUBJECT)),--subject "$(TEST_SUBJECT)",) $(if $(strip $(TEST_BODY)),--body "$(TEST_BODY)",)

setup: ## Run the interactive setup wizard for ACCOUNT_FILE
	./scripts/setup.sh --env-file $(ACCOUNT_FILE)

setup-example: ## Copy a starter example to ACCOUNT_FILE (set EXAMPLE=...)
	./scripts/quickstart.sh --example $(EXAMPLE) --env-file $(ACCOUNT_FILE)

generate: ## Render the generated msmtprc from ACCOUNTS_DIR
	./scripts/render-config.sh --accounts-dir $(ACCOUNTS_DIR) $(DEFAULT_ACCOUNT_ARGS) --output $(OUTPUT)

preview: ## Print the rendered msmtprc from ACCOUNTS_DIR
	./scripts/render-config.sh --accounts-dir $(ACCOUNTS_DIR) $(DEFAULT_ACCOUNT_ARGS) --stdout

install: ## Guided install flow for choosing target and copy vs symlink
	./scripts/install-helper.sh --accounts-dir $(ACCOUNTS_DIR) $(DEFAULT_ACCOUNT_ARGS) --output $(OUTPUT) $(TARGET_ARG) $(MODE_ARG) $(FORCE_ARG)

install-user: ## Explicitly copy the rendered config into ~/.msmtprc
	./scripts/install.sh --accounts-dir $(ACCOUNTS_DIR) $(DEFAULT_ACCOUNT_ARGS) --output $(OUTPUT) --target $(USER_INSTALL_PATH) --mode copy $(FORCE_ARG)

install-system: ## Explicitly copy the rendered config into /etc/msmtprc
	./scripts/install.sh --accounts-dir $(ACCOUNTS_DIR) $(DEFAULT_ACCOUNT_ARGS) --output $(SYSTEM_INSTALL_PATH) --target $(SYSTEM_INSTALL_PATH) --mode copy $(FORCE_ARG)

restore: ## Guided restore flow for choosing backup type and target
	./scripts/restore-helper.sh --accounts-dir $(ACCOUNTS_DIR) $(if $(strip $(BACKUP)),--backup $(BACKUP),) $(TARGET_ARG) $(FORCE_ARG)

restore-config: ## Restore a live msmtp config target from BACKUP or choose one interactively
	./scripts/restore-config-helper.sh $(if $(strip $(BACKUP)),--backup $(BACKUP),) $(TARGET_ARG) $(FORCE_ARG)

restore-user-config: ## Restore ~/.msmtprc from BACKUP or choose one interactively
	./scripts/restore-config-helper.sh $(if $(strip $(BACKUP)),--backup $(BACKUP),) --target $(USER_INSTALL_PATH) $(FORCE_ARG)

restore-system-config: ## Restore /etc/msmtprc from BACKUP or choose one interactively
	./scripts/restore-config-helper.sh $(if $(strip $(BACKUP)),--backup $(BACKUP),) --target $(SYSTEM_INSTALL_PATH) $(FORCE_ARG)

restore-account: ## Restore one accounts/*.env backup
	./scripts/restore-account-helper.sh --accounts-dir $(ACCOUNTS_DIR) $(if $(filter command environment,$(ACCOUNT_NAME_ORIGIN)),--account $(ACCOUNT_NAME),) $(if $(strip $(BACKUP)),--backup $(BACKUP),) $(FORCE_ARG)

restore-secret: ## Restore one password_file or gpg secret backup and validate it
	./scripts/restore-secret-helper.sh $(ACCOUNT_SELECTION_ARG) $(if $(strip $(BACKUP)),--backup $(BACKUP),) $(FORCE_ARG)

link: ## Explicitly symlink your active msmtp path to the repo-managed output file
	./scripts/install.sh --accounts-dir $(ACCOUNTS_DIR) $(DEFAULT_ACCOUNT_ARGS) --output $(OUTPUT) --target $(if $(strip $(INSTALL_PATH)),$(INSTALL_PATH),$(USER_INSTALL_PATH)) --mode symlink $(FORCE_ARG)

link-user: ## Symlink ~/.msmtprc to the repo-managed output file
	./scripts/install.sh --accounts-dir $(ACCOUNTS_DIR) $(DEFAULT_ACCOUNT_ARGS) --output $(OUTPUT) --target $(USER_INSTALL_PATH) --mode symlink $(FORCE_ARG)

check: ## Run the repo smoke tests
	./tests/test.sh

secrets-help: ## Show the supported secret backends and helper commands
	./scripts/secrets-help.sh

secret-check: ## Validate the configured passwordeval command for one account or ACCOUNTS_DIR
	./scripts/secret-check.sh $(ACCOUNT_SELECTION_ARG)

keychain-add: ## Add or update a macOS Keychain secret for ACCOUNT_FILE
	./scripts/keychain-add.sh --env-file $(ACCOUNT_FILE) $(if $(strip $(KEYCHAIN_SERVICE)),--service $(KEYCHAIN_SERVICE),) $(if $(strip $(KEYCHAIN_ACCOUNT)),--account $(KEYCHAIN_ACCOUNT),)

password-file-init: ## Create a password file with strict permissions for ACCOUNT_FILE
	./scripts/password-file-init.sh --env-file $(ACCOUNT_FILE) $(if $(strip $(PASSWORD_FILE)),--password-file $(PASSWORD_FILE),)

gpg-file-init: ## Create a GPG-encrypted password file without plaintext args for ACCOUNT_FILE
	./scripts/gpg-file-init.sh --env-file $(ACCOUNT_FILE) $(if $(strip $(GPG_FILE)),--gpg-file $(GPG_FILE),) $(if $(strip $(GPG_RECIPIENT)),--recipient $(GPG_RECIPIENT),)

clean: ## Remove generated files from the repo root
	rm -f $(OUTPUT)
