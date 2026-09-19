#!/bin/sh

# Exit immediately if a command exits with a non-zero status
set -eu

# --- Configuration & Globals ---
TMP_INPUT="${1:-package}"
TARGET_INPUT="${TMP_INPUT%/}"
PROJECT_ROOT="$(pwd)"
OUTPUT_DIR="${PROJECT_ROOT}/dist"

# Readonly constants
readonly TMP_INPUT
readonly TARGET_INPUT
readonly PROJECT_ROOT
readonly OUTPUT_DIR

# Global placeholders (to be set during runtime validation)
SOURCE_DIR=""
PACKAGE_NAME=""
PARENT_DIR=""

# --- Helper Functions ---

log_info() {
    echo "💡 $1"
}

log_error() {
    echo "❌ Error: $1" >&2
}

# --- Core Task Functions ---

get_source_dir() {
    if [ -z "${TARGET_INPUT}" ]; then
        log_error "Please provide a directory name.\nUsage: $0 <directory_name>"
        exit 1
    fi

    if [ ! -d "${TARGET_INPUT}" ]; then
        log_error "Directory '${TARGET_INPUT}' does not exist."
        exit 1
    fi

    # Assign single variable
    SOURCE_DIR="$(cd "${TARGET_INPUT}" && pwd)"
}

validate_debian_directory() {
    if [ ! -d "${SOURCE_DIR}/debian" ]; then
        log_error "'${SOURCE_DIR}' is not a valid Debian package directory (missing 'debian/' folder)."
        exit 1
    fi
}

get_package_name() {
    # Assign single variable
    PACKAGE_NAME="$(awk '/^Package:/ {print $2; exit}' "${SOURCE_DIR}/debian/control")"

    if [ -z "${PACKAGE_NAME}" ]; then
        log_error "Could not determine Package name from '${SOURCE_DIR}/debian/control'."
        exit 1
    fi
}

get_parent_dir() {
    # Assign single variable
    PARENT_DIR="$(dirname "${SOURCE_DIR}")"
}

prepare_workspace() {
    log_info "Starting build process for package: ${PACKAGE_NAME} (Directory: ${TARGET_INPUT})"

    # Create output directory for binaries if it doesn't exist
    mkdir -p "${OUTPUT_DIR}"
    log_info "Created output directory for build artifacts: ${OUTPUT_DIR}"
}

clean_source_tree() {
    log_info "Cleaning up source directory..."
    # Always keep context explicit by cd'ing within the function
    cd "${SOURCE_DIR}"
    debuild --no-tgz-check -- clean >/dev/null 2>&1 || true
}

build_package() {
    log_info "Changing to package directory: ${SOURCE_DIR}"
    cd "${SOURCE_DIR}"

    log_info "Running debuild..."
    debuild -b -us -uc
}

move_build_artifacts() {
    cd "${PROJECT_ROOT}"
    log_info "Moving build artifacts for ${PACKAGE_NAME} to ${OUTPUT_DIR}..."

    # Use find to locate artifacts safely without triggering glob-splitting warnings
    find "${PARENT_DIR}" -maxdepth 1 -type f -name "${PACKAGE_NAME}_*.deb" -exec mv {} "${OUTPUT_DIR}/" \; 2>/dev/null || true
}

cleanup_logs() {
    log_info "Cleaning up temporary build logs..."
    find "${PARENT_DIR}" -maxdepth 1 -type f \( -name "${PACKAGE_NAME}_*.changes" -o -name "${PACKAGE_NAME}_*.buildinfo" -o -name "${PACKAGE_NAME}_*.build" \) -exec rm -f {} \; 2>/dev/null || true
}

# --- Main Pipeline Orchestration ---

main() {
    # Sequential variable setup and validation
    get_source_dir
    validate_debian_directory
    get_package_name
    get_parent_dir

    # Rest of pipeline commands...
    prepare_workspace
    clean_source_tree
    build_package
    move_build_artifacts
    cleanup_logs
    clean_source_tree

    log_info "Success! Built artifacts are in: ${OUTPUT_DIR}"
}

# Execute main pipeline
main
