# bash completion for shkit
_shkit() {
	local cur prev
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD - 1]}"

	if [[ $COMP_CWORD -eq 1 ]]; then
		COMPREPLY=($(compgen -W "env ports rename json version help" -- "$cur"))
		return 0
	fi

	case "${COMP_WORDS[1]}" in
	env)
		COMPREPLY=($(compgen -W "-e --env -x --example -h --help" -- "$cur"))
		;;
	ports)
		COMPREPLY=($(compgen -W "-i --interval -o --once -h --help" -- "$cur"))
		;;
	rename)
		COMPREPLY=($(compgen -W "-p --prefix -s --suffix -e --ext -r --regex -d --dry-run -v --verbose -h --help" -- "$cur"))
		;;
	json)
		COMPREPLY=($(compgen -W "-f --file -o --output -i --indent --info -q --quiet -h --help" -- "$cur"))
		;;
	esac
}
complete -F _shkit shkit
