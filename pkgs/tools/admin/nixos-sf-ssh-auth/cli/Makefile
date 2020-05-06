MKF_CWD := $(shell pwd)

.PHONY: all clean tests

all: typechecks tests-lib lint release

clean:
	rm -f ./result*

typechecks:
	mypy . $(shell find ./tests -name "test_*.py")

tests:
	pytest

tests-lib:
	pytest tests/lib

lint:
	flake8

release:
	nix-build release.nix -A release