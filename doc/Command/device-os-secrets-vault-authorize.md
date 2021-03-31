# `device-os-secrets-vault-authorize`

Authorize a gpg identity (by public key) to access a *target device*'s
secret sub-store.

Will fallback to the *current device* if no *target device* specified.

## Settings

 -  `.current-device.yaml`

     -  `identifier`

        Identifies the current / target device when not explicitly specified
        otherwise (e.g: via env. var or parameter).

 -  `.factory-info.yaml`

    The secrects vault / top level store under which we'll look
    for the *target device*'s sub store:

     -  `gopass.default-device-vault`

## Effects

Will:

 -  mount required gopass stores / sub-store.
 -  import any required gpg public keys in the current factory user's
    keyring.
 -  update gpg user / identity authorized to the targeted stores / sub-stores.
 -  rencrypted any impacted / targeted secret files (`*.gpg`).


Impacted files:

 -  `./device/$(device-current-state field get identifier)/`
     -  `./.gpg-id`
     -  `./.public-keys/`
     -  `./*.gpg`

## See also

 -  [factory-gpg](./factory-gpg.md)
