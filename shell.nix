with import <nixpkgs> {};

stdenvNoCC.mkDerivation {
  name = "hermetic";
  buildInputs = [ elixir ];
}
