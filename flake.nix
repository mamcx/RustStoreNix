{
  description = "RustStore";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    flake-utils.url = "github:numtide/flake-utils";
    flakebox = {
      url = "github:rustshop/flakebox?rev=390c23bc911b354f16db4d925dbe9b1f795308ed";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, flakebox }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        projectName = "RustStore";

        flakeboxLib = flakebox.lib.${system} {
          config = {
            git.pre-commit.trailing_newline = false;
            typos.pre-commit.enable = false;
          };
        };

        buildPaths = [
          "Cargo.toml"
          "Cargo.lock"
          ".cargo"

          "client/ui"
          "corelib"
          "corelogic"
          "server"
          "sync"
          "syncdb"
        ];

        buildSrc = flakeboxLib.filterSubPaths {
          root = builtins.path {
            name = projectName;
            path = ./.;
          };
          paths = buildPaths;
        };

        multiBuild =
          (flakeboxLib.craneMultiBuild { }) (craneLib':
            let
              craneLib = (craneLib'.overrideArgs {
                pname = projectName;
                src = buildSrc;
              });
            in
            rec {
               workspaceDeps = craneLib.buildWorkspaceDepsOnly { };
               workspaceBuild = craneLib.buildWorkspace {
                cargoArtifacts = workspaceDeps;
              };
              ${projectName} = craneLib.buildPackage { };
            });
      in
      {
        packages.default = multiBuild.${projectName};

        legacyPackages = multiBuild;

        devShells = {
          default = flakeboxLib.mkDevShell {
            packages = [ ];
          };
        };
      }
    );
}