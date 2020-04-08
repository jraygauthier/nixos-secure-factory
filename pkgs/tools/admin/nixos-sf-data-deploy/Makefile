MKF_CWD := $(shell pwd)

.PHONY: all clean tests

all: tests

clean:
	rm -f ./result*

tests: tests.case1 tests.case2

tests.case1:
	nix-build ./tests/case1/test.nix -A myDeviceDataDeployDerivation

tests.case2:
	nix-build ./tests/case2/test.nix -A myDeviceDataDeployDerivation