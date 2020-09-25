Todo
====

Required refactors
------------------

 -  Prefix all commands with `nsf`.

     -  `device-.+` -> `nsf-device-.+`
     -  `factory-.+` -> `nsf-factory-.+`

    Note, some commands are defined as scripts under the `bin` folder.
    Other commands (python) via the `*/py/setup.cfg` file.

 -  `device-liveenv-install-factory-tools` -> should fetch the
    package env from `./release.nix` instead of `./env.nix`. This
    would make these bundles more lightweight.

    Consider letting the tool wrap the package itself using `buildEnv`?
    It might well be the default behavior when no `env` attribute found
    in `release.nix`.

 -  `etc/nixos-device-system-config` -> `etc/nsf-device-system-config`.

    Needs to adapt updater package so that it keeps backward compatibility
    for some time.

 -  Top level config `release.nix` should return an attribute set instead of a
    derivation. This attribute set should have a `default` derivation but is
    allowed to expose different variants (e.g: `local`, etc).

    Has impact on:

     -  Update package.
     -  Config build script.

 -  Top level config `device-update/release.nix`. Same as above.

    Has impact on:

     -  Update package.

 -  Use plain gpg instead of gopass.

    Has already been completed for reading secrets. What remains is the
    mutable operations (creating secrets, updating secrets, authorizing
    users to secrets, etc). The mutable operations will be much more
    complex to implement then reading.

    This way, we can completly circumvent the store mount / unmount and avoid
    the fragile gopass states generated / managed by gopass under the workspace.

    We can then do whatever we want with the storage of gpg public keys
    (see [gopass/issues/1238]) and the space it takes. We should however
    maintain full compatibility with gopass / pass.

    We can decide to preserve some of the gopass code but only in order
    launch the a gui with mounted stores.

[gopass/issues/1238]: https://github.com/gopasspw/gopass/issues/1238


Exploring some ideas
--------------------

 -  Instead of accepting the pkgs implicitly if it has all of the
    required internal overlay packages nominally, we should instead require that
    our user provide additionnal attributes so that the intention
    of providing the whole internal overlay is made explicit.

    By default if the following is not set, we should implicitly add our internal overlay
    with well known pin:

    ```nix
    nix-pin-config.overlay.nixos-secure-factory-internal.provider = "nixos-secure-factory-internal";
    ```

    This is the principle of least surprise in action. However, there are 2 side effects to this:

     1. Performance degradation as we're adding a new overlay.
     2. Local sources as specified by user repo / flake won't be used for internal packages which
        can lead to some surprises, in particular when our public interface changes due to some
        common / indirect dependencies.

    As part of the provided pkgs set:

    ```nix
    nix-pin-config.overlay.nixos-secure-factory-internal.provider = "custom-factory-internal";
    ```

    By telling so, the user of our repo / flake is telling us that he intends on controlling
    the whole of our internal dependencies.

    Once user does that, we should fail if any missing package instead of
    silently using the internal overlay pins.

    Also, a stack of provided overlay should be kept for debugging purposes (first
    being the top of the stack):

    ```nix
    nix-pin-config.overlay-stack = [
        "nixos-secure-factory-internal"
        "custom-factory-internal"
        "custom-factory-internal-internal"
    ]
    ```

 -  See if we can reuse the [nix-deploy] tool.

 -  A way to extend some of the executables.

     -  Might be a nix parameters which brings some python project with extensions.
     -  We might also offer a way to completely disable some of the tools to
        make room for rewriting them.

 -  Use the state field as a way to change the system update channel (a bit
    like what has been done for ssh auth.

 -  A nsf-fi tool that would re return the effective authorized user of key by
    building the effective configuration. This would supplement what's offered
    by ssh auth.

 -  It would be nice if we can avoid the config generation part and simply have
    a pure derivation to build. In order to do that, we would have to refine
    our `nsf-pin` system so that we have a mean to allow `-I` nix paths to
    be effective for any of the srcs.

 -  Consider a `factory-ssh-known-hosts-device-update` variant that update the
    factory user's known host file for all devices. Would it be useful?

 -  Consider a `device-state-network-reset-to-default` to make easier to switch
    back to default network when something bad occurs (mostly useful for vm).
    This raise the question as to what should be done for non vm case? Should we
    prompt the user, providing him some recent history selection for the values?

 -  When building a device configuration, allow for a cli option to be provided
    to write an `out-link` symlink in `workspaceDir`. This would allow one to
    protect the build from being garbage collected.

    NOTE: Might already be available by specifying the `--out-link` option as
    options are currently forwarded to nix build.

[nix-deploy]: https://awakesecurity.com/blog/deploy-software-easily-securely-using-nix-deploy/
