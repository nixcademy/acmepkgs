final: prev: {
  acme = prev.acme.overrideScope (
    acmeFinal: acmePrev: {
      gcan = acmeFinal.callPackage ./gcan.nix { };
    }
  );
}
