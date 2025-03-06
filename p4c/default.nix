{ lib
, stdenv
, fetchFromGitHub
, bmv2
, ptf
, PI-py
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
, git

  ## Some checks can only be run inside a VM, turn off by default
,  doCheck ? false

  ## Configure options
,  enableTofino ? true
,  enableBMV2 ? true
,  enableBPF ? true
,  enableDPDK ? true
,  enableP4TC ? true
,  enableP4FMT ? true
,  enableP4CGraphs ? true
  
  ## For ebpf test cases
, elfutils

  ## For various tests
, iproute2
, procps
, iptables
, tcpdump
, libpcap
, gmp
}:

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
  ## The dev output of the standard spdlog is missing
  ## include/spdlog/fmt/bundled
  spdlog = fetchFromGitHub {
    repo = "spdlog";
    owner = "gabime";
    ## From backends/tofino/cmake/spdlog.cmake
    rev = "v1.8.3";
    sha256 = "1qcabdc3yrm30vapn7g7lf3bwjissl15y66mpmx2w0gjjc6aqdd1";
  };
in stdenv.mkDerivation rec {
  name = "p4c";
  version = "1.2.5.4";
  src = fetchFromGitHub {
    repo = "p4c";
    owner = "p4lang";
    rev = "v${version}";
    hash = "sha256-0BZtPqUH4GMzQ8EnkzUkLnQQyryjdp0HVJ0tCR3AlXI=";
    ## The version logic in CMakeLists.txt uses git rev-parse to add
    ## the commit hash to P4C_VERSION
    leaveDotGit = true;
  };
  passthru = {
    inherit src;
  };
  patches = [
    ## Some eBPF tests fail with stack protection enabled, which is
    ## the default for our version of clang
    ./disable-stack-protection.patch

    ## Allow overrides via cmakeFlags, see below
    ./make-bmv2-path-overridable.patch

    ## Fix shell function references
    ./fix-driver-tests.patch
  ];
  
  nativeBuildInputs =
    [ cmake flex bison pkg-config rapidjson llvm clang clang-tools llvm
      libbpf python3.pkgs.wrapPython git

      (python3.withPackages (pkgs:
        with pkgs; [ jsl jsonschema ] ++
                   lib.optionals doCheck [ scapy ply nnpy PI-py ]))
      
      ## find_package() for Protobuf complains about not finding zlib,
      ## but we probably don't really need this
      zlib.static
                  
      ## Add the spdlog header files to NIX_CFLAGS_COMPILE directly
      ## from the source archive
      spdlog

      ## Used to bundle p4c-build-logs into a standalone
      ## executable
      python3.pkgs.pyinstaller
    ];
  buildInputs = [ boost z3 abseil-cpp protobuf boehmgc libbacktrace ];
  nativeCheckInputs = [
    ## For BMV2 tests
    bmv2
                  
    ## For ebpf tests
    elfutils
                  
    ## For various tests
    libpcap gmp gtest
    iproute2 procps iptables tcpdump ptf
  ];
  cmakeFlags = [
    "-DENABLE_TOFINO=${toCMakeBoolean enableTofino}"
    "-DENABLE_BMV2=${toCMakeBoolean enableBMV2}"
    "-DENABLE_EBPF=${toCMakeBoolean enableBPF}"
    "-DENABLE_UBPF=${toCMakeBoolean enableBPF}"
    "-DENABLE_DPDK=${toCMakeBoolean enableDPDK}"
    "-DENABLE_P4TC=${toCMakeBoolean enableP4TC}"
    "-DENABLE_P4FMT=${toCMakeBoolean enableP4FMT}"
    "-DENABLE_P4C_GRAPHS=${toCMakeBoolean enableP4CGraphs}"

    ## Flags derived from doCheck
    "-DENABLE_GTESTS=${toCMakeBoolean doCheck}"
    "-DENABLE_P4TEST=${toCMakeBoolean doCheck}"

    "-DP4C_USE_PREINSTALLED_ABSEIL=ON"
    "-DP4C_USE_PREINSTALLED_PROTOBUF=ON"
    "-DP4C_USE_PREINSTALLED_BDWGC=ON"
    "-DUSE_PREINSTALLED_Z3=ON"

    ### Override CMake's FetchContent mechanism to use a pre-declared
    ### source repository. This will make FetchContent_MakeAvailable()
    ### skip the download.
    "-DFETCHCONTENT_SOURCE_DIR_P4RUNTIME=${p4runtime}"

    ## libbpf doesn't have a "USE_PREINSTALLED", but it uses
    ## find_library() to check for a previously built library. By
    ## supplying a random existing location here, find_library() will
    ## actually find the library supplied by the libbpf package,
    ## i.e. it acts as one would expect with a "USE_PREINSTALL" flag
    "-DFETCHCONTENT_SOURCE_DIR_BPFREPO=."

  ] ++ lib.optionals enableTofino [
    ## This is only to please FetchContent, the spdlog header files
    ## are integrated through buildInputs
    "-DFETCHCONTENT_SOURCE_DIR_SPDLOG=."
  ] ++ lib.optionals doCheck [
    "-DFETCHCONTENT_SOURCE_DIR_GTEST=${googletest}"
    
    ### Override search paths for components of bmv2, used for BMV2
    ### tests. FindBMV2.cmake initializes these paths to relative
    ### paths that point to pre-built binaries outside the p4c source
    ### directory. These overrdies turn that into proper build
    ### dependencies. The variables have to be marked as cacheable for
    ### this to work, see patches above.
    "-DBMV2_SIMPLE_SWITCH_SEARCH_PATHS=${bmv2}/bin"
    "-DBMV2_PSA_SWITCH_SEARCH_PATHS=${bmv2}/bin"
    "-DBMV2_SIMPLE_SWITCH_GRPC_SEARCH_PATHS=${bmv2}/bin"
    "-DBMV2_PNA_NIC_SEARCH_PATHS=${bmv2}/bin"
  ];
  enableParallelBuilding = true;
  inherit doCheck;
  preConfigure =
    ### Protobuf is very picky about version number matches
    ''
      substituteInPlace cmake/Protobuf.cmake \
        --replace-fail 25.3 25.3.0
    '' +

    ### Link libbpf to the place where the non-overriden
    ### FetchContent_MakeAvailable() would put it
    ''
      mkdir -p backends/ebpf/runtime/usr/lib64
      ln -s ${libbpf}/lib/libbpf.a backends/ebpf/runtime/usr/lib64

      patchShebangs backends tools/driver/test_scripts
    '' +

    ### The Tofino backend requires an assembler (bfas), which is
    ### currently provided by open-p4studio. The latter contains the
    ### p4c repo as a submodule and builds its own instance of the
    ### compiler together with bfas and bfas ends up in the same bin
    ### directory as the compiler. At runtime, the Tofino p4c driver
    ### searches for bfas in that directory. This is done by first
    ### setting the environment variable P4C_BIN_DIR to the directory
    ### where p4c is located and then using that variable when
    ### searching for bfas. This somewhat convoluted procedure doesn't
    ### work for us because we use the this pre-built compiler package
    ### when building open-p4studio. To solve this problem, we modify
    ### the Barefoot driver to look for bfas via a new environment
    ### variable BFAS_BIN_PATH and have the open-p4studio environment
    ### generate a wrapper around p4c such that the driver can find
    ### bfas within the open-p4studio package (the "p4-compiler"
    ### sub-package, to be precise).
    lib.optionalString enableTofino ''
      substituteInPlace backends/tofino/bf-p4c/driver/barefoot.py \
        --replace-fail "['P4C_BIN_DIR'], 'bfas')" "['BFAS_BIN_DIR'], 'bfas')"
    '';

  ## Some checks use clang's cpp. The version we're using has
  ## -Wnunused-command-line-argument enabled by default which produces
  ## a huge amount of warnings due to all -L options passed in via
  ## NIX_LDFLAGS.
  preCheck = ''
    patchShebangs p4c */testdata p4c
    NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -Wno-unused-command-line-argument"
  '';

  ## Aggregated dependencies for Python scripts in $out/bin
  pythonpath =  python3.withPackages (pkgs: with pkgs; [ jsonschema jsl ]);
  postInstall = ''
    wrapPythonPrograms    
  '' +
  ## Used for building bf-asm in open-p4studio
  lib.optionalString enableTofino ''
    cp backends/tofino/bf-p4c/git_sha_version.h $out/share/p4c
  '';
}
