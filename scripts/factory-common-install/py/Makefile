MKF_CWD := $(shell pwd)

.PHONY: all clean release typechecks tests lint

all: typechecks tests lint release

clean:
	rm -f ./result*

typechecks:
	mypy . ./src $(shell find ./tests -name "test_*.py")

tests:
	pytest

lint:
	flake8

release:
	nix-build release.nix -A default

shell.dev:
	nix-shell release.nix -A shell.dev
