# p4lang-nixpkgs

This project provides packaging for parts of the [p4lang project on
Github](https://github.com/p4lang) for the [Nix package
manager](https://nixos.org/). Currently, this is restricted to a
[subset](#contents) that includes the [P4_16 reference
compiler](https://github.com/p4lang/p4c) and its dependencies.

## Usage

This repository requires an [installation of the Nix package
manager](https://nixos.org/download/) in multi-user mode as a
prerequisite. The top-level [Nix expression](/default.nix) pins a
specific version of the nixpkgs collection to be used by all packages
provided by this repository.

The p4c compiler with default options can be built by running

```
~/p4lang-nixpkgs$ nix-build -j auto -A p4c
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
~/p4lang-nixpkgs$ nix-build -j auto -A p4c --arg enableTofino false
```

All of the options have a default value of `true`. When the build is
finished, the symbolic link `result` in the current directory will
point to the location of the package in the Nix store where the build
artifacts are stored

```
~/p4lang-nixpkgs$ nix-build -j auto -A p4c
/nix/store/mhcm0666ya43kqfk878zvxyzbz4vyjmd-p4c
~/p4lang-nixpkgs$ ls -l result
lrwxrwxrwx 1 gall gall 47 Mar  5 16:34 result -> /nix/store/mhcm0666ya43kqfk878zvxyzbz4vyjmd-p4c
~/p4lang-nixpkgs$ result/bin/p4c --version
p4c 1.2.5.4 (SHA: 3551e70 BUILD: Release)
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

The packaging supports a subset of the test cases provided by the p4c
repository but they are nor run by default because some of them
require root privileges. To build the package and also excercise the
tests, execute

```
~/p4lang-nixpkgs$ nix-build -j auto -A p4c-with-checks
```

This will run the build and the test cases inside a VM where root
privileges are available.

## <a name="contents"></a>Packaged p4lang repositories

   * [p4c](https://github.com/p4lang/p4c)
   * [PI](https://github.com/p4lang/PI)
   * [behavioral-model](https://github.com/p4lang/behavioral-model)
   * [target-syslibs](https://github.com/p4lang/target-syslibs)
   * [target-utils](https://github.com/p4lang/target-utils)
   * [ptf](https://github.com/p4lang/ptf)
