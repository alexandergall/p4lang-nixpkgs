{ lib
, stdenv
, fetchFromGitHub
, vmTools
, bmv2
, ptf
, p4runtime-py
, cmake
, python3
, flex
, bison
, abseil-cpp
, protobuf
, boost
, boehmgc
, z3
, pkg-config
, rapidjson
, clang
, clang-tools
, zlib
, llvm
, libbpf
, gtest
, libbacktrace

  ## Some checks can only be run inside a VM, turn off by
  ## default. memSize is the memory assigned to the VM, change to
  ## match your setup. If delayedChecks is true, the checks are
  ## configured but not executed. Instead, the entire build tree is
  ## exported as additional output "build" and the checks listed in
  ## checkTargets are executed in a separate derivation. checkTargets
  ## is ignored if delayedChecks is false.
, doCheck ? false
, delayedChecks ? false
, checkTargets ? [ "check" ]
, memSize ? 20*1024

  ## Run the lint checks before building p4c. The Build will fail if
  ## any of the checks fail
, lintChecks ? false

  ## Configure options
, enableTofino ? true
, enableBMV2 ? true
, enableBPF ? true
, enableDPDK ? true
, enableP4TC ? true
, enableP4FMT ? true
, enableP4CGraphs ? true
  
  ## For ebpf test cases
, elfutils

  ## For p4tools testgen
, inja

  ## For lint checks
, black
, isort

  ## For various tests
, iproute2
, procps
, iptables
, tcpdump
, libpcap
, gmp
}:

