MKF_CWD := $(shell pwd)

.PHONY: all clean tests

all: tests

clean:
	rm -f ./result*

tests: tests.case2

tests.case2:
	nix-build ./tests/case2/test.nix -A myDeviceDataDeployDerivation