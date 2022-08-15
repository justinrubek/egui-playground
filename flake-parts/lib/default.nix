{
  inputs,
  self,
  ...
}: let
  inherit (inputs.gitignore.lib) gitignoreSource;
in {
  flake = {
    lib = {
      flake_source = gitignoreSource ../..;
      cargo_lock = ../../Cargo.lock;
      rust-stable = system: inputs.rust-overlay.packages.${system}.rust;
      rust-nightly = system: inputs.rust-overlay.packages.${system}.rust-nightly;
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

  # imports = [ ./rust.nix ./egui.nix];
}
