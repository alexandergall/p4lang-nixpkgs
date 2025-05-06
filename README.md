# p4lang-nixpkgs

This project provides packaging for parts of the [p4lang GitHub
project](https://github.com/p4lang) for the [Nix package
manager](https://nixos.org/). Currently, this is mostly restricted to
a subset that includes the [P4_16 reference
compiler](https://github.com/p4lang/p4c) and its dependencies.

Nix provides reproducible builds and reliable deployments of software
packages that are independent of any specific Linux distribution. It
eliminates all restrictions on build platforms specified by the p4lang
maintainers.

## Contents

Nix packages are provided for the following p4lang repositories

   * [p4c](https://github.com/p4lang/p4c)
   * [PI](https://github.com/p4lang/PI)
   * [p4runtime](https://github.com/p4lang/p4runtime)
   * [behavioral-model](https://github.com/p4lang/behavioral-model)
   * [target-syslibs](https://github.com/p4lang/target-syslibs)
   * [target-utils](https://github.com/p4lang/target-utils)
   * [ptf](https://github.com/p4lang/ptf)

## Usage

An [installation of the Nix package
manager](https://nixos.org/download/) in multi-user mode on a Linux
distribution of your choice is required as a prerequisite (Nix and any
package built with it has no dependencies on the system's native
package manager). The [top-level Nix expression](/default.nix) pins
the [nixpkgs collection](https://github.com/NixOS/nixpkgs) used to
build all components in this repository to a specific version.

To build all packages, execute

```
nix-build -j auto
```

from the top-level directory. Individual packages can be built by
selecting the respective attributes from the set to which the
top-level Nix expression evaluates. This is done by passing the name
of the attribute to `nix-build` with the `-A` option, e.g.

```
nix-build -j auto -A p4c
```

The available attributes are

   * `p4c`
   * `bmv2`
   * `PI`
   * `p4runtime-py` (Python bindings for p4runtime)
   * `ptf`
   * `target-syslibs`
   * `target-utils`

When the build is finished, the symbolic link `result` in the current
directory will point to the location of the package in the Nix store
where the build artifacts are stored

```
~/p4lang-nixpkgs$ nix-build -j auto -A p4c
/nix/store/5bvji8iy6h3qkp0551758gbr57ccmswp-p4c
~/p4lang-nixpkgs$ ls -l result
lrwxrwxrwx 1 gall gall 47 Mar  5 16:34 result -> /nix/store/5bvji8iy6h3qkp0551758gbr57ccmswp-p4c
~/p4lang-nixpkgs$ result/bin/p4c --version
p4c 1.2.5.6
```

Alternatively, the package can be added to the user's
[profile](https://nix.dev/manual/nix/2.24/package-management/profiles)
to appear in the search path with

```
~/p4lang-nixpkgs$ nix-env -f . -A p4c
installing 'p4c'
~/p4lang-nixpkgs$ type p4c
p4c is hashed (/home/gall/.nix-profile/bin/p4c)
```

## Customization

The `p4c` package makes some of its settings overridable by passing an
attribute set to the `p4cOverrides` argument of the function contained
in `default.nix`. This set can contain any of the following attributes

   * `enableTofino`
     * Type: boolean
     * Default: `true`
     * Purpose: enable the Tofino backend
   * `enableBMV2`: BMV2 backend
     * Type: boolean
     * Default: `true`
     * Purpose: enable the BMV2 backend
   * `enableBPF`
     * Type: boolean
     * Default: `true`
     * Purpose: enable the EBPF and uBPF backends
   * `enableDPDK`
     * Type: boolean
     * Default: `true`
     * Purpose: enable the DPDK backend
   * `enableP4TC`
     * Type: boolean
     * Default: `true`
     * Purpose: enable P4TC backend
   * `enableP4FMT`
     * Type: boolean
     * Default: `true`
     * Purpose: enable the P4FMT backend
   * `enableP4CGraphs`
     * Type: boolean
     * Default: `true`
     * Purpose: enable the pc4-graphs backend
   * `doCheck`
     * Type: boolean
     * Default: `false`
     * Purpose: In addition to building the package, also run the test
       suites, executes in a VM
   * `memSize`
      * Type: `integer`
      * Default: 20480
      * Purpose: Size of the memory in MiB assigned to the VM if
        `doCheck` is enabled, ignored otherwise
   * `lintChecks`
     * Type: boolean
     * Default: `false`
     * Purpose: Run the lint tests before building `p4c`, mutually
       exclusive with `doCheck`

The attribute set is passed to the build using `--arg p4cOverrides`, e.g.

```
nix-build -j auto -A p4c --arg p4cOverrides '{ enableTofino = false; enableBMV2 = false; }'
```

## Excercising the test suites

The packaging supports a subset of the test cases provided by the p4c
repository but they are not run by default because some of them
require root privileges. When the `doCheck` attribute is enabled with

```
nix-build -j auto -A p4c --arg p4cOverrides '{ doCheck = true; }'
```

the entire build will be executed in a VM where root privileges are
available (in fact, the entire build is executed as the root user
inside the VM). By default, the VM's memory is set to 20 GiB. This
value needs to be adjusted to match the ressources available on the
build host and the number of cores assigned to the build process. The
number of cores used by `nix-build` is controlled by the `--cores`
option, e.g.

```
nix-build --cores 8 -A p4c
```

The default is to use all available cores.

Building all compiler backends is fairly ressource-intensive. As a
rule of thumb, the amount of memory assigned to the VM should be at
least 1.5GiB times the number of CPU cores. The default can be changed
with the `memSize` option, e.g.

```
nix-build -j auto -A p4c --arg p4cOverrides '{ doCheck = true; memSize = 32*1024; }'
```

Note that the host's kernel needs to have KVM enabled and `/dev/kvm`
must be writeable by the `nixbld` group for the `doCheck` option to
work.

The following test suites are currently **not** supported

   * P4TC
   * eBPF Kernel
   * DPDK
   * Tofino tests requring `bf_switchd` and `tofino-model` (though no
     actual tests appear to exist at this time)

Some of the tests in the `bmv2-ptf` and `bmv2-stf` groups fail
probabilistically when run in parallel. This can be avoided by
reducing the number of cores as explained above. A small number of
tests currently fail consistently:

   * testgen-p4c-bmv2-ptf/action_profile-bmv2.p4
   * testgen-p4c-bmv2-ptf/action_profile_max_group_size_annotation.p4
   * testgen-p4c-bmv2-ptf/action_profile_sum_of_members_annotation.p4
   * testgen-p4c-bmv2-ptf/action_selector_shared-bmv2.p4
   * testgen-p4c-bmv2-ptf/issue297-bmv2.p4
   * ubpf/testdata/p4_16_samples/ipv4-actions_ubpf.p4
   * gtestasm

The lint checks are not set up as CMake test cases like the other
tests. Instead, they are executed explicitely after the configuration
stage when the `lintChecks` option is set. The build will fail when
any of the lint checks fails. Currently, this is the case for the
`clang` lint check.
