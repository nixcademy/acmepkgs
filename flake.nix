{
  description = "ACME package set: nixpkgs + all acme overlays";

  inputs = {
    # This is the autoritative nixpkgs pin that everyone in ACME inc. uses
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Each ACME project is consumed as a plain source tree (flake = false).
    # otherwise we get a "lock file explosion"
    # (note that non-flake locking tools like Nixtamal, npins, etc. work like
    # this by default)
    acme-liba = {
      url = "github:nixcademy/acme-liba";
      flake = false;
    };
    acme-libb = {
      url = "github:nixcademy/acme-libb";
      flake = false;
    };
    acme-libc = {
      url = "github:nixcademy/acme-libc";
      flake = false;
    };
    acme-libd = {
      url = "github:nixcademy/acme-libd";
      flake = false;
    };
    acme-myapp = {
      url = "github:nixcademy/acme-myapp";
      flake = false;
    };

    gcan = {
      url = "github:applicative-systems/gcan/v1.1.1";
      flake = false;
    };
  };

  outputs =
    inputs:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      inherit (inputs.nixpkgs) lib;

      eachSystem =
        systems: f:
        builtins.foldl' (
          a: s: a // builtins.mapAttrs (k: v: (a.${k} or { }) // { ${s} = v; }) (f s)
        ) { } systems;
    in
    {
      overlays = {
        default = lib.composeManyExtensions (with inputs.self.overlays; [
          acmeSources
          acmeScope

          packages

          liba
          libb
          libc
          libd
          myapp
        ]);

        # Being part of this makes you part of the official ACME product set.

        acmeScope = import ./overlay.nix;
        acmeSources = final: prev: { acme-srcs = inputs; };

        # from these sources, we grab the source code *and* the nix expressions
        liba = import "${inputs.acme-liba}/overlay.nix";
        libb = import "${inputs.acme-libb}/overlay.nix";
        libc = import "${inputs.acme-libc}/overlay.nix";
        libd = import "${inputs.acme-libd}/overlay.nix";
        myapp = import "${inputs.acme-myapp}/overlay.nix";

        # For these packages, we host the nix expressions in this repo and only
        # grab the source code from their repo.
        # (see pkgs.acme-srcs which point to the flake inputs).
        # This has different tradeoffs, also regarding evaluation performance.
        packages = import ./pkgs/overlay.nix;
      };
    } // eachSystem systems (
      system:
      let
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [ inputs.self.overlays.default ];
        };
      in
      {
        # Like nixpkgs' legacyPackages, but with all acme overlays applied.
        # The acme package set is therefore at legacyPackages.<system>.acme.*
        # (and downstream flakes consume it from there).
        legacyPackages = pkgs;

        # The acme overlays compose into a scope (pkgs.acme).
        # The flake `packages` output must contain only derivations,
        # so filter out the scope's helper attrs
        # (callPackage, newScope, overrideScope, packages, ...).
        # filterAttrs's predicate is `name: value:`, so ignore the name.
        packages = lib.filterAttrs (_: lib.isDerivation) pkgs.acme;
      }
    );
}
