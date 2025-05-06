# p4lang-nixpkgs

This project provides packaging for parts of the [p4lang project on
Github](https://github.com/p4lang) for the [Nix package
manager](https://nixos.org/). Currently, this is restricted to a
[subset](#contents) that includes the [P4_16 reference
compiler](https://github.com/p4lang/p4c) and its dependencies.

## Usage

This repository requires an [installation of the Nix package
manager](https://nixos.org/download/) in multi-user mode as a
prerequisite on a Linux distribution of your choice (Nix and any
package built with it has no dependencies on the system's native
package manager). The [top-level Nix expression](/default.nix) pins a
specific version of the nixpkgs collection to be used by all packages
provided by this repository.

The p4c compiler with default options can be built by running

```
nix-build -j auto -A p4c
```

from the top-level directory. A customized version can be built by
overriding any of the configuration options

   * `enableTofino`: Tofino backend
   * `enableBMV2`: BMV2 backend
   * `enableBPF`: EBPF and uBPF backends
   * `enableDPDK`: DPDK backend
   * `enableP4TC`: P4TC backend
   * `enableP4FMT`: P4FMT backend
   * `enableP4CGraphs`: p4c-graphs backend

by adding corresponding `--arg` arguments, e.g.

```
nix-build -j auto -A p4c --arg enableTofino false
```

All of the options have a default value of `true`. When the build is
finished, the symbolic link `result` in the current directory will
point to the location of the package in the Nix store where the build
artifacts are stored

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

To run the lint checks before building use (the build will fail if any
of the lint checks fail)

```
nix-build -j auto -A p4c-with-lint
```

The packaging supports a subset of the test cases provided by the p4c
repository but they are not run by default because some of them
require root privileges. To build the package and also excercise the
tests, execute

```
nix-build -j auto -A p4c-with-checks
```

This will run the build and the test cases inside a VM where root
privileges are available. By default, the VM's memory is set to 20
GiB. This value needs to be adjusted to match the ressources available
on the build host and the number of cores assigned to the build
process (defaulting to all available cores). For example, to limit the
number of cores to 8 and the memory to 16 GiB one would use

```
nix-build --cores 8 -j auto -A p4c-with-checks --arg memSize $((16*1024))
```

Note that the host's kernel needs to have KVM enabled and `/dev/kvm`
must be writeable by the `nixbld` group for this to work.

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

## <a name="contents"></a>Packaged p4lang repositories

   * [p4c](https://github.com/p4lang/p4c)
   * [PI](https://github.com/p4lang/PI)
   * [behavioral-model](https://github.com/p4lang/behavioral-model)
   * [target-syslibs](https://github.com/p4lang/target-syslibs)
   * [target-utils](https://github.com/p4lang/target-utils)
   * [ptf](https://github.com/p4lang/ptf)
