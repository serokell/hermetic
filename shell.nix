with import <nixpkgs> {};

stdenvNoCC.mkDerivation {
  name = "hermetic";
  buildInputs = [ elixir ];

  shellHook = ''
    mix local.hex --force
    mix deps.get
  '';
}
