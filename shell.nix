with import <nixpkgs> {};

stdenvNoCC.mkDerivation {
  name = "hermetic";
  buildInputs = [ elixir ];

  MIX_REBAR = "${rebar}/bin/rebar";
  MIX_REBAR3 = "${rebar3}/bin/rebar3";
}
