### Global overrides
let
  overlay = final: prev:
    {
      ## Make 25 the default version for protobuf. Downgrade explicitly to
      ## 25.3 to please the version check in p4c. Note that this will
      ## trigger rebuilds of all dependencies of the p4lang packages that
      ## implicitly depend on protobuf (e.g. grpc and
      ## python3.pkgs.{googleapis-common-protos,grpcio})
      protobuf_25 = prev.protobuf_25.override {
        version = "25.3";
        hash = "sha256-N/mO9a6NyC0GwxY3/u1fbFbkfH7NTkyuIti6L3bc+7k=";
      };
      protobuf = final.protobuf_25;
      
      ### Python packageOverrides can't be composed, so we collect all of
      ### them here.
      python3 = prev.python3.override {
        packageOverrides = python-self: python-super: (
          {
            ## Global overrides
            protobuf = python-self.protobuf4;
          } //
          ## Per-component overrides, stored separately to make the
          ## dependence manifest.
          builtins.foldl' (result: next:
            result // (import next final prev python-self python-super)) {}
            [
              ./p4c/python-overrides.nix
              ./bmv2/python-overrides.nix
            ]
        );
      };
    };
in [ overlay ]
