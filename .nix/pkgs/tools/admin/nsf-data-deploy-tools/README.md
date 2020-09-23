Readme
======

The set of tools that are used by `nsf-data-deploy` in order to perform its
deployment on the target system.


Testing
-------

### Lib

Test the bash libraries found under `./sh-lib`. Theses libraries are used by
shell programs under `./bin` but also potentially by shell libraries and
programs of dependant packages (e.g.: under
`../nsf-secrets-deploy-tools/[bin|lib]`).

```bash
$ make shell-tests-lib
$ pytest tests/lib
# ..
```

### Installed

Test the installed form of the shell programs found under `./bin`. These shell
programs are potentially used by dependant packages (e.g.
`../nsf-secrets-deploy-tools`) and definitely used by
`nsf-data-deploy` through `nsf-data-deploy-lib`.

```bash
$ make shell-tests-installed
$ pytest tests/installed
# ..
```

### Nixos

```bash
$ make tests-nixos
# ..
```
