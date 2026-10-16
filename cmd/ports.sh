#!/usr/bin/env bash
# shkit ports — watch listening ports

cmd_ports_usage() {
	cat <<EOF
$(ui::muted "shkit ports") — watch listening TCP/UDP ports

Usage:
  shkit ports [options]

Options:
  -i, --interval N   Poll interval in seconds (default: 5)
  -o, --once         Print current ports and exit
  -h, --help         Show help

Requires: ss (iproute2)
EOF
}

cmd_ports_snapshot() {
	ss -tulnp 2>/dev/null | awk 'NR>1 {print $1"\t"$5"\t"$7}' | sort
}

cmd_ports() {
	local interval=5 once=0

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-i | --interval)
			interval="${2:-}"
			validation::is_positive_integer "$interval" || ui::die "Interval must be a positive integer"
			shift 2
			;;
		-o | --once)
			once=1
			shift
			;;
		-h | --help)
			cmd_ports_usage
			return 0
			;;
		*)
			ui::die "Unknown option: $1"
			;;
		esac
	done

	ui::require_cmd ss "Install iproute2 (apt install iproute2 / dnf install iproute)"

	ui::header "Listening ports"
	local prev="" ports new_ports

	while true; do
		ports="$(cmd_ports_snapshot)"
		if [[ -z "$prev" ]]; then
			if [[ -z "$ports" ]]; then
				ui::warn "No listening ports detected"
			else
				ui::ok "Current listeners"
				printf '%s\n' "$ports" | while IFS=$'\t' read -r proto addr proc; do
					printf '  %-6s %-28s %s\n' "$proto" "$addr" "${proc:--}"
				done
			fi
		else
			new_ports="$(comm -13 <(printf '%s\n' "$prev") <(printf '%s\n' "$ports") || true)"
			if [[ -n "$new_ports" ]]; then
				ui::warn "New listening ports"
				printf '%s\n' "$new_ports" | while IFS=$'\t' read -r proto addr proc; do
					printf '  %-6s %-28s %s\n' "$proto" "$addr" "${proc:--}"
				done
			fi
		fi
		[[ "$once" -eq 1 ]] && return 0
		prev="$ports"
		sleep "$interval"
	done
}
