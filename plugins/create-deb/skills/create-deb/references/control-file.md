# DEBIAN/control File Reference

## Required Fields

| Field | Description |
|-------|-------------|
| Package | Lowercase, alphanumeric, hyphens allowed |
| Version | Format: `upstream-debian_revision` (e.g., `1.0.0-1`) |
| Architecture | `all` (arch-independent), `amd64`, `i386`, `arm64` |
| Maintainer | `Name <email@example.com>` |
| Description | First line: short (max 80 chars). Following lines: long description with leading space |

## Optional Fields

| Field | Description |
|-------|-------------|
| Section | Category: `utils`, `admin`, `net`, `text`, etc. |
| Priority | `required`, `important`, `standard`, `optional` |
| Depends | Runtime dependencies |
| Recommends | Suggested packages |
| Conflicts | Incompatible packages |
| Replaces | Packages whose files this replaces |
| Provides | Virtual package names |
| Homepage | Project URL |

## Dependency Syntax

```
Depends: pkg1, pkg2 (>= 1.0), pkg3 | alternative
```

Version operators: `<<`, `<=`, `=`, `>=`, `>>`

## Example

```
Package: my-tool
Version: 1.0.0-1
Architecture: all
Maintainer: John Doe <john@example.com>
Depends: bash, curl (>= 7.0)
Section: utils
Priority: optional
Homepage: https://github.com/user/my-tool
Description: Brief one-line description
 Extended description that provides more detail.
 Each line starts with a single space.
 .
 Blank lines use a period with leading space.
```
