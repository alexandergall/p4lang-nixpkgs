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
}:

let
  python = python3.override {
    packageOverrides = python-self: python-super:
      {
        nnpy = python-self.buildPythonPackage rec {
          pname = "nnpy";
          version = "1.4.2";
          format = "setuptools";
          
          src = python-self.fetchPypi {
            inherit pname version;
            sha256 = "1y8g8dfk2kg8f2zznyfjr7pvlm9vgw19xr17gb4ag53224pn3haj";
          };
          buildInputs = [ nanomsg ];
          propagatedBuildInputs = with python-self; [ cffi ];
          preBuild = ''
            cat <<EOF >site.cfg
            [DEFAULT]
            include_dirs = ${nanomsg}/include/nanomsg
            host_library = ${nanomsg}/lib/libnanomsg.so
            EOF
          '';
        };
      };
  };
in stdenv.mkDerivation rec {
  pname = "bmv2";
  version = "1.15.0-72-gd12eefc";
  src = fetchFromGitHub {
    repo = "behavioral-model";
    owner = "p4lang";
    rev = "d12eefc";
    hash = "sha256-lYfp+ui3ADk9n3vmr0qIifD7Enw9T59JqT6GbfEk2Ro=";
  };
  configureFlags = [
    "--with-pi"
  ];
  nativeBuildInputs = [ autoreconfHook  thrift  pkg-config ];
  buildInputs = [ PI nanomsg gmp libpcap boost protobuf grpc ] ++
                [ (python.withPackages (pkgs: with pkgs; [ pkgs.thrift nnpy ])) ];
  enableParallelBuilding = true;
}
