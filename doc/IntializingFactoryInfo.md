# Initializing factory information

The system needs to known multiple things about you before
proceeding. Here's the steps you should follow in order
to provide it.

## Step 1 - Initializing your gnupg identity

### By importing existing identity from the user's home

```bash
$ factory-gpg-import-secret-id-from-user-home
# .
```

The identity has been copied to a separate gnupg home
directly under the workspace: `${workspace_dir}/.gnupg`.

Take note of the fingerprint (fpr or long key id) of your gnupg identity. You
will be prompted for it later by `factory-state-init`.


### By creating a new or separate identity

```bash
$ factory-gpg-create-identity
# ..
```

TODO: Add some tips / warnings.


## Step 2 - Initializing secret repositories to be used

You will have to create 2 private git repositories. Both github and bitbucket
offer great private repositories services.

Information is encrypted by gopass targeting your gnupg identity and that of
the targeted device (only when required). You can optionally encrypt for
other users on a per *sub store* basis. We should come back to this later on.


### Factory secrets repository

This is where secrets only the factory user should known about will be stored.

You will be prompt for its local name by `factory-state-init`.

### Device secrets repository

You will be prompt for its local name by `factory-state-init`.


## Step 3 - Initialize your factory info config file

```bash
$ factory-state-init
# ..
```

This information will be saved to a `${workspace_dir}/.factory-info.yaml` file.
