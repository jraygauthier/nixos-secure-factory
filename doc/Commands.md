Commands
========

 -  `device-os-secrets-create`

    EnvVars:

     -  `NSF_DEVICE_ROOT_USER_GPG_DEFAULT_EXPIRE_DATE`

        The default value that will be used when creating a device
        root user's gpg identity.

        One of: {"0", "\<n\>", "\<n\>w", "\<n\>m", "\<n\>y"}

        When unspecified, static default will be "1y".

 -  `factory-gpg-create-identity`

    Settings:

     -  `.factory-info.yaml`

         -  `user.gpg.default-expire-date`

            One of: {"0", "\<n\>", "\<n\>w", "\<n\>m", "\<n\>y"}

            When unspecified via one of the above mean), user will
            be prompted for a value by the command unless below
            `NSF_FACTORY_USER_GPG_DEFAULT_EXPIRE_DATE` is provided.

    EnvVars:

     -  `NSF_FACTORY_USER_GPG_DEFAULT_EXPIRE_DATE`

        The default value that will be used when creating the
        current factory user's gpg identity in case
        `.factory-info.yaml` does not specify it via the
        `user.gpg.default-expire-date` field.

        One of: {"0", "\<n\>", "\<n\>w", "\<n\>m", "\<n\>y"}

        When unspecified via one of the above mean), user will
        be prompted for a value by the command.
