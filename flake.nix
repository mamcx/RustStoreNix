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
            github.ci.buildOutputs = [ ".#ci.RustStore" ];
            typos.pre-commit.enable = false;
          };
        };

        buildPaths = [
          "Cargo.toml"
          "Cargo.lock"
          ".cargo"

          "IronAge"
          "IronAge/corelib"
          "IronAge/db"
          "IronAge/sync"
          "IronAge/ui"
          "IronAge/web"

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
              ${projectName} = craneLib.buildPackage {
                 src = craneLib.cleanCargoSource (craneLib.path ./.);
                 cargoLock = ./Cargo.lock;
                 cargoToml = ./Cargo.toml;
                 # # Use a postUnpack hook to jump into our nested directory.
                 # postUnpack = ''
                 #   cd $sourceRoot/RustStore
                 #   sourceRoot="."
                 # '';
               };
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