{
  description = "ACME package set: nixpkgs + all acme overlays";

  inputs = {
    # This is the autoritative nixpkgs pin that everyone in ACME inc. uses
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Each ACME project is consumed as a plain source tree (flake = false).
    # otherwise we get a "lock file explosion"
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

      overlays = [
        # Must come first: creates the empty `acme` scope the others extend.
        (import ./overlay.nix)
        (import "${inputs.acme-libd}/overlay.nix")
        (import "${inputs.acme-libc}/overlay.nix")
        (import "${inputs.acme-libb}/overlay.nix")
        (import "${inputs.acme-liba}/overlay.nix")
        (import "${inputs.acme-myapp}/overlay.nix")
      ];

    in
    eachSystem systems (
      system:
      let
        pkgs = import inputs.nixpkgs {
          inherit system overlays;
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
    )
    # overlays.default is not per-system, so it lives outside eachSystem.
    // {
      overlays.default = lib.composeManyExtensions overlays;
    };
}
