{
  inputs.nixify.url = "github:rvolosatovs/nixify";

  outputs = {nixify, ...}:
    nixify.lib.rust.mkFlake {
      src = ./.;
      name = "RustStore";

      # NOTE: `IronAge` is outside this workspace and will not be tested/linted,
      # perhaps that should be changed
      build.workspace = true;
      clippy.workspace = true;
      test.workspace = true;

      buildOverrides = {pkgs, ...}: {buildInputs ? [], ...}:
        with pkgs.lib; {
          buildInputs =
            buildInputs
            ++ optional pkgs.stdenv.hostPlatform.isDarwin pkgs.libiconv;
        };
    };
}

