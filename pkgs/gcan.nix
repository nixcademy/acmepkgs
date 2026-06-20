{
  lib,
  rustPlatform,
  versionCheckHook,
  acme-srcs,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "gcan";
  version = "1.1.1";

  __structuredAttrs = true;

  # Source comes from the `flake = false` input, surfaced via the acme-srcs
  # overlay. This way we can have central tooling that updates them all.
  src = acme-srcs.gcan;

  # Vendor dependencies straight from the upstream lockfile rather than pinning
  # a cargoHash that has to be regenerated on every dependency bump.
  cargoLock.lockFile = "${acme-srcs.gcan}/Cargo.lock";

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];

  meta = {
    description = "Analyze, filter, and prune Nix GC roots";
    homepage = "https://github.com/applicative-systems/gcan";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.tfc ];
    mainProgram = "gcan";
    platforms = lib.platforms.unix;
  };
})
