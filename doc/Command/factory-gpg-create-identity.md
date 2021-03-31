# `factory-gpg-create-identity`

## Settings

 -  `.factory-info.yaml`

     -  `user.gpg.default-expire-date`

        One of: {"0", "\<n\>", "\<n\>w", "\<n\>m", "\<n\>y"}

        When unspecified via one of the above mean), user will
        be prompted for a value by the command unless below
        `NSF_FACTORY_USER_GPG_DEFAULT_EXPIRE_DATE` is provided.

## Env. vars

 -  `NSF_FACTORY_USER_GPG_DEFAULT_EXPIRE_DATE`

    The *default* value that will be used when creating the
    current factory user's gpg identity in case
    `.factory-info.yaml` does not specify it via the
    `user.gpg.default-expire-date` field.

    One of: {"0", "\<n\>", "\<n\>w", "\<n\>m", "\<n\>y"}

    When unspecified via one of the above mean), user will
    be prompted for a value by the command.

 -  `NSF_FACTORY_USER_GPG_EXPIRE_DATE`

    The value that will be used when creating the current factory user's
    gpg identity.

    Has priority over `NSF_FACTORY_USER_GPG_DEFAULT_EXPIRE_DATE`
    and `.factory-info.yaml::user.gpg.default-expire-date`.


## See also

 -  [factory-gpg](./factory-gpg.md)
