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
  }: rec {
    apps = {
      gui = {
        type = "app";
        program = "${self.packages.${system}.default}/bin/egui-playground-bin";
      };
      default = apps.gui;
    };
  };
}
