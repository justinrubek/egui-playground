{
  inputs,
  self,
  ...
}: let
in {
  flake = {
    lib = {
      egui.libPath = pkgs:
        with pkgs;
          lib.makeLibraryPath [
            libGL
            libxkbcommon
            wayland
            xorg.libX11
            xorg.libXcursor
            xorg.libXi
            xorg.libXrandr
          ];
    };
  };
}
