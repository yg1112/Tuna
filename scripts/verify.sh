#!/usr/bin/env bash
set -e
swift build
CI=true swift test --parallel
grep -R "no 'async' operations occur within 'await'" Sources && exit 1 || true 