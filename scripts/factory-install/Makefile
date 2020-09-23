MKF_CWD := $(shell pwd)

.PHONY: all clean release typechecks tests lint lint-python lint-shell

all: typechecks tests lint release

clean:
	rm -f ./result*

typechecks:
	mypy . $(shell find ./tests -name "test_*.py")
	mypy --scripts-are-modules $(shell find ./bin -mindepth 1 -maxdepth 1 -exec file --mime-type {} + \
		| grep 'text/x-python' | awk -F: '{ print $$1 }')

tests:
	pytest

lint: lint-shell lint-python

lint-python:
	flake8
	flake8 $(shell find ./bin -mindepth 1 -maxdepth 1 -exec file --mime-type {} + \
		| grep 'text/x-python' | awk -F: '{ print $$1 }')

lint-shell:
	shellcheck -x -P \
	  "$(shell pkg-nsf-data-deploy-tools-get-sh-lib-dir)" \
	  $(shell find ./sh-lib -type f -name "*.sh") \
	  $(shell find ./bin -mindepth 1 -executable -type f)

release:
	nix-build release.nix

