#!/usr/bin/env bash
set -euo pipefail

# Download the latest Omarchy ISO to ~/Downloads/ with SHA256 verification.
# Prints the path to the ISO file on stdout.
#
# Supports OMARCHY_ISO_URL env var to override the URL.
# Uses curl -C - to resume partial downloads.

for cmd in curl gh jq; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: $cmd is required but not found." >&2
        exit 1
    fi
done

# Determine ISO URL and SHA256
if [[ -n "${OMARCHY_ISO_URL:-}" ]]; then
    iso_url="$OMARCHY_ISO_URL"
    expected_sha256=""
    echo "==> Using ISO URL from OMARCHY_ISO_URL: $iso_url" >&2
else
    echo "==> Finding latest Omarchy release with an ISO..." >&2
    release_json=$(gh api repos/basecamp/omarchy/releases --paginate -q '
        [.[] | select(.body | test("iso\\.omarchy\\.org"))] | first
    ')
    if [[ -z "$release_json" || "$release_json" == "null" ]]; then
        echo "Error: No release with an ISO link found." >&2
        exit 1
    fi
    version=$(echo "$release_json" | jq -r '.tag_name')
    body=$(echo "$release_json" | jq -r '.body')
    iso_url=$(echo "$body" | grep -oP 'https://iso\.omarchy\.org/\S+\.iso' | head -1)
    if [[ -z "$iso_url" ]]; then
        echo "Error: Could not extract ISO URL from release $version." >&2
        exit 1
    fi
    expected_sha256=$(echo "$body" | grep -ioP '(?<=SHA256:\s)[0-9a-f]{64}' | head -1 || true)
    echo "    Found $version: $iso_url" >&2
fi

# Download
iso_filename=$(basename "$iso_url")
iso_file="$HOME/Downloads/$iso_filename"
if [[ -f "$iso_file" ]]; then
    echo "==> ISO already downloaded: $iso_file" >&2
    echo "    Attempting to resume/verify..." >&2
fi
curl -L -C - -o "$iso_file" "$iso_url" >&2

# Verify SHA256
if [[ -n "${expected_sha256:-}" ]]; then
    echo "==> Verifying SHA256..." >&2
    actual_sha256=$(sha256sum "$iso_file" | awk '{print $1}')
    if [[ "$actual_sha256" != "$expected_sha256" ]]; then
        echo "Error: SHA256 mismatch!" >&2
        echo "  Expected: $expected_sha256" >&2
        echo "  Actual:   $actual_sha256" >&2
        exit 1
    fi
    echo "    SHA256 OK: $expected_sha256" >&2
else
    echo "==> Skipping SHA256 verification (no hash available)" >&2
fi

echo "$iso_file"
