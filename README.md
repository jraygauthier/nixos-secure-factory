Readme
======

This is a set of tools meant to help one securely factory install and update
[nixos] devices with both os configuration but also with a set of *secrets*.

The secrets part is handled using the [gopass] tool while the os configuration
is handled by [nixos].

The main secret of a device is its [gnupg] identity which allows through
[gopass] to securely retrieve new updates for its secrets.

This repository also provide a set of [virtualbox] helpers meant to test
device factory install and update process easily.


[gopass]: https://github.com/gopasspw/gopass
[nixos]: https://nixos.org/
[gnupg]: https://gnupg.org/
[virtualbox]: https://www.virtualbox.org/


Usage
-----

## Initial setup

See [initial setup](./doc/InitialSetup.md) page.


Concepts
--------

See [concepts](./doc/Concepts.md) page.



External tools / extensions
---------------------------

Those are standalone tools that were developed as a mean of extending the
capabilities of the current framework but that can even find uses outside of it.

 -  [nsf-ssh-auth]

    A nix lib to simplify the management of ssh public keys allowed remote
    access to individual linux users. This introduce the concept of a *ssh auth
    dir* which allows to define users, groups, per device user authorizations
    and much more.

    It comes with a nice command line helper whose underlying library is used by
    some of `nixos-sf-factory-install` tools, namely
    `device-common-ssh-auth-dir` and `device-ssh-auth-dir` to respectively allow
    authorizations throughout all devices and on a per device basis.

 -  [nsf-atlassian-tools]

    Of particular interest, provides a cli helper to manage **ssh authorizations**
    to [bitbucket] repositories via its rest api (in case you chose to host your
    repositories on [bitbucket]).

    It is then easy to build over this:

     -  so that credentials / tokens to operate the tools are stored (for
        example) as part of your factory secret gopass vault (avoiding the need
        to remember those)
     -  profiting from the *current device* concept and the fact that its public
        ssh key (or that of any other devices) is known and stored in the gopass
        vault to avoid having to copy paste this information.

    Using [bitbucket] is really a pretty nice **zero infrastructure** and
    **free** mean of distributing **system updates** to your devices.

 -  [nsf-zerotier-tools]

    Of particular interest, provide a cli helper to manager authorization to one
    or many [zerotier] (a distributed vpn) **private network(s)** of machines
    (in case you chose to use this technology to interconnect your devices).

    Same kind of integration is possible as the bitbucket tool above.

    Using [zerotier] is really a pretty nice **zero infrastructure** and
    **free** mean of **remote access** to your devices (e.g.: through ssh, vnc,
    sftp, etc) even though these are *behind firewalls*.

[nsf-ssh-auth]: https://github.com/jraygauthier/nsf-ssh-auth
[nsf-atlassian-tools]: https://github.com/amotus/nsf-atlassian-tools
[nsf-zerotier-tools]: https://github.com/amotus/nsf-zerotier-tools

[bitbucket]: https://bitbucket.org
[zerotier]: https://www.zerotier.com/


Todo
----

A listing of some things that can be done to improve this project, including
some ideas:

[TODO](./TODO.md)


What this tool is not made / ideal for
--------------------------------------

 -  Deployment / provisioning of private cloud machines.

    See instead [nixops] or even [disnix] (the latter in case of
    service-oriented deployment).


[nixops]: https://github.com/NixOS/nixops
[disnix]: https://github.com/svanderburg/disnix


Contributing
------------

Contributing implies licensing those contributions under the terms of [LICENSE](./LICENSE), which is an *Apache 2.0* license.


Acknowledgements
----------------

Thanks to [Zilia Health] for being the first innovative corporate user /
supporter of this project allowing it to grow both in quality and features.

[Zilia Health]: https://ziliahealth.com/
