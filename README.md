<p align="center">
  <img src="https://img.shields.io/badge/shkit-shell%20toolkit-0ea5e9?style=for-the-badge&logo=gnubash&logoColor=white" alt="shkit" />
</p>

<pre align="center">
      _     _    _ _
  ___| |__ | | _(_) |_
 / __| '_ \| |/ / | __|
 \__ \ | | |   <| | |_
 |___/_| |_|_|\_\_|\__|
</pre>

<p align="center">
  <b>Tiny Bash toolkit for the chores you always reinvent.</b><br/>
  Compare <code>.env</code> files · watch ports · batch-rename · format JSON
</p>

<p align="center">
  <a href="#install"><img src="https://img.shields.io/badge/install-one%20liner-22c55e?style=flat-square" alt="install" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-yellow?style=flat-square" alt="MIT" /></a>
  <a href="#commands"><img src="https://img.shields.io/badge/bash-4.0%2B-4EAA25?style=flat-square&logo=gnubash&logoColor=white" alt="bash" /></a>
  <a href="https://github.com/mrvi0/shkit"><img src="https://img.shields.io/badge/github-mrvi0%2Fshkit-181717?style=flat-square&logo=github" alt="github" /></a>
</p>

---

## Why

You already have ten half-finished shell scripts in `~/bin`.  
**shkit** is those scripts, finished once, with a single entrypoint and a shared library.

| Command | What it does |
|---------|----------------|
| `shkit env` | Diff `.env` vs `.env.example` (missing / extra / mismatched) |
| `shkit ports` | List listening ports; watch for new ones |
| `shkit rename` | Prefix, suffix, extension, or sed-regex batch rename |
| `shkit json` | Validate & pretty-print JSON (via `jq`) |

Zero npm. Zero cargo. Just Bash.

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/mrvi0/shkit/master/install.sh | bash
```

Or from a clone:

```bash
git clone git@github.com:mrvi0/shkit.git
cd shkit
./install.sh
```

Installs to `~/.local/share/shkit` and links `~/.local/bin/shkit`.  
Ensure `~/.local/bin` is on your `PATH`.

Optional bash completion:

```bash
source ~/.local/share/shkit/completions/shkit.bash
```

### Dependencies

| Tool | Used by | Notes |
|------|---------|--------|
| Bash 4+ | everything | associative arrays |
| `ss` | `ports` | usually from `iproute2` |
| `jq` | `json` | `apt install jq` / `brew install jq` |

---

## Quick tour

```bash
shkit help
shkit version

# catch .env drift before deploy
shkit env
shkit env -e .env.prod -x .env.example
shkit env --json          # CI / scripts

# one-shot or watch
shkit ports --once
shkit ports -i 3

# preview then rename
shkit rename --dry-run --prefix "img_" *.png
shkit rename -r 's/ /_/g' *.md

# pipe-friendly JSON
echo '{"ok":true}' | shkit json
shkit json -f payload.json --info
```

---

## Commands

### `env`

```text
shkit env [options] [directory]
  -e, --env FILE        .env path
  -x, --example FILE    .env.example path
  -j, --json            machine-readable JSON
```

Exit `1` when anything differs — CI-friendly.

`--json` shape:

```json
{
  "env": ".env",
  "example": ".env.example",
  "ok": false,
  "missing": ["DEBUG"],
  "extra": ["SECRET_KEY"],
  "mismatched": [{"key":"APP_PORT","env":"8080","example":"3000"}],
  "summary": {"missing":1,"extra":1,"mismatched":1}
}
```

### `ports`

```text
shkit ports [options]
  -i, --interval N   poll seconds (default 5)
  -o, --once         print and exit
```

### `rename`

```text
shkit rename [options] <files...>
  -p, --prefix STR
  -s, --suffix STR
  -e, --ext EXT
  -r, --regex SED      e.g. s/old/new/g
  -d, --dry-run
  -v, --verbose
```

### `json`

```text
shkit json [options] ['{"a":1}']
  -f, --file PATH
  -o, --output PATH
  -i, --indent N
      --info
  -q, --quiet
```

---

## Library

Core helpers from the unfinished **bash-lib** experiment live in `lib/`:

- `colors.sh` — terminal colors & progress bar  
- `logging.sh` — leveled logging  
- `validation.sh` — integers, emails, ports, paths, …  
- `common.sh` — thin UI wrappers used by commands  

Source them in your own scripts:

```bash
source /path/to/shkit/lib/common.sh
ui::ok "deployed"
```

---

## Project layout

```text
shkit/
├── bin/shkit           # entrypoint
├── cmd/                # env · ports · rename · json
├── lib/                # shared bash library
├── completions/        # bash completion
├── examples/           # sample .env + JSON
├── tests/smoke.sh
└── install.sh
```

---

## Development

```bash
./bin/shkit help
./tests/smoke.sh
```

Contributions welcome — keep commands small, dependency-light, and boringly reliable.

---

## License

[MIT](LICENSE) © mrvi0

Born from consolidating `envdiff`, `port-watcher`, `batch-file-renamer`, `cli-json-formatter`, and `bash-lib`.
