# `device-os-secrets-vaults-factory-only-authorize`

Authorize a gpg identity (by public key) to access a *target device*'s
secret sub-stores (both the *factory-only device sub-store* one and the
*device sub-store*).

Will fallback to the *current device* if no *target device* specified.

## Settings

 -  `.current-device.yaml`

     -  `identifier`

        Identifies the current / target device when not explicitly specified
        otherwise (e.g: via env. var or parameter).

 -  `.factory-info.yaml`

    The secrects vaults / top level stores under which we'll look
    for the *target device*'s sub stores:

     -  `gopass.factory-only-vault`
     -  `gopass.default-device-vault`

Impacted files (under both targeted stores / repositories):

 -  `./device/$(device-current-state field get identifier)/`
     -  `./.gpg-id`
     -  `./.public-keys/`
     -  `./*.gpg`

## See also

 -  [factory-gpg](./factory-gpg.md)
