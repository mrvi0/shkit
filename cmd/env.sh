#!/usr/bin/env bash
# shkit env — compare .env vs .env.example

cmd_env_json_escape() {
	local s="${1-}"
	s="${s//\\/\\\\}"
	s="${s//\"/\\\"}"
	s="${s//$'\n'/\\n}"
	s="${s//$'\r'/\\r}"
	s="${s//$'\t'/\\t}"
	printf '%s' "$s"
}

cmd_env_json_string_array() {
	local -n _arr=$1
	local i=0
	printf '['
	for item in "${_arr[@]+"${_arr[@]}"}"; do
		((i++)) && printf ','
		printf '"%s"' "$(cmd_env_json_escape "$item")"
	done
	printf ']'
}

cmd_env_usage() {
	cat <<EOF
$(ui::muted "shkit env") — compare environment files

Usage:
  shkit env [options] [directory]

Options:
  -e, --env FILE       Path to .env           (default: ./.env)
  -x, --example FILE   Path to .env.example   (default: ./.env.example)
  -j, --json           Machine-readable JSON (CI / scripts)
  -h, --help           Show help

Exit codes:
  0  files match (no missing / extra / mismatched keys)
  1  differences found or error
EOF
}

cmd_env() {
	local env_file="" example_file="" target_dir="" json_out=0

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-e | --env)
			env_file="${2:-}"
			shift 2
			;;
		-x | --example)
			example_file="${2:-}"
			shift 2
			;;
		-j | --json)
			json_out=1
			shift
			;;
		-h | --help)
			cmd_env_usage
			return 0
			;;
		-*)
			ui::die "Unknown option: $1"
			;;
		*)
			target_dir="$1"
			shift
			;;
		esac
	done

	if [[ -z "$env_file" ]]; then
		if [[ -n "$target_dir" ]]; then
			env_file="${target_dir}/.env"
		else
			env_file=".env"
		fi
	fi
	if [[ -z "$example_file" ]]; then
		if [[ -n "$target_dir" ]]; then
			example_file="${target_dir}/.env.example"
		else
			example_file=".env.example"
		fi
	fi

	[[ -f "$env_file" ]] || ui::die ".env not found: ${env_file}"
	[[ -f "$example_file" ]] || ui::die ".env.example not found: ${example_file}"

	declare -A env_vars=()
	declare -A example_vars=()

	local key value
	while IFS='=' read -r key value || [[ -n "${key:-}" ]]; do
		[[ "${key:-}" =~ ^[[:space:]]*# ]] && continue
		[[ -z "${key:-}" ]] && continue
		key="${key%%[[:space:]]*}"
		[[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
		env_vars["$key"]="${value}"
	done < <(grep -vE '^\s*(#|$)' "$env_file" || true)

	while IFS='=' read -r key value || [[ -n "${key:-}" ]]; do
		[[ "${key:-}" =~ ^[[:space:]]*# ]] && continue
		[[ -z "${key:-}" ]] && continue
		key="${key%%[[:space:]]*}"
		[[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
		example_vars["$key"]="${value}"
	done < <(grep -vE '^\s*(#|$)' "$example_file" || true)

	local -a missing=() extra=() diff=()

	for key in "${!example_vars[@]}"; do
		if [[ -z "${env_vars[$key]+x}" ]]; then
			missing+=("$key")
		elif [[ "${env_vars[$key]}" != "${example_vars[$key]}" ]]; then
			diff+=("$key")
		fi
	done
	for key in "${!env_vars[@]}"; do
		[[ -z "${example_vars[$key]+x}" ]] && extra+=("$key")
	done

	if ((${#missing[@]})); then
		mapfile -t missing < <(printf '%s\n' "${missing[@]}" | sort)
	fi
	if ((${#extra[@]})); then
		mapfile -t extra < <(printf '%s\n' "${extra[@]}" | sort)
	fi
	if ((${#diff[@]})); then
		mapfile -t diff < <(printf '%s\n' "${diff[@]}" | sort)
	fi

	local ok=true
	if ((${#missing[@]} + ${#extra[@]} + ${#diff[@]} > 0)); then
		ok=false
	fi

	if [[ "$json_out" -eq 1 ]]; then
		local i=0
		printf '{\n'
		printf '  "env": "%s",\n' "$(cmd_env_json_escape "$env_file")"
		printf '  "example": "%s",\n' "$(cmd_env_json_escape "$example_file")"
		printf '  "ok": %s,\n' "$ok"
		printf '  "missing": '
		cmd_env_json_string_array missing
		printf ',\n'
		printf '  "extra": '
		cmd_env_json_string_array extra
		printf ',\n'
		printf '  "mismatched": ['
		i=0
		for key in "${diff[@]+"${diff[@]}"}"; do
			((i++)) && printf ','
			printf '\n    {"key":"%s","env":"%s","example":"%s"}' \
				"$(cmd_env_json_escape "$key")" \
				"$(cmd_env_json_escape "${env_vars[$key]}")" \
				"$(cmd_env_json_escape "${example_vars[$key]}")"
		done
		((i > 0)) && printf '\n  ' || true
		printf '],\n'
		printf '  "summary": {"missing":%d,"extra":%d,"mismatched":%d}\n' \
			"${#missing[@]}" "${#extra[@]}" "${#diff[@]}"
		printf '}\n'
		[[ "$ok" == true ]]
		return
	fi

	ui::header "Comparing"
	ui::muted "  example  ${example_file}"
	ui::muted "  env      ${env_file}"
	echo

	if ((${#missing[@]})); then
		ui::warn "Missing in .env (present in example)"
		for key in "${missing[@]}"; do
			echo "  - ${key}"
		done
		echo
	else
		ui::ok "No missing variables"
	fi

	if ((${#extra[@]})); then
		ui::warn "Extra in .env (not in example)"
		for key in "${extra[@]}"; do
			echo "  - ${key}"
		done
		echo
	else
		ui::ok "No extra variables"
	fi

	if ((${#diff[@]})); then
		ui::warn "Mismatched values"
		for key in "${diff[@]}"; do
			echo "  - ${key}"
			ui::muted "      .env         = ${env_vars[$key]}"
			ui::muted "      .env.example = ${example_vars[$key]}"
		done
		echo
	else
		ui::ok "No mismatched values"
	fi

	ui::header "Summary"
	echo "  missing     ${#missing[@]}"
	echo "  extra       ${#extra[@]}"
	echo "  mismatched  ${#diff[@]}"

	if [[ "$ok" == true ]]; then
		ui::ok "Environment files look aligned"
		return 0
	fi
	return 1
}
