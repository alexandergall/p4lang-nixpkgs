{ python3
, PI
}:

python3.pkgs.buildPythonPackage rec {
  pname = "p4lang-PI-py";
  version = with builtins; head (match "(.*)-g.*" PI.version);
  inherit (PI) src;
  pyproject = true;
  nativeBuildInputs = with python3.pkgs; [ setuptools-scm ];
  propagatedBuildInputs = with python3.pkgs; [ protobuf grpcio googleapis-common-protos ];
  preConfigure = ''
    cd proto/p4runtime/py
    ## setuptools-scm-git-archive is broken in our nixpkgs, but
    ## the build seems to work without it
    sed -i -e '/setuptools_scm_git_archive/d' pyproject.toml
  '';
}
