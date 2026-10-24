<p align="center">
  <img src="assets/logo.svg" alt="Immich plus Nix" width="480" />
</p>

<h1 align="center">immich-flake</h1>

<p align="center">
  <a href="flake.nix"><img src="https://img.shields.io/badge/Nix-flake-5277C3?logo=nixos&logoColor=white" alt="Nix flake" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT license" /></a>
  <a href="https://github.com/immich-app/immich/releases/tag/v3.3.5"><img src="https://img.shields.io/badge/immich-3.3.5-4250af" alt="Immich 3.3.5" /></a>
</p>

[Immich](https://github.com/immich-app/immich) is a self-hosted photo and video backup server.

nixpkgs already ships Immich and a solid `services.immich` NixOS module, but the package can trail upstream by a few releases. This flake rebuilds the nixpkgs derivation at the newest stable upstream release — only the source and dependency hashes change — so the server, web UI, and machine-learning service stay current while the build recipe and module remain the well-tested nixpkgs ones. It supports x86_64 and ARM64 Linux.

```sh
nix build github:Fractal-Tess/immich-flake#immich
```

## Use it on NixOS

Add the flake input:

```nix
inputs.immich-flake = {
  url = "github:Fractal-Tess/immich-flake";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Import the module and configure Immich with the regular upstream options:

```nix
{
  imports = [ inputs.immich-flake.nixosModules.default ];

  services.immich = {
    enable = true;
    host = "0.0.0.0";
    openFirewall = true;
    mediaLocation = "/mnt/photos/immich";
  };
}
```

The module sets `services.immich.package` to this flake's build (override it to go back to nixpkgs) and makes the server wait for the disk holding `mediaLocation` to be mounted. Everything else is the [nixpkgs module](https://search.nixos.org/options?query=services.immich). To use the package elsewhere, apply `overlays.default` to get `pkgs.immich` and `pkgs.immich-machine-learning`.

When this flake is ahead of your nixpkgs, the first build compiles the server and web UI locally; once nixpkgs catches up, the identical outputs come straight from cache.nixos.org.

## Update

The daily [update workflow](.github/workflows/update.yml) runs at 12:00 UTC, resolves the latest stable release (release candidates are skipped), refreshes the source and pnpm hashes, builds the package, and commits an update. Run the same process locally with:

```sh
./scripts/update.sh
```

Pass a version such as `./scripts/update.sh 3.3.5` to pin a specific release.

Read the [upstream release notes](https://github.com/immich-app/immich/releases) before a major version bump; breaking database changes need manual steps.

## Credits

The flake packaging is [MIT](LICENSE). Immich is [AGPL-3.0 licensed](https://github.com/immich-app/immich/blob/main/LICENSE), © Immich authors. The build recipe comes from [nixpkgs](https://github.com/NixOS/nixpkgs/tree/master/pkgs/by-name/im/immich).

The lockup pairs the [Immich flower](https://github.com/immich-app/immich/blob/main/design/immich-logo.svg) with the [Nix snowflake](https://github.com/NixOS/nixos-artwork/tree/master/logo) by Simon Frankau and Tim Cuthbertson ([CC BY 4.0](https://creativecommons.org/licenses/by/4.0)), both resized and arranged here. Neither project is affiliated with or endorsing this flake.
