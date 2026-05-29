# straas-tech/install

Hosts the STRAAS CLI installer at `https://straas-tech.github.io/install/cli.sh`.

## Files

| File | Purpose |
|------|---------|
| `cli.sh` | Installer script (copy of `scripts/install.sh` from main repo) |
| `index.html` | Landing page served at `https://install.straas.ai/` |

## Usage

```bash
curl -fsSL https://straas-tech.github.io/install/cli.sh | bash
```

Pin a version:

```bash
curl -fsSL https://straas-tech.github.io/install/cli.sh | bash -s -- v0.2.0
```

Custom install directory:

```bash
STRAAS_INSTALL_DIR=$HOME/bin curl -fsSL https://straas-tech.github.io/install/cli.sh | bash
```

## Updating

`cli.sh` is kept in sync with [`scripts/install.sh`](https://github.com/straas-tech/straas-workspace/blob/main/scripts/install.sh) in the main repo. When the installer changes, copy it here and push to main.

## Hosting

Deployed via Cloudflare Pages with custom domain `install.straas.ai`.
Build command: none (static files).
Output directory: `/` (repo root).
