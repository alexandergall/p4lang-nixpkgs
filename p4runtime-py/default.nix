{
  fetchFromGitHub
, python3
}:

python3.pkgs.buildPythonPackage rec {
  pname = "p4runtime-py";
  ## v1.4.1-18-g5e6138d
  version = "v1.4.1-18";
  src = fetchFromGitHub {
    repo = "p4runtime";
    owner = "p4lang";
    rev = "5e6138d";
    hash = "sha256-Hgi1G2Bld01/tx+YMasY1oRhPkPrne2yS/N8szgZWhY=";
  };
  pyproject = true;
  nativeBuildInputs = with python3.pkgs; [ setuptools-scm ];
  propagatedBuildInputs = with python3.pkgs; [ protobuf grpcio googleapis-common-protos ];
  preConfigure = ''
    cd py
    ## setuptools-scm-git-archive is broken in our nixpkgs, but
    ## the build seems to work without it
    sed -i -e '/setuptools_scm_git_archive/d' pyproject.toml
  '';
}
