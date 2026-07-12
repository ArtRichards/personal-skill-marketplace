---
name: create-deb
description: Package scripts, applications, or services as Debian (.deb) packages. Use when the user wants to create a .deb package, make software installable system-wide, package a script for distribution, or asks to "package this as a deb". Invoke with `/create-deb [source-path]`.
---

# Create .deb Package

Package any script, application, or service as a Debian (.deb) package for easy system installation.

## Usage

Invoke with `/create-deb` followed by the source path:

```
/create-deb /path/to/source
/create-deb ./my-script.sh
/create-deb ~/projects/my-app/
```

If no path is provided, ask what to package.

## Workflow

### Step 1: Analyze Source

Examine what's being packaged:

1. Read the source files to understand what the software does
2. Identify file types and their install paths:
   - Executable scripts/binaries → `/usr/bin/` or `/usr/sbin/`
   - Libraries/modules → `/usr/lib/<package>/`
   - Configuration files → `/etc/<package>/`
   - Systemd unit files → `/lib/systemd/system/` or `/usr/lib/systemd/user/`
   - Desktop entries → `/usr/share/applications/`
   - Autostart entries → `/etc/xdg/autostart/`
   - Documentation → `/usr/share/doc/<package>/`
3. Detect dependencies (shebang lines, imports, linked libraries)
4. Check for existing package metadata (version, description)

### Step 2: Gather Package Metadata

Ask the user for required information if not already known:

**Required:**
- Package name (suggest based on source, lowercase with hyphens)
- Version (suggest 1.0.0-1 if first release)
- Maintainer name and email
- Short description (one line, max 80 chars)

**Optional (ask if relevant):**
- Long description
- Dependencies (suggest based on analysis)
- Architecture (default: `all` for scripts, detect for binaries)

### Step 3: Create Package Structure

Build directory structure using naming convention:

```bash
PKG="<package-name>_<version>_<arch>"
mkdir -p "$PKG/DEBIAN"
```

Create subdirectories based on content type:

| Content Type | Create Directory |
|--------------|-----------------|
| Scripts/binaries | `$PKG/usr/bin/` |
| System services | `$PKG/lib/systemd/system/` |
| User services | `$PKG/usr/lib/systemd/user/` |
| Config files | `$PKG/etc/<package>/` |
| Desktop entries | `$PKG/usr/share/applications/` |
| Autostart entries | `$PKG/etc/xdg/autostart/` |
| Documentation | `$PKG/usr/share/doc/<package>/` |

### Step 4: Copy and Configure Files

1. Copy source files to appropriate locations
2. Set correct permissions:
   - Executables: `755`
   - Config files: `644`
   - Maintainer scripts: `755`
3. Update any hardcoded paths to use installed locations

### Step 5: Create DEBIAN/control

```
Package: <package-name>
Version: <version>
Architecture: <arch>
Maintainer: <name> <email>
Depends: <dependencies>
Description: <short-description>
 <long-description with leading spaces>
```

See [references/control-file.md](references/control-file.md) for full field reference.

### Step 6: Create Maintainer Scripts (if needed)

**For systemd services**, create postinst:
```bash
#!/bin/bash
set -e
case "$1" in
    configure)
        systemctl daemon-reload
        systemctl enable <service>.service
        systemctl start <service>.service
        ;;
esac
exit 0
```

And postrm:
```bash
#!/bin/bash
set -e
case "$1" in
    remove|purge)
        systemctl stop <service>.service || true
        systemctl disable <service>.service || true
        systemctl daemon-reload
        ;;
esac
exit 0
```

**For config files**, create `DEBIAN/conffiles`:
```
/etc/<package>/config.conf
```

See [references/maintainer-scripts.md](references/maintainer-scripts.md) for full templates.

### Step 7: Build Package

```bash
dpkg-deb --build --root-owner-group "$PKG"
```

Verify the package:
```bash
dpkg-deb --info "$PKG.deb"
dpkg-deb --contents "$PKG.deb"
```

### Step 8: Provide Instructions

Output installation and management commands:

```bash
# Install
sudo apt install ./<package>.deb

# Check status (if service)
systemctl status <service>

# View installed files
dpkg -L <package>

# Remove
sudo apt remove <package>

# Purge (remove + delete config)
sudo apt purge <package>
```

## Package Naming Convention

```
<package-name>_<version>-<release>_<architecture>.deb
```

- `package-name`: Lowercase, alphanumeric, hyphens (e.g., `my-tool`)
- `version`: Upstream version (e.g., `1.0.0`)
- `release`: Debian revision (e.g., `1`)
- `architecture`: `all`, `amd64`, `i386`, `arm64`

Example: `screen-blank-fix_1.0.0-1_all.deb`

## Scenario-Specific Guidance

### Simple Script

For a single script with no service or config:
- Only need `DEBIAN/control` and `/usr/bin/<script>`
- Minimal dependencies (usually just `bash`)
- No maintainer scripts needed

### System Service

For a daemon that runs at boot:
- Include systemd unit file in `/lib/systemd/system/`
- Create postinst to enable/start service
- Create postrm to stop/disable service
- Consider creating dedicated user/group

### User Session Service

For a service that runs in user sessions:
- Include unit file in `/usr/lib/systemd/user/`
- Users enable with `systemctl --user enable <service>`
- May include autostart .desktop as fallback

### Desktop Application

For GUI applications:
- Include .desktop file in `/usr/share/applications/`
- For autostart, also add to `/etc/xdg/autostart/`
- May need GTK/Qt dependencies

### Application with Config

For apps with configuration files:
- Place configs in `/etc/<package>/`
- List in `DEBIAN/conffiles` to preserve on upgrade
- Scripts should reference `/etc/<package>/` paths

## Common Dependencies

| Type | Typical Dependencies |
|------|---------------------|
| Bash script | `bash` |
| Python 3 script | `python3` |
| Systemd service | `systemd` |
| DBus monitoring | `dbus-x11` |
| xrandr usage | `x11-xserver-utils` |
| GUI (GTK) | `libgtk-3-0` |
| GUI (Qt) | `libqt5widgets5` |
| Network tools | `curl`, `wget` |
| JSON processing | `jq` |

## Error Handling

If `dpkg-deb` fails:
1. Check control file has no syntax errors
2. Ensure control file ends with newline
3. Verify all maintainer scripts are executable (755)
4. Check for invalid characters in package name

If package installs but doesn't work:
1. Verify all paths are correct for installed location
2. Check dependencies are complete
3. Review `journalctl` for service failures
4. Test scripts can find their resources

See [references/common-pitfalls.md](references/common-pitfalls.md) for detailed troubleshooting.

## Reference Files

- [references/control-file.md](references/control-file.md) - Full control file field reference
- [references/maintainer-scripts.md](references/maintainer-scripts.md) - Complete postinst/postrm templates
- [references/common-pitfalls.md](references/common-pitfalls.md) - Troubleshooting guide

## Templates

Copy-paste templates in `assets/templates/`:
- `control.template`
- `postinst.template`
- `postrm.template`
