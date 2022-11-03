{
  description = "Slack bot that links to YouTrack issues";

  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };

  inputs.gitignore = {
    url = "github:hercules-ci/gitignore.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  inputs.mix-to-nix.url = "github:serokell/mix-to-nix/transumption";
  inputs.mix-to-nix.flake = false;

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, gitignore, mix-to-nix, flake-utils, ... }: ({
    nixosModules.hermetic = import ./module.nix;
  } // flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };

      mixToNix = (pkgs.callPackage mix-to-nix { }).mixToNix;
      inherit (gitignore.lib) gitignoreSource;
    in
    {
      defaultPackage = pkgs.callPackage ./derivation.nix { inherit mixToNix gitignoreSource; };
      devShell = with pkgs; mkShell {
        name = "hermetic";
        buildInputs = [ elixir ];

        MIX_REBAR = "${rebar}/bin/rebar";
        MIX_REBAR3 = "${rebar3}/bin/rebar3";
      };

      defaultApp = {
        type = "app";
        program = "${self.defaultPackage."${system}"}/bin/hermetic";
      };
    }));
}
