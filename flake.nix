{
  description = "RustStore";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    flake-utils.url = "github:numtide/flake-utils";
    flakebox = {
      url = "github:rustshop/flakebox?rev=00baca64cf47f00dceb6782bcbbc37307fdb51fd";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, flakebox }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        projectName = "RustStore";

        flakeboxLib = flakebox.lib.${system} {
          config = {
            github.ci.buildOutputs = [ ".#ci.RustStore" ];
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
                pname = "flexbox-multibuild";
                src = buildSrc;
              });
            in
            rec {
               workspaceDeps = craneLib.buildWorkspaceDepsOnly { };
               workspaceBuild = craneLib.buildWorkspace {
                cargoArtifacts = workspaceDeps;
              };
              ruststore = craneLib.buildPackage { };
            });
      in
      {
        packages.default = multiBuild.ruststore;

        legacyPackages = multiBuild;

        devShells = {
          default = flakeboxLib.mkDevShell {
            packages = [ ];
          };
        };
      }
    );
}