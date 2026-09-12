#!/usr/bin/env bash
#
# combine-context.sh: assemble selected Markdown/text documents into one context file.
#
# Project-specific settings live in .combine-context.conf (create it with --init),
# so this script can be copied between projects without modification.
#
# Requires bash 3.2+ and POSIX tools. Works with both GNU and BSD userlands.

set -euo pipefail

readonly CONFIG_NAME=".combine-context.conf"

usage() {
    cat <<'HELP'
Usage:
  combine-context.sh [options] [FILE ...]
  combine-context.sh --init [--project NAME] [--slug SLUG] [--output FILE] [--root DIR] [--force]

Combine selected Markdown/text documents into one context file.

Configuration:
  Project settings are read from .combine-context.conf, searched for upwards
  from the current directory, then upwards from the script's directory.
  Create one with --init. Relative paths inside the config are resolved
  against the config file's directory; relative paths passed on the command
  line are resolved against the current directory.

  Precedence: command-line options > config file > built-in defaults.

Selection:
  Explicit files:
    combine-context.sh docs/Architecture.md docs/adr/ADR-0003-Top-Level-Structure.md

  Tags:
    combine-context.sh --tag top-level --tag renderer

  Both:
    combine-context.sh --tag top-level docs/Roadmap.md

  A tag without the project prefix also matches its prefixed form: with
  PROJECT_SLUG=yana-engine, "renderer" selects documents tagged either
  "renderer" or "yana-engine-renderer".

Options:
  -c, --config FILE    Config file (default: nearest .combine-context.conf)
  -r, --root DIR       Search root for tagged files (default: docs)
  -o, --output FILE    Output file (default: <slug>-context.md)
  -t, --tag TAG        Select files with TAG; may be repeated
  -m, --match MODE     Tag mode: any or all (default: any)
      --extensions CSV Extensions searched for tags (default: md,txt)
      --project NAME   Project name used in the bundle heading
      --slug SLUG      Project tag prefix, lowercase kebab-case
      --no-toc         Omit the included-files list
      --dry-run        Print selected files only
      --print-config   Print the effective configuration and exit
      --init           Write a config file and exit (prompts when interactive)
      --force          With --init, overwrite an existing config file
  -h, --help           Show help

  --init writes to --config FILE if given, otherwise to .combine-context.conf
  in the git repository root (or the current directory outside git).

Supported tag forms:

  ---
  tags: [architecture, events, threading]
  ---

  ---
  tags:
    - architecture
    - events
  ---

  <!-- context-tags: architecture, events, threading -->
HELP
}

die() {
    printf 'error: %s\n' "$*" >&2
    exit 2
}

note() {
    printf 'note: %s\n' "$*" >&2
}

