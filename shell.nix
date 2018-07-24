with import <nixpkgs> {};

stdenvNoCC.mkDerivation {
  name = "cobwebhook";
  buildInputs = [ elixir ];
}
