{ stdenv
, fetchFromGitHub
, autoreconfHook
, readline
, pkg-config
, protobuf
, grpc
, boost
}:

stdenv.mkDerivation (finalArgs: {
  pname = "PI";
  version = "v0.1.4";
  src = fetchFromGitHub {
    repo = "PI";
    owner = "p4lang";
    rev = "${finalArgs.version}";
    hash = "sha256-5WxrhsvcZwA5cgTTQ2uc7/l1/33HY1dNa9O28Tzkptk=";
    fetchSubmodules = true;
  };
  nativeBuildInputs = [ autoreconfHook pkg-config ];
  buildInputs = [ readline protobuf grpc boost ];
  enableParallelBuilding = true;
  configureFlags = [
    "--with-proto"
    "--with-cli"
    ## The detection code in proto/m4/ax_boost_system.m4 doesn't work properly
    "--with-boost-libdir=${boost}/lib"
  ];
})
