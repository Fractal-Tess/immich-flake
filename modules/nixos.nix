{ self }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  cfg = config.services.immich;
in
{
  # Configure Immich through the upstream `services.immich` options. This
  # module only swaps in the flake package and adds a few safe defaults.
  config = lib.mkIf cfg.enable {
    services.immich.package = lib.mkDefault self.packages.${system}.immich;

    # The media directory often lives on a separate disk; don't start Immich
    # against an empty mount point.
    systemd.services.immich-server.unitConfig.RequiresMountsFor = [ cfg.mediaLocation ];
  };
}
