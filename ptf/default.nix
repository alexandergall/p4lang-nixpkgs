{ fetchFromGitHub
, python3
}:

python3.pkgs.buildPythonApplication rec {
  pname = "ptf";
  version = "0.11.0";
  
  src = fetchFromGitHub {
    repo = "ptf";
    owner = "p4lang";
    rev = "v${version}";
    hash = "sha256-MBGZd6tnxnWyWLrqnQD89nrpPMWLJZy6vNSf8/4G2Sw=";
  };

  format = "setuptools";
  nativeBuildInputs = with python3.pkgs; [ setuptools-scm ];
}
