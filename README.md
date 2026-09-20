<!-- REMOVE -->
# Debian Package Template

The `generate.sh` script prompts for defined keys and applies replacements to `README.md`, `LICENSE.md`, and any files
found under `package/debian/` to simply starting a new package.

## Usage

Run the script directly without arguments:

```bash
./generate.sh
```

<!-- /REMOVE -->
# `{{ package_name }}`

{{ short_description }}

{{ long_description }}

## Build Debian Package

Build the package using the included build script or using debuild directly.

### Install build requirements

```bash
apt update && apt install devscripts
```

### Build with help script

```bash
./build.sh
```

### Build directly with debuild

```bash
cd package && debuild -us -uc -b
```
