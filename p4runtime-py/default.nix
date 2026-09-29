{
  fetchFromGitHub
, python3
}:

python3.pkgs.buildPythonPackage rec {
  pname = "p4runtime-py";
  version = "v1.5.0";
  src = fetchFromGitHub {
    repo = "p4runtime";
    owner = "p4lang";
    rev = "${version}";
    hash = "sha256-bGR19GCEXjMT2YTpAWwPZAij3y/RxVXVzYgItsYJla0=";
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
