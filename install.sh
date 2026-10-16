#!/usr/bin/env bash
# Install shkit into ~/.local/bin (or PREFIX)
set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local}"
BIN_DIR="${PREFIX}/bin"
SHARE_DIR="${PREFIX}/share/shkit"
REPO_URL="${REPO_URL:-https://github.com/mrvi0/shkit.git}"
BRANCH="${BRANCH:-master}"

info() { printf '\033[0;36m→\033[0m %s\n' "$*"; }
ok()   { printf '\033[0;32m✓\033[0m %s\n' "$*"; }
die()  { printf '\033[0;31m✗\033[0m %s\n' "$*" >&2; exit 1; }

command -v bash >/dev/null 2>&1 || die "bash is required"

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC=""

if [[ -x "${SELF_DIR}/bin/shkit" && -d "${SELF_DIR}/cmd" && -d "${SELF_DIR}/lib" ]]; then
	SRC="$SELF_DIR"
	info "Installing from local checkout"
else
	command -v git >/dev/null 2>&1 || die "git is required"
	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' EXIT
	info "Cloning shkit (${BRANCH})"
	git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$tmpdir/shkit" >/dev/null 2>&1 \
		|| die "Failed to clone ${REPO_URL} (branch ${BRANCH})"
	SRC="$tmpdir/shkit"
fi

info "Installing to ${SHARE_DIR}"
mkdir -p "$BIN_DIR" "$SHARE_DIR"
rm -rf "${SHARE_DIR}/bin" "${SHARE_DIR}/cmd" "${SHARE_DIR}/lib" "${SHARE_DIR}/completions"
cp -a "${SRC}/bin" "${SRC}/cmd" "${SRC}/lib" "$SHARE_DIR/"
[[ -d "${SRC}/completions" ]] && cp -a "${SRC}/completions" "$SHARE_DIR/"

ln -sfn "${SHARE_DIR}/bin/shkit" "${BIN_DIR}/shkit"
chmod +x "${SHARE_DIR}/bin/shkit" "${BIN_DIR}/shkit"

ok "shkit installed → ${BIN_DIR}/shkit"

if ! command -v shkit >/dev/null 2>&1; then
	case ":$PATH:" in
	*":${BIN_DIR}:"*) ;;
	*)
		info "Add to your shell profile:"
		echo "  export PATH=\"${BIN_DIR}:\$PATH\""
		;;
	esac
fi

"${BIN_DIR}/shkit" version
ok "Done. Try: shkit help"
