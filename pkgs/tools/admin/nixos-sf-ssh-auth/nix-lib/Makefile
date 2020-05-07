MKF_CWD := $(shell pwd)

.PHONY: all clean tests

all: tests

clean:
	rm -f ./result*

tests:
	nix eval --show-trace --raw -f ./tests runTestsAll
