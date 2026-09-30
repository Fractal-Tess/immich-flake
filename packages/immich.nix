{
  immich,
  fetchFromGitHub,
  fetchPnpmDeps,
}:

# Rebuilds the nixpkgs Immich derivation at the newest upstream release. Only
# the source and the pnpm dependency hashes change; build steps, runtime
# dependencies, and the machine-learning component (passthru.machine-learning,
# built from finalPackage.src) all follow the nixpkgs package.
immich.overrideAttrs (
  finalAttrs: previousAttrs: {
    version = "3.2.4";

    src = fetchFromGitHub {
      owner = "immich-app";
      repo = "immich";
      tag = "v${finalAttrs.version}";
      hash = "sha256-/wWep6A/ryocuGMOElcD1lOEwT6tJDdwa5HAcCZUXSs=";
    };

    pnpmDeps = fetchPnpmDeps {
      inherit (finalAttrs) pname version src;
      inherit (previousAttrs.passthru) pnpm;
      fetcherVersion = 4;
      hash = "sha256-N6eaRcJxik1wzGE1H/LnKR1JUcSc8iswPFkIGymOKVA=";
    };
  }
)
