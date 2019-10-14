{ lib, mixToNix, gitignoreSource, ... }:

let
  fixHexDep = drv:
    drv.overrideAttrs (super: rec {
      postConfigure = ''
        [ -e rebar.config ] && [ -e _build/default/lib ] && {
          mkdir -p _checkouts
          cp -R _build/default/lib/*/ _checkouts/
          chmod -R u+w _checkouts
        } || true
      '';

      postInstall = ''
        [ -e .hex ] && cp -Hrt "$out/lib/erlang/lib/${super.name}/" .hex || true
      '';
    });

in (mixToNix {
  src = gitignoreSource ./.;
  overlay = final: lib.mapAttrs (lib.const fixHexDep);
}).overrideAttrs (super: {
  name = "hermetic";

  doCheck = false;

  postConfigure = ''
    mkdir -p _build/test/lib deps
    cp -Rv _build/prod/lib/* _build/test/lib/
    cp -Rv _build/prod/lib/* deps/
  '';

  buildPhase = ''
    export MIX_ENV=prod
    mkdir -p $out
    mix do compile --warnings-as-errors, release --path $out
  '';
})