require_value() {
    (($# >= 2)) || die "option $1 requires a value"
}

trim() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    printf '%s' "$s"
}

unquote() {
    local s="$1"
    if ((${#s} >= 2)); then
        case "$s" in
            \"*\" | \'*\') s="${s:1:${#s}-2}" ;;
        esac
    fi
    printf '%s' "$s"
}

lowercase() {
    printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

slugify() {
    lowercase "$1" | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

is_valid_slug() {
    [[ "$1" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]
}

abs_dir() {
    (cd "$1" && pwd -P)
}

abs_file() {
    local dir
    dir="$(abs_dir "$(dirname "$1")")" || return 1
    printf '%s/%s' "$dir" "$(basename "$1")"
}

# Joins a relative path onto a base directory; absolute paths are returned unchanged.
resolve() {
    case "$2" in
        /*) printf '%s' "$2" ;;
        *) printf '%s/%s' "$1" "$2" ;;
    esac
}

# Shows paths inside the project relative to it, so bundles do not leak local directories.
display_path() {
    case "$1" in
        "$base_dir"/*) printf '%s' "${1#"$base_dir"/}" ;;
        *) printf '%s' "$1" ;;
    esac
}

find_config_from() {
    local dir="$1"
    while :; do
        if [[ -f "$dir/$CONFIG_NAME" ]]; then
            printf '%s' "$dir/$CONFIG_NAME"
            return 0
        fi
        [[ "$dir" != "/" ]] || return 1
        dir="$(dirname "$dir")"
    done
}

# The config is parsed rather than sourced, so it can never execute code.
load_config() {
    local file="$1" line key value lineno=0
    local skip_re='^[[:space:]]*(#.*)?$'

    while IFS= read -r line || [[ -n "$line" ]]; do
        lineno=$((lineno + 1))
        line="${line%$'\r'}"
        if [[ $line =~ $skip_re ]]; then
            continue
        fi
        [[ "$line" == *=* ]] || die "$file:$lineno: expected KEY=value"

        key="$(trim "${line%%=*}")"
        value="$(unquote "$(trim "${line#*=}")")"

        case "$key" in
            PROJECT_NAME) cfg_project="$value" ;;
            PROJECT_SLUG) cfg_slug="$value" ;;
            ROOT) cfg_root="$value" ;;
            OUTPUT) cfg_output="$value" ;;
            MATCH_MODE) cfg_match="$value" ;;
            EXTENSIONS) cfg_extensions="$value" ;;
            *) die "$file:$lineno: unknown key '$key'" ;;
        esac
    done <"$file"
}

prompt() {
    local answer=""
    read -r -p "$1 [$2]: " answer || true
    printf '%s' "${answer:-$2}"
}

validate_settings() {
    [[ "$1" == "any" || "$1" == "all" ]] || die "match mode must be 'any' or 'all', got '$1'"
    [[ -n "$2" ]] || die "extensions must not be empty"
    [[ -z "$3" ]] || is_valid_slug "$3" || die "slug must be lowercase kebab-case, got '$3'"
}

run_init() {
    local target target_dir default_project project slug output root match extensions

    if [[ -n "$cli_config" ]]; then
        target="$cli_config"
    else
        target="$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)/$CONFIG_NAME"
    fi

    if [[ -e "$target" ]] && ((!force)); then
        die "config already exists: $target (use --force to overwrite)"
    fi

    mkdir -p "$(dirname "$target")"
    target_dir="$(abs_dir "$(dirname "$target")")"
    default_project="$(basename "$target_dir")"

    project="$cli_project"
    slug="$cli_slug"
    output="$cli_output"

    if [[ -t 0 ]]; then
        [[ -n "$project" ]] || project="$(prompt 'Project name' "$default_project")"
        [[ -n "$slug" ]] || slug="$(prompt 'Tag prefix' "$(slugify "$project")")"
        [[ -n "$output" ]] || output="$(prompt 'Output file' "$slug-context.md")"
    fi

    project="${project:-$default_project}"
    slug="${slug:-$(slugify "$project")}"
    output="${output:-$slug-context.md}"
    root="${cli_root:-docs}"
    match="${cli_match:-any}"
    extensions="${cli_extensions:-md,txt}"

    [[ -n "$slug" ]] || die "cannot derive a tag prefix from '$project'; pass --slug"
    validate_settings "$match" "$extensions" "$slug"

    cat >"$target" <<CONFIG
# Configuration for combine-context.sh.
# Plain KEY=value lines: the file is parsed, never executed.
# Relative paths are resolved against the directory of this file.

# Project name used in the bundle heading.
PROJECT_NAME=$project

# Tag prefix. A tag passed without it also matches the prefixed form:
# "renderer" selects "renderer" and "$slug-renderer".
PROJECT_SLUG=$slug

# Directory searched for tagged documents.
ROOT=$root

# Generated context bundle.
OUTPUT=$output

# How several --tag options combine: any or all.
MATCH_MODE=$match

# File extensions searched for tags.
EXTENSIONS=$extensions
CONFIG

    printf 'Created %s\n' "$target"

    if git -C "$target_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1 &&
        ! git -C "$target_dir" check-ignore -q -- "$output" 2>/dev/null; then
        note "'$output' is not ignored by git; consider adding it to .gitignore"
    fi
}

extract_tags() {
    awk '
        BEGIN { in_front = 0; in_list = 0 }
        NR == 1 && $0 ~ /^---[[:space:]]*$/ { in_front = 1; next }
        in_front && $0 ~ /^---[[:space:]]*$/ { in_front = 0; in_list = 0; next }
        in_front {
            if ($0 ~ /^[[:space:]]*tags[[:space:]]*:/) {
                line = $0
                sub(/^[[:space:]]*tags[[:space:]]*:[[:space:]]*/, "", line)
                if (line == "") { in_list = 1; next }
                gsub(/[\[\]]/, "", line)
                n = split(line, values, ",")
                for (i = 1; i <= n; ++i) {
                    tag = values[i]
                    gsub(/^[[:space:]"\047]+|[[:space:]"\047]+$/, "", tag)
                    if (tag != "") print tolower(tag)
                }
                next
            }
            if (in_list && $0 ~ /^[[:space:]]*-[[:space:]]+/) {
                tag = $0
                sub(/^[[:space:]]*-[[:space:]]+/, "", tag)
                gsub(/^[[:space:]"\047]+|[[:space:]"\047]+$/, "", tag)
                if (tag != "") print tolower(tag)
                next
            }
            if (in_list && $0 !~ /^[[:space:]]*$/) in_list = 0
        }
        {
            line = $0
            if (match(line, /<!--[[:space:]]*context-tags[[:space:]]*:[^>]*-->/)) {
                value = substr(line, RSTART, RLENGTH)
                sub(/^<!--[[:space:]]*context-tags[[:space:]]*:[[:space:]]*/, "", value)
                sub(/[[:space:]]*-->$/, "", value)
                n = split(value, values, ",")
                for (i = 1; i <= n; ++i) {
                    tag = values[i]
                    gsub(/^[[:space:]"\047]+|[[:space:]"\047]+$/, "", tag)
                    if (tag != "") print tolower(tag)
                }
            }
        }
    ' "$1" | awk 'NF && !seen[$0]++'
}

file_matches_tags() {
    local extracted i found matched=0
    extracted="$(extract_tags "$1")"
    [[ -n "$extracted" ]] || return 1

    for ((i = 0; i < ${#req_plain[@]}; ++i)); do
        found=0
        if grep -Fxq -- "${req_plain[i]}" <<<"$extracted"; then
            found=1
        elif [[ -n "${req_prefixed[i]}" ]] && grep -Fxq -- "${req_prefixed[i]}" <<<"$extracted"; then
            found=1
        fi

        if ((found)); then
            matched=$((matched + 1))
        elif [[ "$match_mode" == "all" ]]; then
            return 1
        fi
    done

    if [[ "$match_mode" == "all" ]]; then
        ((matched == ${#req_plain[@]}))
    else
        ((matched > 0))
    fi
}

# ---------------------------------------------------------------------------
# Command line

cli_config="" cli_root="" cli_output="" cli_match="" cli_extensions=""
cli_project="" cli_slug=""
write_toc=1 dry_run=0 print_config=0 init=0 force=0
tags=()
explicit_files=()

while (($#)); do
    case "$1" in
        -c|--config) require_value "$@"; cli_config="$2"; shift 2 ;;
        -r|--root) require_value "$@"; cli_root="$2"; shift 2 ;;
        -o|--output) require_value "$@"; cli_output="$2"; shift 2 ;;
        -t|--tag) require_value "$@"; tags+=("$2"); shift 2 ;;
        -m|--match) require_value "$@"; cli_match="$2"; shift 2 ;;
        --extensions) require_value "$@"; cli_extensions="$2"; shift 2 ;;
        --project) require_value "$@"; cli_project="$2"; shift 2 ;;
        --slug) require_value "$@"; cli_slug="$2"; shift 2 ;;
        --no-toc) write_toc=0; shift ;;
        --dry-run) dry_run=1; shift ;;
        --print-config) print_config=1; shift ;;
        --init) init=1; shift ;;
        --force) force=1; shift ;;
        -h|--help) usage; exit 0 ;;
        --) shift; explicit_files+=("$@"); break ;;
        -*) printf 'error: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
        *) explicit_files+=("$1"); shift ;;
    esac
