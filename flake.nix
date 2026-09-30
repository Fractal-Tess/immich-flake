{
  description = "Immich packaged for Nix at the latest upstream release, with a NixOS module";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      packageFor = system: nixpkgs.legacyPackages.${system}.callPackage ./packages/immich.nix { };
    in
    {
      packages = forAllSystems (
        system:
        let
          immich = packageFor system;
        in
        {
          inherit immich;
          immich-machine-learning = immich.machine-learning;
          default = immich;
        }
      );

      checks = forAllSystems (system: {
        immich = self.packages.${system}.immich;
        immich-machine-learning = self.packages.${system}.immich-machine-learning;
      });

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);

      overlays.default = final: previous: {
        immich = final.callPackage ./packages/immich.nix { inherit (previous) immich; };
      };

      nixosModules.default = import ./modules/nixos.nix { inherit self; };
    };
}
