#!/bin/bash

# Exit on any error
set -e

echo "Checking for duplicate source files..."

# Run swift package diagnose and capture output
DIAGNOSE_OUTPUT=$(swift package diagnose 2>&1)

# Check for multiple producers error
if echo "$DIAGNOSE_OUTPUT" | grep -E "multiple producers|because of multiple producers"; then
    echo "❌ Error: Duplicate source files detected"
    echo "$DIAGNOSE_OUTPUT" | grep -E "multiple producers|because of multiple producers"
    exit 1
fi

echo "✅ No duplicate source files found"
exit 0 