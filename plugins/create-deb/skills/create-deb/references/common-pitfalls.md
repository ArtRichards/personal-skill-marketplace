# Common Pitfalls

## dpkg-deb Build Failures

**Syntax error in control file**
- Ensure file ends with newline
- No trailing spaces
- Long description lines must start with single space

**Invalid package name**
- Must be lowercase
- Only alphanumeric and hyphens
- No underscores

**Maintainer scripts not executable**
```bash
chmod 755 DEBIAN/postinst DEBIAN/postrm
```

## Package Installs But Fails

**Missing dependencies**
- Test in minimal environment
- Check shebang: `#!/bin/bash` needs `bash` dependency
- Check imports: Python scripts need `python3`

**Hardcoded paths**
```bash
# Bad - won't work after install
CONFIG="./config.ini"
CONFIG="/home/user/myapp/config"

# Good - uses installed path
CONFIG="/etc/mypackage/config.ini"
```

**Script can't find resources**
- Update paths to reflect installed locations
- Use `/usr/share/<package>/` for data files

## Service Failures

**Service won't start**
- Run `systemctl daemon-reload` in postinst
- Check ExecStart path matches installed location
- Verify user exists if Service has User= directive
- Check `journalctl -u myservice` for errors

**Service enabled but not running after install**
- postinst must call both `enable` and `start`

## Permission Issues

**Files not executable**
```bash
chmod 755 $PKG/usr/bin/*
```

**Wrong ownership**
- Use `--root-owner-group` flag with dpkg-deb
- Files will be owned by root:root regardless of build user

## Config File Conflicts

**Upgrade overwrites user changes**
- List config files in `DEBIAN/conffiles`
- One absolute path per line
