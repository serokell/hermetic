{ sources ? import nix/sources.nix }:

let
  inherit (import sources.nixpkgs { }) callPackage;
  inherit (callPackage sources.mix-to-nix { }) mixToNix;
  inherit (callPackage sources.gitignore { }) gitignoreSource;

in callPackage ./derivation.nix { inherit mixToNix gitignoreSource; }
