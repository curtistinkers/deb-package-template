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

Build the package using `make`, the included build script `build.sh`, or using debuild directly. Using `make` or
`build.sh` will output the files into `dist/` and cleanup all the extra files that debuild leaves behind.

### Install build requirements

```bash
apt update && apt install devscripts
```

### Build using `make`

```bash
make build
```

### Build using the helper script

```bash
./build.sh
```

### Build using `debuild`

```bash
cd package && debuild -us -uc -b
```
