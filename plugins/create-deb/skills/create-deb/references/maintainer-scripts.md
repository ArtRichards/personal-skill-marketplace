# Maintainer Scripts

Scripts in DEBIAN/ that run during package lifecycle. Must be executable (chmod 755).

## Execution Order

**Install:** preinst → files extracted → postinst configure
**Remove:** prerm remove → files removed → postrm remove
**Purge:** postrm purge

## postinst for Systemd Service

```bash
#!/bin/bash
set -e

case "$1" in
    configure)
        systemctl daemon-reload
        systemctl enable myservice.service
        systemctl start myservice.service
        ;;
    abort-upgrade|abort-remove|abort-deconfigure)
        ;;
    *)
        echo "postinst called with unknown argument '$1'" >&2
        exit 1
        ;;
esac

exit 0
```

## postrm for Systemd Service

```bash
#!/bin/bash
set -e

case "$1" in
    remove|purge)
        systemctl stop myservice.service || true
        systemctl disable myservice.service || true
        systemctl daemon-reload
        ;;
    upgrade|failed-upgrade|disappear)
        ;;
    abort-install|abort-upgrade)
        ;;
    *)
        echo "postrm called with unknown argument '$1'" >&2
        exit 1
        ;;
esac

exit 0
```

## conffiles

List config files to preserve on upgrade in `DEBIAN/conffiles`:

```
/etc/mypackage/config.conf
/etc/mypackage/settings.ini
```

## Common postinst Actions

```bash
# Create directory
mkdir -p /var/lib/mypackage

# Create system user
getent passwd myuser || useradd -r -s /usr/sbin/nologin myuser

# Update desktop cache
update-desktop-database /usr/share/applications || true
```

## Common postrm Actions (purge only)

```bash
# Remove data directories
rm -rf /var/lib/mypackage
rm -rf /etc/mypackage

# Remove user
userdel myuser || true
```