assert lintChecks -> ! doCheck;
assert delayedChecks -> doCheck;
let
  toCMakeBoolean = v: if v then "ON" else "OFF";
  googletest = fetchFromGitHub {
    repo = "googletest";
    owner = "google";
    ## From cmake/GoogleTest.cmake
    rev = "f8d7d77c06936315286eb55f8de22cd23c188571";
    sha256 = "19c7f248rkg302yrbl5x7irfyi6a9whbpf45wn4bn9fk0625qi5p";
  };
  p4runtime = fetchFromGitHub {
    repo = "p4runtime";
    owner = "p4lang";
    ## From CMakeLists.txt
    rev = "ec4eb5ef70dbcbcbf2f8357a4b2b8c2f218845a5";
    sha256 = "03xycmagalns7xwldw45z44wpcylj1wvjv5fnnzskkfchdq5wg3y";
  };
  spdlog = fetchFromGitHub {
    repo = "spdlog";
    owner = "gabime";
    ## From backends/tofino/cmake/spdlog.cmake
    rev = "v1.8.3";
    sha256 = "1qcabdc3yrm30vapn7g7lf3bwjissl15y66mpmx2w0gjjc6aqdd1";
  };
  p4c = stdenv.mkDerivation (rec {
    pname = "p4c";
    version = "1.2.5.6";
    src = fetchFromGitHub {
      repo = "p4c";
      owner = "p4lang";
      rev = "v${version}";
      hash = "sha256-65wOacVvbdOlRhOsk8CjtQM+ugsPyNNBaJ9qslkw/i8=";
    };

    patches = [
      ## Allow overriding variables via cmakeFlags, see below
      ./cmake-cache-variables.patch

      ## Fix shell function references
      ./fix-driver-tests.patch
    ];

    nativeBuildInputs =
      [ cmake flex bison pkg-config rapidjson llvm clang clang-tools llvm
        libbpf python3.pkgs.wrapPython

        (python3.withPackages (pkgs:
          with pkgs; [ jsl jsonschema pyyaml ] ++
                     lib.optionals doCheck [ scapy ply nnpy p4runtime-py ]))

        ## find_package() for Protobuf complains about not finding zlib,
        ## but we probably don't really need this
        zlib.static

        ## Used to bundle p4c-build-logs into a standalone
        ## executable
        python3.pkgs.pyinstaller
      ] ++ lib.optionals lintChecks [ black isort ];
    buildInputs = [ boost z3 abseil-cpp protobuf boehmgc libbacktrace ];
    nativeCheckInputs = [
      ## For BMV2 tests
      bmv2

      ## For ebpf tests
      elfutils

      ## For p4tools testgen
      inja

      ## For various tests
      libpcap gmp gtest
      iproute2 procps iptables tcpdump ptf

      ## For the lint checks
      black isort
    ];
    outputs = [ "out" ] ++ lib.optional delayedChecks "build";

    cmakeFlags = [
      "-DENABLE_TOFINO=${toCMakeBoolean enableTofino}"
      "-DENABLE_BMV2=${toCMakeBoolean enableBMV2}"
      "-DENABLE_EBPF=${toCMakeBoolean enableBPF}"
      "-DENABLE_UBPF=${toCMakeBoolean enableBPF}"
      "-DENABLE_DPDK=${toCMakeBoolean enableDPDK}"
      "-DENABLE_P4TC=${toCMakeBoolean enableP4TC}"
      "-DENABLE_P4FMT=${toCMakeBoolean enableP4FMT}"
      "-DENABLE_P4C_GRAPHS=${toCMakeBoolean enableP4CGraphs}"

      ## For backends/p4tools/CMakeLists.txt, also see comment on
      ## P4C_VERSION below
      "-DP4C_SEM_VERSION_STRING=${version}"

      ## Flags derived from doCheck
      "-DENABLE_GTESTS=${toCMakeBoolean doCheck}"
      "-DENABLE_P4TEST=${toCMakeBoolean doCheck}"
      "-DENABLE_TEST_TOOLS=${toCMakeBoolean doCheck}"

      ## Enable pre-installed dependencies
      "-DP4C_USE_PREINSTALLED_ABSEIL=ON"
      "-DP4C_USE_PREINSTALLED_BDWGC=ON"
      "-DUSE_PREINSTALLED_Z3=ON"
      "-DP4C_USE_PREINSTALLED_PROTOBUF=ON"

      ## The non-pre-installed branch of p4c_obtain_protobuf in
      ## cmake/Protobuf.cmake has the comment
      ##  Protobuf does not seem to set Protobuf_INCLUDE_DIRS correctly
      ## and proceeds to set it explicitly. There is no corresponding
      ## workaround in the pre-installed branch, so add it
      ## here. find_package() should discover this automatically,
      ## though.
      "-DProtobuf_INCLUDE_DIRS=${protobuf}/include"

      ### Override CMake's FetchContent mechanism to use pre-declared
      ### source repositories. This will make
      ### FetchContent_MakeAvailable() skip the download. Ideally,
      ### those should also have an optional "USE_PREINSTALLED".
      "-DFETCHCONTENT_SOURCE_DIR_P4RUNTIME=${p4runtime}"
      "-DFETCHCONTENT_SOURCE_DIR_INJA=${inja}"

      ## libbpf doesn't have a "USE_PREINSTALLED", but it uses
      ## find_library() to check for a previously built library. By
      ## supplying a random existing location here, find_library() will
      ## actually find the library supplied by the libbpf package,
      ## i.e. it acts as one would expect with a "USE_PREINSTALL" flag
      "-DFETCHCONTENT_SOURCE_DIR_BPFREPO=."

    ] ++ lib.optionals doCheck [
      "-DFETCHCONTENT_SOURCE_DIR_GTEST=${googletest}"

      ### Override search paths for components of bmv2, used for BMV2
      ### tests. FindBMV2.cmake initializes these paths to relative
      ### paths that point to pre-built binaries outside the p4c
      ### source directory. These overrides turn that into proper
      ### build dependencies but for it to work the variables have to
      ### be marked as cacheable, see patches above.
      "-DBMV2_SIMPLE_SWITCH_SEARCH_PATHS=${bmv2}/bin"
      "-DBMV2_PSA_SWITCH_SEARCH_PATHS=${bmv2}/bin"
      "-DBMV2_SIMPLE_SWITCH_GRPC_SEARCH_PATHS=${bmv2}/bin"
      "-DBMV2_PNA_NIC_SEARCH_PATHS=${bmv2}/bin"
    ];

    enableParallelBuilding = true;
    inherit doCheck;
    hardeningDisable = lib.optionals doCheck [
      ## The BPF clang target doesn't like these
      "stackprotector"
      "zerocallusedregs"
    ];

    preConfigure =
      ''
        patchShebangs backends tools
      '' +

      ### Set the version explicitly, otherwise CMake will atempt to use
      ### git to determine the commit hash, which fails because our
      ### source doesn't have .git (and using leaveDotGit in
      ### fetchFromGitHub is not deterministic).
      ''
        export P4C_VERSION=${version}
      '' +

      ### Protobuf is very picky about version number matches
      ''
        substituteInPlace cmake/Protobuf.cmake \
          --replace-fail 25.3 25.3.0
      '' +

      lib.optionalString doCheck
      ## Disable fetching of inja completely. It is sufficient to
      ## declare the standard inja package in nativeCheckInputs for
      ## the header files to be found. Note that unless we remove the
      ## "PUBLIC inja" declaration, CMake will generate a bogus -linja
      ## option for the linker that will make it exit with a
      ## file-not-found error.
      ''
        sed -i -e '/fetchcontent_makeavailable_but_exclude_install(inja)/d;/PUBLIC inja/d' backends/p4tools/modules/testgen/CMakeLists.txt
      '' +

      ### Pre-populate spdlog to avoid FetchContent
      lib.optionalString enableTofino
      ''
        mkdir -p backends/tofino/third_party
        ln -s ${spdlog} backends/tofino/third_party/spdlog
      '' +

      ### Create symlinks to the libbpf package in the place expected
      ### by the test environment. Disable the check for the libc
      ### version to enable the ebpf kernel test (that check does not
      ### work in the VM and we know that our libc is ok).
      lib.optionalString (doCheck && enableBPF)
      ''
        mkdir -p backends/ebpf/runtime/usr/lib64
        ln -s ${libbpf}/lib/libbpf.a backends/ebpf/runtime/usr/lib64

        sed -i -e 's/check_minimum_linux_libc_version.*$/set (SUPPORTS_LIBC TRUE)/' backends/ebpf/CMakeLists.txt
      '';

    ### The lint checks are not provisioned as regular CMake tests.
    ### In the P4lang CI system, they are run explicitly by the GitHub
    ### workflow job ci-lint.yaml. We run them explicitly here when
    ### requested.
    postConfigure = lib.optionalString lintChecks ''
      echo "Running lint checks"
      cmake --build . --target cpplint
      cmake --build . --target clang-format
      cmake --build . --target black
      cmake --build . --target isort
    '';

    preCheck =
      ## Some checks use clang's cpp. The version we're using has
      ## -Wnunused-command-line-argument enabled by default which produces
      ## a huge amount of warnings due to all -L options passed in via
      ## NIX_LDFLAGS.
      ''
        patchShebangs p4c */testdata testgen/*
        NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -Wno-unused-command-line-argument"
      '';

    ## Aggregated dependencies for Python scripts in $out/bin
    pythonpath =  python3.withPackages (pkgs: with pkgs; [ jsonschema jsl ]);
    postInstall = ''
      wrapPythonPrograms
    '' +

    ## open-p4studio expects p4c to be called bf-p4c
    lib.optionalString enableTofino
    ''
      ln -sr $out/bin/p4c $out/bin/bf-p4c
    '' +

    ## Create the "build" output containing the complete source +
    ## build trees to run the checks in a separate derivation
    lib.optionalString delayedChecks
    ''
      mkdir $build
      tar -C ../.. -cf - source | tar -C $build -xf -
    '';
  } //
  ## Skip the actual checks when producing the "build" output
  lib.optionalAttrs delayedChecks {
    checkPhase = "true";
  });
in
if (doCheck && ! delayedChecks) then
  vmTools.runInLinuxVM
    (p4c.overrideAttrs {
      inherit memSize;
    })
else
  if delayedChecks then
    import ./run-checks.nix {inherit lib stdenv vmTools p4c memSize checkTargets; }
  else
    p4c
