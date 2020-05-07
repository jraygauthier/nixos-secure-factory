MKF_CWD := $(shell pwd)

.PHONY: all clean tests release

all: tests release

clean:
	rm -f ./result*

tests: tests.case2

tests.case2:
	nix-build ./tests/case2/test.nix -A myDeviceDataDeployDerivation

release:
	nix eval --show-trace --raw \
	  '(builtins.toString (builtins.isAttrs ((import ./release.nix {}).nix-lib)))'

	nix eval --show-trace --raw -f ./release.nix \
	  '(builtins.toString (builtins.isFunction ((import ./release.nix {}).mkSecretsDeployPackage)))'
