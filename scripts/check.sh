#!/bin/sh
# Check the kit docs. Run from the repo root. Exits non-zero on any failure.
#   1. banned-term grep (framework, vendor and platform names)
#   2. every relative .md link resolves
#   3. area files have the six headings in order
#   4. dist/ matches a fresh build
#   5. manifest template has the board bounding and closeout keys
set -u
LC_ALL=C
export LC_ALL

[ -f VERSION ] || { echo "check: run from the repo root (VERSION not found)" >&2; exit 2; }

fail=0
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/ti-check.XXXXXX") || exit 2
trap 'rm -rf "$tmpdir"' EXIT INT TERM

targets="HANDOFF.md README.md BOOTSTRAP.md CHANGELOG.md guidelines templates dist"

# 1. Banned terms. scripts/ is not scanned because it holds this list.
cat > "$tmpdir/banned" <<'EOF'
claude|anthropic|openai|codex|gemini|copilot|cursor|sonnet|opus|haiku|\.claude|SKILL\.md|settings\.json|mcp|PreToolUse|SessionStart|PreCompact|UserPromptSubmit|SendMessage|plugin|marketplace|frontmatter|github|tmux|systemd|cgroup|/proc|terraform|playwright
(^|[^-[:alnum:]])AGENTS\.md
(^|[^[:alnum:]_-])gh([^[:alnum:]_-]|$)
(^|[[:space:]`(])/ti-
(^|[^[:alnum:]_-])(aws|gcloud|azure|gitlab|bitbucket|slack|launchd|cron)([^[:alnum:]_-]|$)
plan mode
swappiness
jira
monday
EOF
if grep -rniE -f "$tmpdir/banned" $targets > "$tmpdir/hits" 2>/dev/null; then
  echo "FAIL banned terms:"
  sed 's/^/  /' "$tmpdir/hits" | cut -c1-160
  fail=1
else
  echo "ok   banned terms: none"
fi

# 2. Relative .md links resolve.
nlinks=0
: > "$tmpdir/missing"
for f in HANDOFF.md README.md BOOTSTRAP.md CHANGELOG.md guidelines/*.md; do
  dir=$(dirname "$f")
  grep -oE '\]\([^)#: ]+\.md(#[^)]*)?\)' "$f" | sed 's/^](//; s/)$//; s/#.*//' | sort -u > "$tmpdir/links"
  while IFS= read -r l; do
    nlinks=$((nlinks + 1))
    [ -e "$dir/$l" ] || echo "  $f -> $l" >> "$tmpdir/missing"
  done < "$tmpdir/links"
done
if [ -s "$tmpdir/missing" ]; then
  echo "FAIL links:"; cat "$tmpdir/missing"; fail=1
else
  echo "ok   links: $nlinks unique per-file links resolve"
fi

# 3. Area headings.
expected="Intent|Rules|Architecture|Interactions|Adapting it|Pitfalls"
nareas=0
hfail=0
for f in guidelines/[0-9][0-9]-*.md; do
  case "$f" in guidelines/00-*|guidelines/17-*) continue ;; esac
  nareas=$((nareas + 1))
  got=$(sed -n 's/^## //p' "$f" | paste -sd'|' -)
  if [ "$got" != "$expected" ]; then
    echo "FAIL headings: $f has: $got"; hfail=1; fail=1
  fi
done
[ "$hfail" -eq 0 ] && echo "ok   headings: $nareas area files have the six headings in order"

# 4. Bundle freshness.
if sh scripts/build-bundle.sh "$tmpdir/bundle.md" > /dev/null && cmp -s "$tmpdir/bundle.md" dist/ti-workspace-kit.md; then
  echo "ok   bundle: dist/ti-workspace-kit.md is current"
else
  echo "FAIL bundle: dist/ti-workspace-kit.md is missing or stale; run scripts/build-bundle.sh"
  fail=1
fi

# 5. Board bounding keys in the manifest template. The kit ships no board file,
# so the board size lint itself is generated at setup (guidelines/10).
missing_keys=""
for k in max_lines max_resolved_rows resolved_age_days archive_location; do
  grep -qE "^  $k:" templates/manifest.template.yaml || missing_keys="$missing_keys $k"
done
for k in scratch_retention_days handoff_retention_days; do
  grep -qE "^  $k:" templates/manifest.template.yaml || missing_keys="$missing_keys $k"
done
if [ -n "$missing_keys" ]; then
  echo "FAIL board keys: manifest template lacks:$missing_keys"; fail=1
else
  echo "ok   board keys: manifest template has the board bounding and closeout keys"
fi

if [ "$fail" -ne 0 ]; then echo "check: FAILED"; exit 1; fi
echo "check: all passed"
