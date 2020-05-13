Concepts
========

 -  *device config repository*:

    The repository / directory that contains the whole / self-contained *nixos
    system configuration* required to build any of the devices managed by the
    particular *nixos-secure-factory* system.

    See `../demo-nixos-config` for a example.

    This is also generally the point of entry for the *device update system* and
    should also points to a *pinned version* of the *device secrets repository*
    (that is when the device secrets are defined outside of the *device config
    repository*).

 -  *device secrets repository*:

    The repository / directory that contains the secrets required to initialize
    and update any of the devices managed by the particular
    *nixos-secure-factory* system.

    It is possible to decide for the *device secrets repository* to be hosted in
    the same *git repository* / directory then the *device config repository*.
    Note that this is not particularly recommanded as it can make the
    configuration heavier in the long run.

    Example at <https://github.com/jraygauthier/nixos-sf-demo-device-secrets>.

 -  *factory install repository*:

    The repository / directory that contains all the tools required to
    *factory install* devices particular types and later manage those
    devices (remote access, experimentation, system updates, etc).

 -  *device identity*:

    A mean to uniquely identify a particular *device instance*.

    Example in
    [`../demo-nixos-config/device/demo-virtual-box-vm/device.json`](../demo-nixos-config/device/demo-virtual-box-vm/device.json).

    As you can see, a device's identity is *multifaceted*:

     -  `identity`:

        The id used to refer to the device as part of the particular
        *nixos-secure-factory* framework.

     -  `hostname` / `ssh-port`:

        The id used to refer to the device as part of the local network.

     -  `email`:

        A potentially inexistant (yet) email account used to identify the device
        as part of the the gpg and ssh keypairs. Can be optionally used as the
        sender when sending diagnostic / error emails to whomever responsible.

     -  `gpg-id`:

        The gpg public key fingerprint of the device. Currently used as the mean
        to securely distribute secrets to the device as part of *device update
        system*. This as many other potential uses (signing email, commits,
        etc).

     -  `uart-pty`

        The serial port used to communicate with the device when *factory
        installed*.

    Outside of `device.json` some other parts of the device's identity can be
    found:

     -  *root user ssh public key*:

        Potentially used to authorize a device to some ressources such as
        private repositories (e.g. git) required to retrieve some system updates
        components.

     -  *host ssh public key*:

        Help prevent *man in the middle* attack when accessing the device.

 -  *device instance*:

    A concrete machine of a particular *device type* that has a particular
    *device identity*, a set of *device secrets* and is associated to a set of
    *factory only device secrets*. It can optionally define some arbitrary nixos
    customizations.

 -  *device type*:

    A concrete machine ready to be *instanciated* (aka made into a *device
    instance*). The only thing that is missing is the *device identity*.

    This is generally where the **hw specific** stuff will be defined.

    Two distinct parts are required to defined a full *device type*:

     -  one under the *device config repository*:

        This is the declarative nixos configuration.

        Example under
        [`../demo-nixos-config/device-type/virtual-box-vm`](../demo-nixos-config/device-type/virtual-box-vm).

     -  another under the *factory install repository*:

        This is the script package required to format and partition the device's
        hard drives but also to boostrap the initial nixos configuration and
        install the initial device secrets.

        Example under
        [`../device-type/virtual-box-vm/scripts/install`](../device-type/virtual-box-vm/scripts/install).

 -  *device family*:

    This is where the commonalities between multiple types of devices are
    generally defined (the services, packages available as part of the
    environment, network configuration, etc).

 -  *ssh auth dir*

    TODO: Doc.

 -  *initial device secrets*

    TODO: Doc.
