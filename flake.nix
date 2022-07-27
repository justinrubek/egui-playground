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
      packages = {
        gui = rustPackage;
        wasm = wasmPackage;
        default = packages.wasm;
      };
      devShells = {
        default = pkgs.mkShell rec {
          buildInputs = with pkgs; [rustWasm rustfmt wasm-bindgen-cli wasm-pack binaryen build-docs miniserve];
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
