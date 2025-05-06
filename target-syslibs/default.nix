{ stdenv
, fetchFromGitHub
, cmake
}:

stdenv.mkDerivation {
  pname = "target-syslibs";
  version = "v1.0.0-7-g240969c";
  src = fetchFromGitHub {
    repo = "target-syslibs";
    owner = "p4lang";
    rev = "240969c";
    sha256 = "14xs9linc8l8ah7dqyj5i8wgsy1lmy6wjxkr49v84r0701ki7s5s";
    fetchSubmodules = true;
  };
  nativeBuildInputs = [ cmake ];
  
  cmakeFlags = [
    ## CMakeLists.txt declares
    ##
    ##   set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_INSTALL_PREFIX}/lib")
    ##   set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_INSTALL_PREFIX}/lib")
    ##
    ## This causes the buildPhase to create the library directly in the
    ## out path, which causes a subtle issue in the installPhase. The
    ## problem is that cmake generates a "RPATH_CHECK" by default in an
    ## intermediate cmake file:
    ##
    ##   file(RPATH_CHECK
    ##        FILE "$ENV{DESTDIR}/tmp/out/lib/libtarget_sys.so"
    ##        RPATH "")
    ##
    ## This is an internal CMake call that effectively delets a file if
    ## the RPATH is not empty, which is guaranteed with Nix. This option
    ## disables the check.  An alternative way to avoid this problem would
    ## be to remove the declarations for OUTPUT_DIRECTORY.
    "-DCMAKE_SKIP_RPATH=ON"
  ];
}
