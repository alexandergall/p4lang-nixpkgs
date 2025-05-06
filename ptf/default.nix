{ fetchFromGitHub
, python3
}:

python3.pkgs.buildPythonApplication rec {
  pname = "ptf";
  ## Setuptools doesn't accept Git commits as valid version number
  version = "0.9.4-17";
  
  src = fetchFromGitHub {
    repo = "ptf";
    owner = "p4lang";
    rev = "77a5ba4";
    hash = "sha256-H15c4MiTO/zzpHDMFoQqVMA8pZe+9TAwuSMQiEepGaQ=";
  };

  format = "setuptools";
  nativeBuildInputs = with python3.pkgs; [ setuptools-scm ];
}
