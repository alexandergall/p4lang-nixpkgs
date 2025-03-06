### TODO: cJSON should probably not be in the output
### TODO: get rid of third-party and use proper dependencies
{ stdenv
, fetchFromGitHub
, cmake
, target-syslibs
## Required by third-party klish
, expat
, libedit  
}:

stdenv.mkDerivation {
  pname = "p4lang-target-utils";
  version = "v1.0.0-12-g386e7e1";
  src = fetchFromGitHub {
    repo = "target-utils";
    owner = "p4lang";
    rev = "386e7e";
    sha256 = "0xjkmfhz950k3mcimdcsqav4wz1klzis42qm978mvwhw2gb52nsp";
    fetchSubmodules = true;
  };
  nativeBuildInputs = [ cmake target-syslibs ];
  buildInputs = [ expat libedit ];
}
