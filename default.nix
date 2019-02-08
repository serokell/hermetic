{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  inherit (callPackage (fetchFromGitLab {
    owner = "transumption";
    repo = "mix-to-nix";
    rev = "a983c799d8762c91ce3375d03982e04b37835194";
    sha256 = "0ix2g06c444mvmnfvf6jdzhd44vs0b0965xhny6lxxl2rm7cim1d";
  }) {}) mixToNix;

in mixToNix {
  src = ./.;
}
