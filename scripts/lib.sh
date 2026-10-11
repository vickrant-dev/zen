#!/usr/bin/env bash
# Shared helpers. Sourced by the other scripts.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
die() { echo "desktop: $*" >&2; exit 1; }
log() { echo "==> $*"; }
