# `factory-secrets-vaults-authorize`

Authorize a gpg identity (by public key) to access all factory secret
vaults / stores.

This by default includes access to existing per devices sub stores.


## Settings

 -  `.factory-info.yaml`

    More precisely, these are the vault described via the following fields:

     -  `gopass.factory-only-vault`
     -  `gopass.default-device-vault`

    The `repo-name` field under either of these describe the targeted
    repository by *directory name* which should be found under the
    *workspace directory* (i.e: output of
    `pkg-nsf-factory-common-install-get-workspace-dir`).


## Parameters / flags

 -  `--shallow`

    Do not target per device substores / do not re-encrypt the whole set of
    per device secrets.

    Intended use is for when we're interested in authorizing a gpg user only to
    the secrets of newly created devices (i.e: secrets of devices that will be
    created from this point on, not authorizing the user to any previously
    created device secrets).

## Effects

Will:

 -  mount required gopass stores / sub-stores.
 -  import any required gpg public keys in the current factory user's
    keyring.
 -  update gpg user / identity authorized to the targeted stores / sub-stores.
 -  rencrypted any impacted / targeted secret files (`*.gpg`).


Impacted files under each targeted vault repository:

 -  `./.`
     -  `./.gpg-id`
     -  `./.public-keys/`

 -  `./device/*/`

    When not `--shallow`.

     -  `./.gpg-id`
     -  `./.public-keys/`

 -  `*.gpg`

    When `--shallow`, does not descend into per device substores
    (e.g: `./device/*/`).

    This means that the command re-encrypt all secrets from targeted
    stores / sub-stores.


## See also

 -  [factory-gpg](./factory-gpg)
