### Run a given set of CMake check targets in a separate
### derivation. The p4c we're called with is already overridden with
### doCheck and delayedChecks set, i.e. it provides a "build" output
### that contains the full build tree from p4c. The output of the
### derivation produced here contains the files
###
###   * log
###     The output of "make $checkTargets"
###   * rc
###     The return code of the make, 0 indicates that all checks
###     succeeded
###   * checks
###     The list of checks that were executed (i.e. checkTargets)
###
### Some checks may fail due to parallel execution or race
### conditions. To re-run a check, the out path has to be deleted
### first.

{ lib, stdenv, vmTools, p4c, memSize, checkTargets }:

let
  ## From "make help"
  availableCheckTargets = [
    "check"
    "check-all"
    "check-bmv2"
    "check-bmv2-parser-inline-opt-disabled"
    "check-bmv2-parser-inline-opt-enabled"
    "check-bmv2-ptf"
    "check-dpdk"
    "check-ebpf"
    "check-ebpf-bcc"
    "check-ebpf-errors"
    "check-ebpf-kernel"
    "check-err"
    "check-graph"
    "check-p14_to_16"
    "check-p4"
    "check-testgen-p4c-bmv2-metadata"
    "check-testgen-p4c-bmv2-protobuf-ir"
    "check-testgen-p4c-bmv2-ptf"
    "check-testgen-p4c-bmv2-stf"
    "check-testgen-p4c-ebpf"
    "check-testgen-p4c-pna-metadata"
    "check-testgen-tofino"
    "check-testgen-tofino-ptf"
    "check-testgen-tofino2"
    "check-testgen-tofino2-ptf"
    "check-ubpf"
  ];
in

assert lib.asserts.assertEachOneOf "checkTargets" checkTargets availableCheckTargets;

vmTools.runInLinuxVM (stdenv.mkDerivation {
  name = "p4c-checks";
  src = p4c.build;
  inherit (p4c) buildInputs nativeBuildInputs hardeningDisable;
  inherit memSize checkTargets;
  phases = [ "unpackPhase" "buildPhase" "checkPhase" ];
  doCheck = true;
  enableParallelBuilding = true;

  ## Propagate the build output to make it accessible with
  ## nix-build -A p4c.build --arg p4cOverrides '{ doCheck = true; delayedChecks = true; }'
  passthru = { inherit (p4c) build; };

  ## What we do here is borderline illegal :) The build-tree contains
  ## references to absolute paths in the build environment of the p4c
  ## derivation and we have to make these paths valid in the current
  ## build. For a derivation built without vmTools, the build tree is
  ## located under /build, but inside a VM it's located under
  ## /tmp. This is an implementation detail that we shouldn't rely on.
  ##
  ## Also, the -j option for ctest is fixed during the creation of the
  ## build output but we'd like to be able to set the number of
  ## parallel jobs when building this derivation (wiht "nix-build
  ## --cores")
  preBuild = ''
    mkdir /build
    mv source /build
    cd /build/source/build
    for f in $(find . -type f | xargs grep "ctest -j" | awk -F: '{print $1}'); do
      sed -iEe "s/ctest -j [0-9]*/ctest -j $NIX_BUILD_CORES/g" $f
    done
  '';

  checkPhase =
    ## We're not executing the cmakeConfigurePhase and preCheck hooks
    ## of p4c, so re-create the relevant settings here
    ''
      export CTEST_OUTPUT_ON_FAILURE=1
      NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -Wno-unused-command-line-argument"
    '' +

    ## Execute the checks, save the output and result
    ''
      echo $checkTargets >$out/checks
      set +e
      make VERBOSE=y $checkTargets 2>&1 | tee $out/log
      echo $? >$out/rc
      set -e
    '';
})
