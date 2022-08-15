{
  inputs,
  self,
  ...
}: let
in {
  flake = {
    lib = {
      cargo_lock = ../../Cargo.lock;
      rust-stable = system: inputs.rust-overlay.packages.${system}.rust;
      rust-nightly = system: inputs.rust-overlay.packages.${system}.rust-nightly;
    };
  };
}
