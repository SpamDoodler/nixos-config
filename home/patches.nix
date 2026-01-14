{
  config,
  pkgs,
  ...
}: {
  nixpkgs.overlays = [
    (final: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (python-final: python-prev: {
          blis = python-prev.blis.overrideAttrs (oldAttrs: {
            # Force blis to use generic support instead of Intel KNL
            BLIS_COMPILER_TYPE = "gcc";
            BLIS_ARCH = "generic";
          });
        })
      ];
    })
  ];
}
