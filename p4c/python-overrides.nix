final: prev: python-self: python-super:
{
  ## BMV2 tests are not compatible with 2.6
  scapy = python-super.scapy.overridePythonAttrs rec {
    version = "2.5.0";
    src = final.fetchFromGitHub {
      owner = "secdev";
      repo = "scapy";
      rev = "v${version}";
      hash = "sha256-lWp9s1anlJEmPAGeyZeI3TMWPN4oXK0/lKiP02HX6qE=";
    };            
  };
  jsl = python-super.buildPythonPackage rec {
    pname = "jsl";
    version = "0.2.4";
    
    src = python-super.fetchPypi {
      inherit pname version;
      sha256 = "17f14h2aj05hcwc5p1600s5n33fhfsjig7id5gqhixbgdc8j29i2";
    };
    doCheck = false;
  };
  nnpy = python-self.buildPythonPackage rec {
    pname = "nnpy";
    version = "1.4.2";
    format = "setuptools";

    src = python-self.fetchPypi {
      inherit pname version;
      sha256 = "1y8g8dfk2kg8f2zznyfjr7pvlm9vgw19xr17gb4ag53224pn3haj";
    };
    buildInputs = [ final.nanomsg ];
    propagatedBuildInputs = with python-self; [ cffi ];
    preBuild = ''
        cat <<EOF >site.cfg
        [DEFAULT]
        include_dirs = ${final.nanomsg}/include/nanomsg
        host_library = ${final.nanomsg}/lib/libnanomsg.so
        EOF
      '';
  };
  ### pyinstaller is used to build and package the
  ### p4c-build-logs utility for the tofino backend
  pyinstaller-hooks-contrib = python-super.buildPythonPackage rec {
    pname = "pyinstaller_hooks_contrib";
    version = "2024.10";
    propagatedBuildInputs = with python-self;[ pip packaging ];

    src = python-super.fetchPypi {
      inherit pname version;
      sha256 = "0340x016skzshg22a57b2c2z2hmkm4c92f97wnsqc0avbig6aila";
    };
    doCheck = false;
  };
  pyinstaller = python-super.buildPythonPackage rec {
    pname = "pyinstaller";
    version = "6.11.1";
    buildInputs = [ final.zlib ] ++ (with python-self; [ setuptools ]);
    pyproject = true;
    propagatedBuildInputs = with python-self;[ pip packaging pyinstaller-hooks-contrib altgraph setuptools ];

    src = python-super.fetchPypi {
      inherit pname version;
      sha256 = "1vvjrgzhl2nnmmmkk3jd4mx54ab8zz0swzahv589c7axkm6zn7a9";
    };
  };
}
