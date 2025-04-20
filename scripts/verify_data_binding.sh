#!/bin/bash

# Exit on any error
set -e

echo "Running binding integrity tests..."

# Run the specific test target
swift test --filter BindingIntegrityTests

# Check exit code
if [ $? -eq 0 ]; then
    echo "✅ All binding integrity tests passed"
    exit 0
else
    echo "❌ Binding integrity tests failed"
    exit 1
fi 