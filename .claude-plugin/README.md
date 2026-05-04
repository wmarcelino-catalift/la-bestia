# .claude-plugin/

> Plugin manifest for future distribution via `claude plugin install`. Not yet published to a marketplace — this directory is preparatory.

## Files

- `plugin.json` — manifest (name, version, components, license).

## Status

`v1.1.0` ships the manifest but **does not** publish to a marketplace. To install today:

```bash
git clone https://github.com/wmarcelino-catalift/la-bestia.git
cd la-bestia
make install   # or: bash install.sh global
```

When (if) we publish to a marketplace, the install path becomes:

```bash
claude plugin install la-bestia
```

The manifest format mirrors the conventions used by other Claude Code plugins (e.g., `claude-octopus`). If Anthropic finalizes a different schema, this manifest is small enough to migrate in one PR.
