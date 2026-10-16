#!/usr/bin/env bash
# shkit shared bootstrap — colors, logging, tiny UI helpers
set -euo pipefail

SHKIT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SHKIT_LIB_DIR}/colors.sh"
# shellcheck source=/dev/null
source "${SHKIT_LIB_DIR}/logging.sh"
# shellcheck source=/dev/null
source "${SHKIT_LIB_DIR}/validation.sh"

logging::init

SHKIT_VERSION="0.1.0"

ui::header()  { colors::print "$BOLD_CYAN" "$1"; }
ui::ok()      { colors::success "$1"; }
ui::warn()    { colors::warning "$1"; }
ui::err()     { colors::error "$1"; }
ui::info()    { colors::info "$1"; }
ui::muted()   { colors::print "$CYAN" "$1"; }

ui::require_cmd() {
	local cmd="$1"
	local hint="${2:-}"
	if ! command -v "$cmd" >/dev/null 2>&1; then
		ui::err "Missing dependency: ${cmd}"
		[[ -n "$hint" ]] && ui::muted "  ${hint}"
		return 1
	fi
}

ui::die() {
	ui::err "$1"
	exit "${2:-1}"
}
