final: prev: python-final: python-prev:
{
  ## Also used by p4c to run the bmv2 checks.
  pynng =
    let
      nng = final.fetchFromGitHub {
        owner = "nanomsg";
        repo = "nng";
        tag = "v1.6.0";
        hash = "sha256-Kq8QxPU6SiTk0Ev2IJoktSPjVOlAS4/e1PQvw2+e8UA=";
      };

      mbedtls = final.fetchFromGitHub {
        owner = "ARMmbed";
        repo = "mbedtls";
        tag = "v3.5.1";
        hash = "sha256-HxsHcGbSExp1aG5yMR/J3kPL4zqnmNoN5T5wfV3APaw=";
      };
    in python-final.buildPythonPackage rec {
      pname = "pynng";
      version = "0.9.0";
      pyproject = true;

      src = python-final.fetchPypi {
        inherit pname version;
        hash = "sha256-/Ng5q/gqKTT6jCf/V7V0tBgQRY41iVusYoiBTe+o+04=";
      };
      build-system = with python-final; [ setuptools setuptools-scm ];
      nativeBuildInputs = with final; [ cmake ];
      dependencies = with python-final; [ cffi cmake sniffio ];
      dontUseCmakeConfigure = true;
      preBuild = ''
        cp -r ${mbedtls} mbedtls
        chmod -R +w mbedtls
        cp -r ${nng} nng
        chmod -R +w nng
        sed -i -e 's/"setuptools=.*"/"setuptools"/' pyproject.toml
      '';

      pythonImportsCheck = [ "pynng" ];
    };
}
