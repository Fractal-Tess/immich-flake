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
    version = "3.3.5";

    src = fetchFromGitHub {
      owner = "immich-app";
      repo = "immich";
      tag = "v${finalAttrs.version}";
      hash = "sha256-QIp6i+6Hz4ZfXkbdBzK63cNp2OkkOdeWDwkrSiVHUcc=";
    };

    pnpmDeps = fetchPnpmDeps {
      inherit (finalAttrs) pname version src;
      inherit (previousAttrs.passthru) pnpm;
      fetcherVersion = 4;
      hash = "sha256-7xUH5b64QfrgWBe32WSFXXNTbjXx6Po6D6L5hbHTHE0=";
    };
  }
)
