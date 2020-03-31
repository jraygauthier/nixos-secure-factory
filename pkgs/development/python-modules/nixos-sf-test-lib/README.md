Readme
======

Configuration and environment variables
---------------------------------------

 -  `NIXOS_SF_TEST_LIB_BIN_PATH`: The `PATH` environment variable used to run
    this library's external (non-python) executable dependencies.

    This prevent one of this test library's depandency to hide a flaw in package
    under test (e.g: a missing dependancy).

    It is assumed at minimum that the following will be available through this `PATH`
    depending on which helper package is used:

     -  `nsft_pgp_utils` package:
         -  `gpg` executable (`gnupg` package) with all surrounding helpers.
         -  `base64` executable (`coreutils` package).

    When not set, default is to use the current environment `PATH`.
