MKF_CWD := $(shell pwd)

PYTHON_BINS = $(shell find ./bin -mindepth 1 -maxdepth 1 -exec file --mime-type {} + \
	| grep 'text/x-python' | awk -F: '{ print $$1 }')

SH_BINS = $(shell find ./bin -mindepth 1 -maxdepth 1 -executable -type f -exec file --mime-type {} + \
	| grep 'text/x-shellscript' | awk -F: '{ print $$1 }')
SH_MODULES = $(shell find ./sh-lib -type f -name "*.sh")
SH_DEPS_SRC_PATHS = $(shell pkg-nsf-device-system-config-updater-get-sh-lib-dir):$(shell pkg-nsf-device-system-config-get-sh-lib-dir):$(shell pkg-nsf-common-install-get-sh-lib-dir):$(shell pkg-nsf-common-get-sh-lib-dir)


.PHONY: all clean release typechecks tests lint lint-python lint-shell

all: typechecks tests lint release

clean:
	rm -f ./result*

typechecks:
	mypy . ./py/src $(shell find ./py/tests -name "test_*.py") $(shell find ./tests -name "test_*.py")
	mypy --scripts-are-modules $(PYTHON_BINS)

tests:
	pytest

lint: lint.shell lint.python

lint.python:
	flake8
	flake8 $(PYTHON_BINS)

lint.shell: lint.shell.modules lint.shell.bins

lint.shell.deep: lint.shell.modules.deep lint.shell.bins.deep


lint.shell.modules:
	for m in $(SH_MODULES); do \
	  shellcheck -e SC1091 -P "$(SH_DEPS_SRC_PATHS)" $$m; \
	done

lint.shell.bins:
	shellcheck -e SC1091 -P \
	  "$(SH_DEPS_SRC_PATHS)" \
  	  $(SH_BINS)

lint.shell.modules.deep:
	shellcheck -a -x -P \
	  "$(SH_DEPS_SRC_PATHS)" \
	  $(SH_MODULES)

lint.shell.bins.deep:
	shellcheck -a -x -P \
	  "$(SH_DEPS_SRC_PATHS)" \
  	  $(SH_BINS)

release:
	nix-build release.nix

shell.dev:
	nix-shell release.nix -A shell.dev

shell.installed:
	nix-shell release.nix -A shell.installed
