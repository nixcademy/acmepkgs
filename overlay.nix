# Creates the empty `acme` scope that every acme-* overlay extends via
# `prev.acme.overrideScope`. Apply this overlay before the acme-* overlays.
#
# (nixpkgs ships an unrelated `acme` package, a plain derivation, which this
# intentionally shadowed.)
final: prev: {
  acme = prev.lib.makeScope prev.newScope (_: { });
}
