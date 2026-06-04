Scan project dependencies for known vulnerabilities using OSV Scanner.

Queries the Google Open Source Vulnerability (OSV) database against every dependency manifest found in scope. Covers Go, npm, PyPI, Cargo, Maven, RubyGems, NuGet, PHP Composer, and more. Complements `/ds-security-review` (code logic) — this audits what your dependencies brought in, not what you wrote.

If `osv-scanner` is not installed, show installation instructions and stop.

## Arguments

- No args: scan the current directory recursively.
- `<path>`: scan a specific directory or lockfile.
- `--fix`: after reporting, attempt to bump vulnerable direct dependencies to the minimum fixed version in the manifest file. Transitive-only findings are reported but not auto-fixed — they require the intermediate package to release a patch.

## Process

1. Check for `osv-scanner` binary. If missing:
   ```
   Install osv-scanner:
     macOS:  brew install osv-scanner
     Go:     go install github.com/google/osv-scanner/cmd/osv-scanner@latest
     Other:  https://github.com/google/osv-scanner/releases
   ```
   Stop here. Do not proceed without the binary.

2. Run the scan:
   ```bash
   osv-scanner --recursive --format json <path-or-.>
   ```

3. Parse JSON output. Group findings:
   - **CRITICAL / HIGH** — report first, always actionable
   - **MEDIUM** — report with context
   - **LOW / informational** — summarize count only unless `--verbose`

4. For each finding report:
   - Package name + current version
   - Vulnerability ID (OSV ID and CVE alias if present)
   - Severity + CVSS score if available
   - **Fixed version** (the minimum version that resolves it)
   - Whether it's a direct or transitive dependency
   - One-line description of the vulnerability class

5. With `--fix`: for direct dependencies where a fixed version exists, bump the version in the manifest (`package.json`, `go.mod`, `Cargo.toml`, `requirements.txt`, etc.). After each bump, note the change. Do not modify lockfiles — instruct the user to run the package manager's install/update command to regenerate them.

## Output

```
OSV scan: <N> vulnerabilities found (<C> critical, <H> high, <M> medium, <L> low)

CRITICAL / HIGH
  <package>@<version>  <OSV-ID> / <CVE>
  Severity: <score>  Fixed: <version>  Dependency: direct|transitive
  <one-line class: e.g. "arbitrary code execution via malformed input">

MEDIUM
  <package>@<version>  <OSV-ID>
  ...

LOW/INFO: <N> findings — run with --verbose to expand.

Next steps:
  <package manager command to update lockfile after --fix>
  Re-run /ds-osv to confirm findings resolved.
```

If zero findings: report clean with ecosystem coverage summary (which manifests were scanned).

## Rules

- Never modify lockfiles directly. Only manifest files (`go.mod`, `package.json` `dependencies`/`devDependencies`, `Cargo.toml`, `requirements.txt`).
- Do not bump a version beyond the stated minimum fixed version — pick the minimum that resolves the CVE.
- If a finding has no fixed version available, report it clearly and suggest tracking the upstream issue.
- Transitive-only findings with no direct-dependency path to a fix should be flagged for the user to escalate to the upstream package.
