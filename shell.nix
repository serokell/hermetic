{ sources ? import nix/sources.nix }:

let inherit (import sources.nixpkgs { }) elixir stdenvNoCC rebar rebar3;

in stdenvNoCC.mkDerivation {
  name = "hermetic";
  buildInputs = [ elixir ];

  MIX_REBAR = "${rebar}/bin/rebar";
  MIX_REBAR3 = "${rebar3}/bin/rebar3";
}