done

if ((init)); then
    run_init
    exit 0
fi

# ---------------------------------------------------------------------------
# Configuration

cfg_project="" cfg_slug="" cfg_root="" cfg_output="" cfg_match="" cfg_extensions=""
cwd="$(pwd -P)"
script_dir="$(abs_dir "$(dirname "${BASH_SOURCE[0]}")")"
config_file=""

if [[ -n "$cli_config" ]]; then
    [[ -f "$cli_config" ]] || die "config file does not exist: $cli_config"
    config_file="$(abs_file "$cli_config")"
else
    config_file="$(find_config_from "$cwd" || find_config_from "$script_dir" || true)"
fi

if [[ -n "$config_file" ]]; then
    load_config "$config_file"
    base_dir="$(dirname "$config_file")"
else
    base_dir="$cwd"
    note "no $CONFIG_NAME found; using defaults (run with --init to create one)"
fi

project="${cli_project:-${cfg_project:-$(basename "$base_dir")}}"
slug="${cli_slug:-$cfg_slug}"
match_mode="$(lowercase "${cli_match:-${cfg_match:-any}}")"
extensions="${cli_extensions:-${cfg_extensions:-md,txt}}"

if [[ -n "$cli_root" ]]; then
    root_path="$(resolve "$cwd" "$cli_root")"
