#!/usr/bin/env bash
# shkit rename — batch file rename

cmd_rename_usage() {
	cat <<EOF
$(ui::muted "shkit rename") — batch rename files

Usage:
  shkit rename [options] <files...>

Options:
  -p, --prefix STR     Prepend to basename
  -s, --suffix STR     Append before extension
  -e, --ext EXT        Replace extension
  -r, --regex SED      sed expression on basename (e.g. s/old/new/g)
  -d, --dry-run        Preview only
  -v, --verbose        Extra detail
  -h, --help           Show help
EOF
}

cmd_rename_new_name() {
	local old="$1" prefix="$2" suffix="$3" new_ext="$4" regex="$5"
	local base ext name

	base="$(basename "$old")"
	if [[ "$base" == *.* ]]; then
		ext="${base##*.}"
		name="${base%.*}"
	else
		ext=""
		name="$base"
	fi

	[[ -n "$regex" ]] && name="$(printf '%s' "$name" | sed "$regex")"
	[[ -n "$prefix" ]] && name="${prefix}${name}"
	[[ -n "$suffix" ]] && name="${name}${suffix}"

	local dir
	dir="$(dirname "$old")"
	if [[ -n "$new_ext" ]]; then
		echo "${dir}/${name}.${new_ext}"
	elif [[ -n "$ext" ]]; then
		echo "${dir}/${name}.${ext}"
	else
		echo "${dir}/${name}"
	fi
}

cmd_rename() {
	local prefix="" suffix="" new_ext="" regex="" dry=0 verbose=0

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-p | --prefix)
			prefix="${2:-}"
			shift 2
			;;
		-s | --suffix)
			suffix="${2:-}"
			shift 2
			;;
		-e | --ext)
			new_ext="${2:-}"
			shift 2
			;;
		-r | --regex)
			regex="${2:-}"
			shift 2
			;;
		-d | --dry-run)
			dry=1
			shift
			;;
		-v | --verbose)
			verbose=1
			shift
			;;
		-h | --help)
			cmd_rename_usage
			return 0
			;;
		--)
			shift
			break
			;;
		-*)
			ui::die "Unknown option: $1"
			;;
		*)
			break
			;;
		esac
	done

	local -a files=("$@")
	if [[ ${#files[@]} -eq 0 ]]; then
		ui::die "No files specified. See: shkit rename --help"
	fi
	if [[ -z "$prefix$suffix$new_ext$regex" ]]; then
		ui::die "Specify at least one of --prefix / --suffix / --ext / --regex"
	fi
	if [[ -n "$regex" ]] && ! printf 'test' | sed "$regex" >/dev/null 2>&1; then
		ui::die "Invalid sed regex: ${regex}"
	fi

	[[ "$dry" -eq 1 ]] && ui::warn "Dry run — nothing will be renamed"
	ui::header "Rename"

	local renamed=0 errors=0 file new_name
	for file in "${files[@]}"; do
		if [[ ! -e "$file" ]]; then
			ui::err "Not found: ${file}"
			((errors++)) || true
			continue
		fi
		new_name="$(cmd_rename_new_name "$file" "$prefix" "$suffix" "$new_ext" "$regex")"
		if [[ "$file" == "$new_name" ]]; then
			[[ "$verbose" -eq 1 ]] && ui::muted "skip  ${file}"
			continue
		fi
		if [[ -e "$new_name" ]]; then
			ui::err "Target exists: ${new_name}"
			((errors++)) || true
			continue
		fi
		if [[ "$dry" -eq 1 ]]; then
			echo "  ${file}  →  ${new_name}"
			((renamed++)) || true
		else
			if mv -- "$file" "$new_name"; then
				ui::ok "${file}  →  ${new_name}"
				((renamed++)) || true
			else
				ui::err "Failed: ${file}"
				((errors++)) || true
			fi
		fi
	done

	echo
	ui::header "Summary"
	echo "  renamed  ${renamed}"
	echo "  errors   ${errors}"
	((errors == 0))
}
