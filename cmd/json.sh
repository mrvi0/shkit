#!/usr/bin/env bash
# shkit json — validate & format JSON via jq

cmd_json_usage() {
	cat <<EOF
$(ui::muted "shkit json") — validate and pretty-print JSON

Usage:
  shkit json [options] ['{"a":1}']
  shkit json -f file.json
  echo '{"a":1}' | shkit json

Options:
  -f, --file PATH      Read JSON from file
  -o, --output PATH    Write formatted JSON to file
  -i, --indent N       Indent spaces (default: 2)
      --info           Show type / size summary
  -q, --quiet          Suppress status lines (print JSON only)
  -h, --help           Show help

Requires: jq
EOF
}

cmd_json() {
	local input_file="" output_file="" indent=2 show_info=0 quiet=0 json_string=""

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-f | --file)
			input_file="${2:-}"
			shift 2
			;;
		-o | --output)
			output_file="${2:-}"
			shift 2
			;;
		-i | --indent)
			indent="${2:-}"
			validation::is_non_negative_integer "$indent" || ui::die "Indent must be a non-negative integer"
			shift 2
			;;
		--info)
			show_info=1
			shift
			;;
		-q | --quiet)
			quiet=1
			shift
			;;
		-h | --help)
			cmd_json_usage
			return 0
			;;
		-*)
			ui::die "Unknown option: $1"
			;;
		*)
			json_string="$1"
			shift
			;;
		esac
	done

	ui::require_cmd jq "Ubuntu/Debian: sudo apt install jq  |  macOS: brew install jq"

	local content source
	if [[ -n "$input_file" ]]; then
		[[ -f "$input_file" ]] || ui::die "File not found: ${input_file}"
		content="$(cat -- "$input_file")"
		source="file:${input_file}"
	elif [[ -n "$json_string" ]]; then
		content="$json_string"
		source="arg"
	elif [[ ! -t 0 ]]; then
		content="$(cat)"
		source="stdin"
	else
		ui::die "No JSON input. Pass a string, -f file, or pipe on stdin."
	fi

	if ! printf '%s' "$content" | jq . >/dev/null 2>&1; then
		ui::err "Invalid JSON (${source})"
		printf '%s' "$content" | jq . 2>&1 | head -3 | sed 's/^/  /' || true
		return 1
	fi

	[[ "$quiet" -eq 0 ]] && ui::ok "Valid JSON (${source})"

	local formatted
	formatted="$(printf '%s' "$content" | jq . --indent "$indent")"

	if [[ -n "$output_file" ]]; then
		printf '%s\n' "$formatted" >"$output_file"
		[[ "$quiet" -eq 0 ]] && ui::ok "Wrote ${output_file}"
	else
		[[ "$quiet" -eq 0 ]] && ui::muted "Formatted"
		printf '%s\n' "$formatted"
	fi

	if [[ "$show_info" -eq 1 ]]; then
		echo
		ui::header "Info"
		local root_type size
		root_type="$(printf '%s' "$content" | jq -r 'type')"
		size="$(printf '%s' "$content" | jq -c . | wc -c | tr -d ' ')"
		echo "  type  ${root_type}"
		echo "  size  $((size - 1)) chars"
		case "$root_type" in
		array) echo "  len   $(printf '%s' "$content" | jq 'length')" ;;
		object) echo "  keys  $(printf '%s' "$content" | jq 'keys | length')" ;;
		esac
	fi
}
