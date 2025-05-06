{
  p4cOverrides ? {}
}:

let
  nixpkgs = fetchTarball {
    url = https://github.com/NixOS/nixpkgs/archive/24.11-5444-g75ab63cf72c7.tar.gz;
    sha256 = "0sqskvk5cdj88xv1d1yca8sz1f4bjh1s8s2k5blm3gq3sgljnv9x";
  };
  pkgs = import nixpkgs {
    overlays = import ./overlay.nix;
  };
in pkgs.lib.makeScope pkgs.newScope (self:
  {
    p4c = (self.callPackage ./p4c {
      ## The eBPF tests use tc from iproute2 to load eBPF
      ## programs. Newer iproute2 versions use a libbpf version >1.0,
      ## which conflicts with how the p4c eBPF backend currently
      ## generates ELF binaries. This crude downgrade sidesteps the
      ## problem.
      iproute2 = pkgs.iproute2.override {
        libbpf = pkgs.libbpf_0;
      };
    }).override p4cOverrides;
    bmv2 = self.callPackage ./bmv2 {};
    PI = self.callPackage ./PI {};
    p4runtime-py = self.callPackage ./p4runtime-py {};
    ptf = self.callPackage ./ptf {};
    target-syslibs = self.callPackage ./target-syslibs {};
    target-utils = self.callPackage ./target-utils {};
  }
)
