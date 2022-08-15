{
  inputs,
  self,
  ...
}: {
  perSystem = {
    config,
    pkgs,
    system,
    ...
  }: let
    rust = self.lib.rust-stable system;
    rustWasm = rust.override {
      targets = ["wasm32-unknown-unknown"];
    };
  in rec {
    packages = {
      default = packages.gui;
      gui = pkgs.rustPlatform.buildRustPackage {
        pname = "egui-playground";
        version = "0.1.0";

        src = self.lib.flake_source;
        cargoLock = {
          lockFile = self.lib.cargo_lock;
        };
        buildInputs = with pkgs; [
          xorg.libxcb
        ];
        nativeBuildInputs = [rust pkgs.makeWrapper];
        postInstall = ''
          wrapProgram "$out/bin/egui-playground-bin" --prefix LD_LIBRARY_PATH : "${self.lib.egui.libPath pkgs}"
        '';
      };
      wasm = pkgs.rustPlatform.buildRustPackage {
        pname = "egui-playground";
        version = "0.1.0";

        src = self.lib.flake_source;
        cargoLock = {
          lockFile = self.lib.cargo_lock;
        };
        buildInputs = with pkgs; [
          xorg.libxcb
        ];
        buildPhase = ''
          # required to enable web_sys clipboard API
          export RUSTFLAGS=--cfg=web_sys_unstable_apis

          cargo build --release --lib --target wasm32-unknown-unknown
        '';
        installPhase = ''
          mkdir $out
          cp target/wasm32-unknown-unknown/release/egui_playground.wasm $out/egui_playground.wasm
        '';
        nativeBuildInputs = [rustWasm pkgs.binaryen pkgs.wasm-pack pkgs.wasm-bindgen-cli];
      };
    };
  };
}
