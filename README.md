# CALCIOS Healthcheck

Portable **Bash** scripts to check availability of CALCIOS public endpoints:

- Robinhood Chain public RPC
- StockKit API
- Morpho Blue GraphQL API
- CALCIOS website (`https://calcios.xyz`)

Part of the [CALCIOS](https://calcios.xyz/) ecosystem tooling.  
GitHub organization: [https://github.com/CALCIOS](https://github.com/CALCIOS)

## What it does

- HTTP status + latency for each endpoint
- Optional continuous loop for simple uptime monitoring
- Exit code non-zero if any critical check fails (useful in CI)
- **No credentials, no secrets, pure public endpoints**

## Requirements

- `bash` 4+
- `curl`
- Optional: `jq` (prettier JSON parsing; scripts work without it)

## Usage

```bash
cd calcios-healthcheck
chmod +x scripts/*.sh

# One-shot report
./scripts/check.sh

# Continuous every 30s
./scripts/check.sh --watch 30

# CI-friendly (exit 1 on failure)
./scripts/check.sh --strict
```

## Safety

- Read-only GET/POST against public URLs only
- No authentication headers
- Safe for public GitHub Actions and local cron

## License

MIT — see [LICENSE](LICENSE)
