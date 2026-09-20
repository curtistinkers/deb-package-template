SHELL := /bin/sh
.SHELLFLAGS := -eu -c

# --- Configuration & Globals ---
INPUT ?= package
TARGET_INPUT := $(patsubst %/,%,$(INPUT))
PROJECT_ROOT := $(shell pwd)
OUTPUT_DIR := $(PROJECT_ROOT)/dist

# Dynamic metadata extraction
SOURCE_DIR := $(shell cd "$(TARGET_INPUT)" && pwd)
PARENT_DIR := $(shell dirname "$(SOURCE_DIR)")
PACKAGE_NAME := $(shell awk '/^Package:/ {print $$2; exit}' "$(SOURCE_DIR)/debian/control")

.PHONY: all prepare clean build move-artifacts cleanup-logs help

# --- Main Targets ---

all: build

help:
	@echo "Available targets:"
	@echo "  make build          - Build the Debian package (default)"
	@echo "  make clean          - Clean the source tree using debuild"
	@echo "  make purge          - Clean source tree and remove dist directory"

prepare:
	@if [ ! -d "$(TARGET_INPUT)" ]; then \
		echo "❌ Error: Directory '$(TARGET_INPUT)' does not exist." >&2; \
		exit 1; \
	fi
	@if [ ! -d "$(SOURCE_DIR)/debian" ]; then \
		echo "❌ Error: '$(SOURCE_DIR)' is not a valid Debian package directory (missing 'debian/' folder)." >&2; \
		exit 1; \
	fi
	@if [ -z "$(PACKAGE_NAME)" ]; then \
		echo "❌ Error: Could not determine Package name from '$(SOURCE_DIR)/debian/control'." >&2; \
		exit 1; \
	fi
	@echo "💡 Starting build process for package: $(PACKAGE_NAME) (Directory: $(TARGET_INPUT))"
	mkdir -p "$(OUTPUT_DIR)"
	@echo "💡 Created output directory for build artifacts: $(OUTPUT_DIR)"

clean:
	@echo "💡 Cleaning up source directory..."
	cd "$(SOURCE_DIR)" && debuild --no-tgz-check -- clean >/dev/null 2>&1 || true

purge: clean
	rm -rf "$(OUTPUT_DIR)"

move-artifacts:
	@echo "💡 Moving build artifacts for $(PACKAGE_NAME) to $(OUTPUT_DIR)..."
	find "$(PARENT_DIR)" -maxdepth 1 -type f -name "$(PACKAGE_NAME)_*.deb" -exec mv {} "$(OUTPUT_DIR)/" \; 2>/dev/null || true

cleanup-logs:
	@echo "💡 Cleaning up temporary build logs..."
	find "$(PARENT_DIR)" -maxdepth 1 -type f \( -name "$(PACKAGE_NAME)_*.changes" -o -name "$(PACKAGE_NAME)_*.buildinfo" -o -name "$(PACKAGE_NAME)_*.build" \) -exec rm -f {} \; 2>/dev/null || true

build: prepare clean
	@echo "💡 Changing to package directory: $(SOURCE_DIR)"
	cd "$(SOURCE_DIR)" && debuild -b -us -uc
	$(MAKE) move-artifacts
	$(MAKE) cleanup-logs
	$(MAKE) clean
	@echo "💡 Success! Built artifacts are in: $(OUTPUT_DIR)"
	rm -f Makefile generate.sh
