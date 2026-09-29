{ stdenv
, fetchFromGitHub
, autoreconfHook
, python3
, PI
, thrift
, nanomsg
, gmp
, libpcap
, boost
, pkg-config
, protobuf
, grpc
, xxHash
, jsoncpp
}:

stdenv.mkDerivation (finalArgs: {
  pname = "bmv2";
  version = "1.15.6";
  src = fetchFromGitHub {
    repo = "behavioral-model";
    owner = "p4lang";
    rev = "${finalArgs.version}";
    hash = "sha256-jLdo5SNscVipMXDDgRkrHVl5ml491/uBpviBh0XqQ6g=";
  };
  configureFlags = [
    "--with-pi"
  ];
  nativeBuildInputs = [ autoreconfHook  thrift  pkg-config ];
  buildInputs = [ PI nanomsg gmp libpcap boost protobuf grpc xxHash jsoncpp ] ++
                [ (python3.withPackages (pkgs: with pkgs; [ pkgs.thrift pynng ])) ];
  enableParallelBuilding = true;
})
