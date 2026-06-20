# Exposes the raw flake inputs (the `flake = false` source trees) on the package
# set as `pkgs.acme-srcs.*`, so package overlays can use them as `src` instead
# of refetching with fetchFromGitHub. Curried over `inputs` in flake.nix.
inputs: final: prev: {
  acme-srcs = inputs;
}
