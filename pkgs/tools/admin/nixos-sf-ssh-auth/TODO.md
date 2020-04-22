Todo
====

Doc
---

 -  Define the meaning of following concepts (as used throughout this lib):

     -  ssh public key
     -  ssh user
     -  ssh group
     -  device user
     -  all device user set (aka `""`)
     -  final device user
     -  authorized ssh user
     -  auth
     -  auth dir
     -  auth dir config
     -  state
     -  authorized on
     -  authorized always
     -  merge
     -  merge policy
     -  lhs / rhs
     -  inherited
     -  override
     -  nix lib
     -  python tools

 -  Define a mental model for how things work by default:

    This is so that the user knows how things work, in particular with regards to merge.

     -  Supported file formats, default priority, etc.

         -  How to change the supported file formats and their priority.

     -  Ssh public key filenames resolution.

         -  Search paths.
         -  Patterns.
         -  Default patterns and search paths.
         -  How to change the default (locally using json and / or via nix *auth dir config*).

     -  Expansion of *authorized ssh groups* and *authorized ssh users* as part
        of a particular *device user*:

         -  *authorized ssh groups* are expanded on a per *device user* basic
            inside a single *auth dir* resulting in single *authorized ssh group set*.

            So the group definition from within this directory (or anything
            inerhited by this directory) is the only source of truth (i.e: the
            groups are not expanded lazily by eagerly with regards to an *auth
            dir*).

         -  *ssh users* have priority over *ssh groups*.

            Is that even relevant to user?

     -  When merging *device users* from *authorized always* and the various
        *authorized on* definitions into a resulting *authorized* set, the
        following precedence rules apply:

         -  An *authorized on* definition wins over the *authorized always* definition.
         -  *Authorized on* definition priority follows *lexicographical ordering*
            (i.e: `z` *state* wins over an `y` *state*, `1` wins over `0`, etc).

 -  Provide some examples how *nix lib* can be used for concrete use cases.


Nix
---

 -  By default, error when a device user is missing.
    Allow user to opt-in for this rule to be relaxed so that the `""` (all device user) set
    is used as a fallback.


 -  [LRFC-0001](./doc/lrfc/0001.md): Explicit, scoped, in files override of the merge rules

 -  [LRFC-0002](./doc/lrfc/0002.md): Auto expiring ssh authorization

Python
------

 -  Tools to manage groups / users and auth.

 -  Query tools through nix.

### Ideas

 -  For the query tools, it would be nice that the tools distinguish between
    items that could be managed through the python tool vs those that are
    inherited / fixed (obtained through nix) and thus read-only.

    Colouring might be a good way to do that (greyed out items for ro).

 -  Query tools option to show the source file for each item.

    This information is already part of the nix level item so it is
    only a matter of exposing it.
