# `{{ package_name }}`

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
