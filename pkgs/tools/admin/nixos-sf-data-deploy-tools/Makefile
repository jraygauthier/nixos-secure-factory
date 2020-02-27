MKF_CWD := $(shell pwd)

clean:
	rm -f ./result*

release:
	nix build -f release.nix release

tests-sandboxed-lib:
	nix-build release.nix -A tests.lib

tests-sandboxed-install:
	nix-build release.nix -A tests.installed

tests-sandboxed-nixos:
	nix-build release.nix -A tests.nixos

tests-sandboxed-all:
	nix-build release.nix -A tests.all

tests-lib:
	nix-shell --pure release.nix -A tests.lib --run 'pytest tests/lib'

tests-installed:
	nix-shell --pure release.nix -A tests.installed --run 'pytest tests/installed'

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
