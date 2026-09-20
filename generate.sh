#!/usr/bin/env bash
set -euo pipefail

# Defines the list of Liquid replacement keys configured in this script.
get_defined_keys() {
    echo "site_title"
    echo "author_name"
    echo "version"
}

# Prints usage information for the script.
print_usage() {
    echo "Usage: ${0} <directory_or_file>"
    echo "Prompts for values of pre-defined keys and replaces Liquid-style tags in the target."
}

# Substitutes Liquid tags within a single specified file.
substitute_tags() {
    local key="${1}"
    local value="${2}"
    local file="${3}"

    if [[ ! -f "${file}" ]]; then
        echo "Error: File '${file}' does not exist." >&2
        return 1
    fi

    local escaped_value
    escaped_value=$(printf '%s\n' "${value}" | sed -e 's/[\/&]/\\&/g')

    sed -E -i.bak "s/\\{\\{\\s*${key}\\s*\\}\\}/${escaped_value}/g" "${file}"
    rm -f "${file}.bak"
}

# Recursively processes all files inside a given directory.
process_directory() {
    local key="${1}"
    local value="${2}"
    local dir="${3}"

    if [[ ! -d "${dir}" ]]; then
        echo "Error: Directory '${dir}' does not exist." >&2
        return 1
    fi

    local file=""
    while IFS= read -r -d '' file; do
        substitute_tags "${key}" "${value}" "${file}"
    done < <(find "${dir}" -type f -print0)
}

# Applies substitutions for a given key-value pair to a file or directory.
apply_replacements() {
    local target="${1}"
    local key="${2}"
    local value="${3}"

    if [[ -d "${target}" ]]; then
        process_directory "${key}" "${value}" "${target}"
    elif [[ -f "${target}" ]]; then
        substitute_tags "${key}" "${value}" "${target}"
    else
        echo "Error: Target '${target}' is neither a valid file nor directory." >&2
        return 1
    fi
}

# Prompts for each pre-defined key and applies substitutions across the target.
prompt_and_process() {
    local target="${1}"
    local keys=()

    readarray -t keys < <(get_defined_keys)

    if [[ "${#keys[@]}" -eq 0 ]]; then
        echo "Error: No keys defined in get_defined_keys()." >&2
        return 1
    fi

    declare -A variable_values

    local key
    for key in "${keys[@]}"; do
        local user_val=""
        read -r -p "Enter value for '${key}': " user_val
        variable_values["${key}"]="${user_val}"
    done

    for key in "${keys[@]}"; do
        apply_replacements "${target}" "${key}" "${variable_values["${key}"]}"
    done
}

# Main orchestration function.
main() {
    if [[ "${#}" -ne 1 ]]; then
        print_usage
        exit 1
    fi

    local target="${1}"
    prompt_and_process "${target}"
}

main "${@}"
