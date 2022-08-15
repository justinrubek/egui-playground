{
  inputs,
  self,
  ...
} @ part-inputs: {
  perSystem = {
    config,
    pkgs,
    system,
    ...
  }: let
    pre-commit-check = import ./pre_commit.nix part-inputs system;
    rust = self.lib.rust-stable system;
    rustWasm = rust.override {
      targets = ["wasm32-unknown-unknown"];
    };
    # Used to build docs for hosting via github
    build-docs = pkgs.writeShellScriptBin "build-docs" ''
      # Build wasm manually to avoid incurring the cost upon dev shell startup
      nix build .#wasm

      PWD=${./.}

      # Generate bindings
      ${pkgs.wasm-bindgen-cli}/bin/wasm-bindgen ./result/egui_playground.wasm --out-dir docs --no-modules --no-typescript

      # Optimize wasm
      ${pkgs.binaryen}/bin/wasm-opt "docs/egui_playground_bg.wasm" -O2 --fast-math -o "docs/egui_playground_bg.wasm"
    '';
  in rec {
    devShells = {
      default = pkgs.mkShell rec {
        buildInputs = with pkgs; [rustWasm rustfmt wasm-bindgen-cli wasm-pack binaryen build-docs miniserve];
        inherit (pre-commit-check) shellHook;
        LD_LIBRARY_PATH = self.lib.egui.libPath pkgs;
      };
    };
    checks = {
      pre-commit = pre-commit-check;
    };
  };
}
