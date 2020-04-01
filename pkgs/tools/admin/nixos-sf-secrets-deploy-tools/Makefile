MKF_CWD := $(shell pwd)

.PHONY: all clean release typechecks tests lint

all: typechecks tests-lib tests-installed lint release tests-sandboxed-all

clean:
	rm -f ./result*

typechecks:
	mypy . $(shell find ./tests -name "test_*.py")

tests:
	pytest

lint: lint-shell lint-python

lint-python:
	flake8

lint-shell:
	shellcheck -x -P \
	  "$(shell pkg-nixos-sf-data-deploy-tools-get-sh-lib-dir)" \
	  $(shell find ./sh-lib -type f -name "*.sh") \
	  $(shell find ./bin -mindepth 1 -executable -type f)

release:
	nix-build release.nix -A release

tests-sandboxed-lib:
	nix-build release.nix -A tests.lib

tests-sandboxed-installed:
	nix-build release.nix -A tests.installed

tests-sandboxed-nixos:
	nix-build release.nix -A tests.nixos

tests-sandboxed-all:
	nix-build release.nix -A tests.all

tests-lib:
	pytest tests/lib

tests-installed:
	pytest tests/installed

tests-nixos: tests-sandboxed-nixos

tests-all: tests-lib tests-installed tests-nixos

tests-aggregate:
	nix-build release.nix -A tests.aggregate

shell-build:
	nix-shell release.nix -A shell.build

shell-installed:
	nix-shell release.nix -A shell.installed

shell-tests-lib:
	nix-shell release.nix -A tests.lib

shell-tests-installed:
	nix-shell release.nix -A tests.installed
