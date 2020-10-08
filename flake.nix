{
  description = "Slack bot that links to YouTrack issues";

  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };

  inputs.gitignore.url = "github:hercules-ci/gitignore";
  inputs.gitignore.flake = false;

  inputs.mix-to-nix.url = "github:serokell/mix-to-nix/transumption";
  inputs.mix-to-nix.flake = false;

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, gitignore, mix-to-nix, flake-utils, ... }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };

      mixToNix = (pkgs.callPackage mix-to-nix { }).mixToNix;
      gitignoreSource = (pkgs.callPackage gitignore { }).gitignoreSource;
    in
    {
      defaultPackage = pkgs.callPackage ./derivation.nix { inherit mixToNix gitignoreSource; };

      defaultApp = {
        type = "app";
        program = "${self.defaultPackage."${system}"}/bin/hermetic";
      };
    });
}
