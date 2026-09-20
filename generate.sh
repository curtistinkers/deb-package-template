#!/usr/bin/env bash
set -euo pipefail

# Defines the list of Liquid replacement keys configured in this script.
get_defined_keys() {
    echo "package_name"
    echo "package_section"
    echo "package_priority"
    echo "maintainer_name"
    echo "maintainer_email"
    echo "package_git_url"
    echo "package_architecture"
    echo "short_description"
    echo "long_description"
    echo "copyright_year"
}

# Prints usage information for the script.
print_usage() {
    echo "Usage: ${0}"
    echo "Prompts for values of pre-defined keys and replaces Liquid-style tags in ./README.md, ./LICENSE.md, and ./package/debian/*."
}

# Removes the template header block from README.md between REMOVE comments.
remove_readme_header() {
    local file="./README.md"
    if [[ ! -f "${file}" ]]; then
        return 1
    fi

    # Delete lines from <!-- REMOVE --> to <!-- /REMOVE --> inclusive
    sed -E -i.bak '/<!-- REMOVE -->/,/<!-- \/REMOVE -->/d' "${file}"
    rm -f "${file}.bak"
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

    local formatted_val=""
    formatted_val="$(printf '%s\n' "${value}")"

    local escaped_value=""
    escaped_value="$(printf '%s\n' "${formatted_val}" | sed -e 's/[\/&]/\\&/g')"

    sed -E -i.bak "s/\\{\\{\\s*${key}\\s*\\}\\}/${escaped_value}/g" "${file}"
    rm -f "${file}.bak"
}

# Processes hardcoded targets (README, LICENSE, and package/debian/*).
process_targets() {
    local key="${1}"
    local value="${2}"

    local target=""
    for target in "./README.md" "./LICENSE.md"; do
        if [[ -f "${target}" ]]; then
            substitute_tags "${key}" "${value}" "${target}"
        fi
    done

    if [[ -d "./package/debian" ]]; then
        local file=""
        while IFS= read -r -d '' file; do
            substitute_tags "${key}" "${value}" "${file}"
        done < <(find "./package/debian" -type f -print0 || true)
    fi
}

# Prompts for each pre-defined key and applies substitutions across all targets.
prompt_and_process() {
    remove_readme_header

    local keys=()
    local raw_keys=""

    raw_keys="$(get_defined_keys)"
    readarray -t keys <<< "${raw_keys}"

    if [[ "${#keys[@]}" -eq 0 ]]; then
        echo "Error: No keys defined in get_defined_keys()." >&2
        return 1
    fi

    declare -A variable_values=()

    local key=""
    for key in "${keys[@]}"; do
        local user_val=""
        read -r -p "Enter value for '${key}': " user_val
        variable_values["${key}"]="${user_val}"
    done

    for key in "${keys[@]}"; do
        process_targets "${key}" "${variable_values["${key}"]}"
    done
}

# Main orchestration function.
main() {
    if [[ "${#}" -gt 0 ]]; then
        print_usage
        exit 1
    fi

    prompt_and_process
}

main "${@}"

exit 0
