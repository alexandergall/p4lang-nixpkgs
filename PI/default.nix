{ stdenv
, fetchFromGitHub
, autoreconfHook
, readline
, pkg-config
, protobuf
, grpc
, boost
}:

stdenv.mkDerivation rec {
  pname = "PI";
  version = "v0.1.0-25-g17802cf";
  src = fetchFromGitHub {
    repo = "PI";
    owner = "p4lang";
    rev = "17802cf";
    hash = "sha256-uSKkowR27BJ3HuzgkpMii2DV6IRwdur5qkGV4NnoXzk=";
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
  passthru = {
    inherit src;
  };
}
