{
  description = "Mercury Culture Web Backend";
  inputs = {
    nixpkgs.url = "github:MercuryTechnologies/nixpkgs/ghc962";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:matthewbauer/flake-compat/support-fetching-file-type-flakes";
      flake = false;
    };
    rust-overlay.url = "github:oxalica/rust-overlay";
  };
  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
    rust-overlay,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ rust-overlay.overlays.default ] ++ import ./toolchains/nix/overlays;
        config = {
          allowUnfree = true;
          allowBroken = true;
        };
      };

      toolchains = import toolchains/nix { inherit system; };

      inherit (toolchains.packages.${system}) ghcWithPackages haddock;

      buck2BuildInputs = [
        pkgs.bash
        pkgs.coreutils
        pkgs.cacert
        pkgs.gnused
        pkgs.git
        pkgs.nix
        pkgs.openssh
      ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
        pkgs.stdenv.cc.bintools
        pkgs.darwin.cctools
      ];

      macOS-security =
        # make `/usr/bin/security` available in `PATH`, which is needed for stack
        # on darwin which calls this binary to find certificates
        pkgs.writeScriptBin "security" ''exec /usr/bin/security "$@"'';
    in
    rec {
      packages = {
        inherit ghcWithPackages;
        buck2-update = pkgs.writeShellApplication {
          name = "buck2-update";
          runtimeInputs = with pkgs; [ curl jq nix-prefetch common-updater-scripts nix coreutils ];

          text = ''
            exec "$BASH" nix/overlays/buck2/update.sh
          '';
        };
      };

      devShells = rec {
        buck2 = pkgs.mkShellNoCC {
          name = "buck2-test-shell";
          packages = buck2BuildInputs ++ [
            pkgs.buck2-source
            pkgs.nix
          ];

          shellHook = ''
            # node and openssl problem
            export NODE_OPTIONS=--openssl-legacy-provider
            # for now. frontend REACT configuration here.
            export REACT_APP_BACKEND_SOURCE=localhost
            export REACT_APP_NGROK_SUBDOMAIN=abcd1234
            export REACT_APP_DOMAIN_NAME=mercury.place
            #
            export PS1="\n[buck2-test-shell:\w]$ \0"
          '';
        };
      };
    });

  nixConfig.allow-import-from-derivation = true; # needed for cabal2nix

}
