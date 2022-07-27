{
  description = "egui playground";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    gitignore,
    rust-overlay,
    pre-commit-hooks,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          rust-overlay.overlays.default
        ];
      };
      inherit (gitignore.lib) gitignoreSource;
      pre-commit-check = pre-commit-hooks.lib.${system}.run {
        src = gitignoreSource ./.;
        hooks = {
          alejandra.enable = true;
          rustfmt.enable = true;
        };
      };

      rust = pkgs.rust-bin.stable.latest.default;
      rustWasm = rust.override {
        targets = ["wasm32-unknown-unknown"];
      };
      rustPackage = pkgs.rustPlatform.buildRustPackage {
        pname = "egui-playground";
        version = "0.1.0";

        src = gitignoreSource ./.;
        cargoLock = {
          lockFile = ./Cargo.lock;
        };
        buildInputs = with pkgs; [
          xorg.libxcb
        ];
        nativeBuildInputs = [rust pkgs.makeWrapper];
        postInstall = ''
          wrapProgram "$out/bin/egui-playground-bin" --prefix LD_LIBRARY_PATH : "${libPath}"
        '';
      };
      wasmPackage = pkgs.rustPlatform.buildRustPackage {
        pname = "egui-playground";
        version = "0.1.0";

        src = gitignoreSource ./.;
        cargoLock = {
          lockFile = ./Cargo.lock;
        };
        buildInputs = with pkgs; [
          xorg.libxcb
        ];
        buildPhase = "cargo build --release --lib --target wasm32-unknown-unknown";
        installPhase = ''
          mkdir $out
          cp target/wasm32-unknown-unknown/release/egui_playground.wasm $out/egui_playground.wasm
        '';
        nativeBuildInputs = [rustWasm pkgs.binaryen pkgs.wasm-pack pkgs.wasm-bindgen-cli];
      };

      # Required by egui
      libPath = with pkgs;
        lib.makeLibraryPath [
          libGL
          libxkbcommon
          wayland
          xorg.libX11
          xorg.libXcursor
          xorg.libXi
          xorg.libXrandr
        ];
    in rec {
      packages = {
        gui = rustPackage;
        wasm = wasmPackage;
        default = packages.wasm;
      };
      devShells = {
        default = pkgs.mkShell rec {
          buildInputs = with pkgs; [rustWasm rustfmt wasm-bindgen-cli wasm-pack binaryen];
          inherit (pre-commit-check) shellHook;
          LD_LIBRARY_PATH = libPath;
        };
      };
      apps = {
        gui = {
          type = "app";
          program = "${packages.default}/bin/egui-playground-bin";
        };
        default = apps.gui;
      };
    });
}
