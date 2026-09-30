#!/usr/bin/env bash
set -euo pipefail

readonly UPSTREAM_REPO="immich-app/immich"
readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly PACKAGE_FILE="packages/immich.nix"
readonly FAKE_HASH="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

fail() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

require_tool() {
  command -v "$1" >/dev/null 2>&1 || fail "missing required tool: $1"
}

github_api_get() {
  local url="$1"
  local -a args=(
    --silent --show-error --fail --location
    --header "Accept: application/vnd.github+json"
    --header "X-GitHub-Api-Version: 2022-11-28"
    --header "User-Agent: Fractal-Tess/immich-flake"
  )
  if [[ -n "${GH_TOKEN:-}" ]]; then
    args+=(--header "Authorization: Bearer ${GH_TOKEN}")
  fi
  curl "${args[@]}" "$url"
}

# Immich publishes release candidates (`-rc.N`) as GitHub prereleases;
# `releases/latest` only ever points at a stable release.
latest_stable_version() {
  github_api_get "https://api.github.com/repos/${UPSTREAM_REPO}/releases/latest" \
    | jq -r '.tag_name | sub("^v"; "")'
}

set_pnpm_hash() {
  sed -i "/pnpmDeps = fetchPnpmDeps {/,/};/ s|^      hash = .*|      hash = \"$1\";|" "$PACKAGE_FILE"
}

main() {
  local requested_version="${1:-}"
  local current_version version src_hash pnpm_hash build_log

  require_tool curl
  require_tool jq
  require_tool nix
  require_tool sed

  cd "$ROOT_DIR"
  current_version="$(sed -n 's/^    version = "\([^"]*\)";/\1/p' "$PACKAGE_FILE")"
  [[ -n "$current_version" ]] || fail "could not read the packaged version"

  if [[ -n "$requested_version" ]]; then
    version="${requested_version#v}"
    [[ "$(github_api_get "https://api.github.com/repos/${UPSTREAM_REPO}/releases/tags/v${version}" \
      | jq -r '.draft or .prerelease')" == "false" ]] || fail "v${version} is not a stable release"
  else
    version="$(latest_stable_version)"
  fi
  [[ -n "$version" && "$version" != "null" ]] || fail "could not determine the upstream version"

  printf 'Current version: %s\nLatest version:  %s\n' "$current_version" "$version"
  if [[ "$current_version" == "$version" ]]; then
    printf 'Already up to date.\n'
    exit 0
  fi

  src_hash="$(nix flake prefetch --json "github:${UPSTREAM_REPO}/v${version}" | jq -r .hash)"
  [[ "$src_hash" == sha256-* ]] || fail "could not prefetch the v${version} source"

  sed -i \
    -e "s|^    version = \"${current_version}\";|    version = \"${version}\";|" \
    -e "/src = fetchFromGitHub {/,/};/ s|^      hash = .*|      hash = \"${src_hash}\";|" \
    "$PACKAGE_FILE"

  # The pnpm dependency hash can only be learned by fetching with a fake hash
  # and reading the one Nix reports.
  set_pnpm_hash "$FAKE_HASH"
  build_log="$(nix build .#immich.pnpmDeps --no-link 2>&1 || true)"
  pnpm_hash="$(sed -n 's/^ *got: *\(sha256-[^ ]*\).*/\1/p' <<<"$build_log" | tail -n1)"
  [[ -n "$pnpm_hash" ]] || fail "could not determine the pnpm dependency hash:
${build_log}"
  set_pnpm_hash "$pnpm_hash"

  sed -i \
    -e "s|releases/tag/v${current_version}|releases/tag/v${version}|g" \
    -e "s|immich-${current_version}|immich-${version}|g" \
    -e "s|Immich ${current_version}|Immich ${version}|g" \
    -e "s|./scripts/update.sh ${current_version}|./scripts/update.sh ${version}|g" \
    README.md

  git ls-files -z '*.nix' | xargs -0 nix fmt --
  nix flake check --print-build-logs
  nix build .#immich --print-build-logs
  test -x result/bin/server || fail "built package does not contain bin/server"

  printf 'Updated Immich from %s to %s.\n' "$current_version" "$version"
}

main "$@"
