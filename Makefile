SHELL := /bin/bash

.DEFAULT_GOAL := help

ENV_FILE ?= .env
OUTPUT ?= .msmtprc.generated
INSTALL_PATH ?= $(HOME)/.msmtprc
INSTALL_MODE ?= copy
EXAMPLE ?= default

.PHONY: help setup quickstart init-env render print-config install update test clean

help:
	@printf "Targets:\n"
	@printf "  make setup\n"
	@printf "  make quickstart EXAMPLE=<default|macos-keychain|linux-gpg|password-file>\n"
	@printf "  make init-env\n"
	@printf "  make render\n"
	@printf "  make print-config\n"
	@printf "  make install INSTALL_MODE=<copy|symlink>\n"
	@printf "  make update\n"
	@printf "  make test\n"
	@printf "  make clean\n"

setup:
	./scripts/setup.sh --env-file $(ENV_FILE) --output $(OUTPUT) --target $(INSTALL_PATH)

quickstart:
	./scripts/quickstart.sh --example $(EXAMPLE) --env-file $(ENV_FILE)

init-env:
	./scripts/quickstart.sh --example default --env-file $(ENV_FILE)

render:
	./scripts/render-config.sh --env-file $(ENV_FILE) --output $(OUTPUT)

print-config:
	./scripts/render-config.sh --env-file $(ENV_FILE) --stdout

install:
	./scripts/install.sh --env-file $(ENV_FILE) --output $(OUTPUT) --target $(INSTALL_PATH) --mode $(INSTALL_MODE)

update: install

test:
	./tests/test.sh

clean:
	rm -f $(OUTPUT)
