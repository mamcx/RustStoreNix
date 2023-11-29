{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";

    flakebox = {
      url = "github:rustshop/flakebox";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flakebox, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # Set project name
        projectName = "RustStore";
        flakeboxLib = flakebox.lib.${system} {
          config = {
            typos.pre-commit.enable = false;
            #rootDir.path =./RustStore;
          };
        };

        # # Add list of Rust-source paths
        # buildPaths = [
        #   "Cargo.toml"
        #   "Cargo.lock"
        #   ".cargo"
        #   "client/ui"
        #   "corelib"
        #   "corelogic"
        #   "server"
        #   "sync"
        #   "syncdb"
        # ];        

        # # Filter Rust source code
        # buildSrc = flakeboxLib.filterSubPaths {
        #   root = builtins.path {
        #     name = projectName;
        #     path = ./.;
        #   };
        #   paths = buildPaths;
        # };

        # Add toolchain x profile build matrix
        multiBuild =
          (flakeboxLib.craneMultiBuild { }) (craneLib':
            let
              craneLib = (craneLib'.overrideArgs {
                pname = projectName;
                #src = buildSrc;
              });
            in
            {
              package = craneLib.buildPackage { 
                 #src = flakeboxLib.cleanCargoSource (craneLib.path ./.);
                 cargoLock = ./RustStore/Cargo.lock;
                 cargoToml = ./RustStore/Cargo.toml;
                 # Use a postUnpack hook to jump into our nested directory.
                 postUnpack = ''
                   cd $sourceRoot/RustStore
                   sourceRoot="."
                 '';
              };
            });

        # Expose external output packages
        packages.default = multiBuild.package;

        # Expose internal (CI) packages
        legacyPackages = multiBuild;

      in
      {
        devShells = flakeboxLib.mkShells {
          packages = [ ];
        };
      });
}