else
    root_path="$(resolve "$base_dir" "${cfg_root:-docs}")"
fi

if [[ -n "$cli_output" ]]; then
    output_path="$(resolve "$cwd" "$cli_output")"
elif [[ -n "$cfg_output" ]]; then
    output_path="$(resolve "$base_dir" "$cfg_output")"
else
    default_slug="${slug:-$(slugify "$project")}"
    output_path="$base_dir/${default_slug:-project}-context.md"
fi

validate_settings "$match_mode" "$extensions" "$slug"

if [[ -d "$(dirname "$output_path")" ]]; then
    output_path="$(abs_file "$output_path")"
fi

if ((print_config)); then
    printf 'config:     %s\n' "${config_file:-(none)}"
    printf 'project:    %s\n' "$project"
    printf 'slug:       %s\n' "${slug:-(none)}"
    printf 'root:       %s\n' "$root_path"
    printf 'output:     %s\n' "$output_path"
    printf 'match:      %s\n' "$match_mode"
    printf 'extensions: %s\n' "$extensions"
    exit 0
fi

# ---------------------------------------------------------------------------
# Selection

req_plain=()
req_prefixed=()
for tag in ${tags[@]+"${tags[@]}"}; do
    tag="$(lowercase "$tag")"
    req_plain+=("$tag")
    if [[ -n "$slug" && "$tag" != "$slug"-* ]]; then
        req_prefixed+=("$slug-$tag")
    else
        req_prefixed+=("")
    fi
done

candidates=()
for file in ${explicit_files[@]+"${explicit_files[@]}"}; do
    [[ -f "$file" ]] || die "explicit file does not exist: $file"
    candidates+=("$(abs_file "$file")")
done

if ((${#req_plain[@]} > 0)); then
    [[ -d "$root_path" ]] || die "tag search root does not exist: $root_path"

    ext_array=()
    IFS=',' read -r -a ext_array <<<"$extensions"
    find_args=("$(abs_dir "$root_path")" -type f "(")
    first=1
    for ext in ${ext_array[@]+"${ext_array[@]}"}; do
        ext="$(trim "$ext")"
        ext="${ext#.}"
        [[ -n "$ext" ]] || continue
        ((first)) || find_args+=("-o")
        find_args+=("-iname" "*.${ext}")
        first=0
    done
    ((!first)) || die "no usable extensions in '$extensions'"
    find_args+=(")" -print0)

    while IFS= read -r -d '' file; do
        if file_matches_tags "$file"; then
            candidates+=("$file")
        fi
    done < <(find "${find_args[@]}" | sort -z)
fi

selected=()
seen=$'\n'
for file in ${candidates[@]+"${candidates[@]}"}; do
    # The bundle must never include a previous version of itself.
    [[ "$file" != "$output_path" ]] || continue
    case "$seen" in
        *$'\n'"$file"$'\n'*) continue ;;
    esac
    seen+="$file"$'\n'
    selected+=("$file")
done

if ((${#selected[@]} == 0)); then
    printf 'error: no files selected (pass --tag TAG or FILE; see --help)\n' >&2
    exit 1
fi

if ((dry_run)); then
    for file in "${selected[@]}"; do
        display_path "$file"
        printf '\n'
    done
    exit 0
fi

# ---------------------------------------------------------------------------
# Output

mkdir -p "$(dirname "$output_path")"
{
    printf '# %s Context Bundle\n\n' "$project"
    printf '> Generated by `%s`. Each section preserves its source filename.\n\n' "$(basename "$0")"

    if ((write_toc)); then
        printf '## Included sources\n\n'
        for file in "${selected[@]}"; do
            printf -- '- `%s`\n' "$(display_path "$file")"
        done
        printf '\n---\n\n'
    fi

    for file in "${selected[@]}"; do
        printf '# Source: `%s`\n\n' "$(display_path "$file")"
        cat -- "$file"
        printf '\n\n---\n\n'
    done
} >"$output_path"

printf 'Created %s from %d source file(s).\n' "$(display_path "$output_path")" "${#selected[@]}"
