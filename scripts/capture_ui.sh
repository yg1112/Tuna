#!/bin/bash
# Usage: ./scripts/capture_ui.sh MainView.swift

set -euo pipefail

VIEW_FILE="$1"                       # Input SwiftUI file
OUT_DIR="docs/previews"
OUT_IMG="$OUT_DIR/$(basename "${VIEW_FILE%.*}").png"
OUT_MD="docs/ui_manifest.md"

mkdir -p "$OUT_DIR"

# Create a simple placeholder image if screenshot fails
create_placeholder_image() {
    echo "[WARNING] Unable to capture window screenshot, creating placeholder..."
    local width=400
    local height=300
    local filename="$1"
    local title="$(basename "${VIEW_FILE%.*}")"
    
    # If imagemagick is available, create text placeholder
    if command -v convert &> /dev/null; then
        convert -size ${width}x${height} xc:#27272a -fill white -gravity center \
        -pointsize 24 -annotate 0 "$title" \
        -pointsize 16 -annotate 0,30 "UI Preview Placeholder" \
        "$filename"
        echo "[SUCCESS] Created placeholder image: $filename"
        return 0
    fi
    
    # Fallback: create a simple 1x1 pixel image
    echo "[INFO] imagemagick not installed, creating basic placeholder..."
    printf "P3\n1 1\n255\n39 39 42\n" > "$filename"
    echo "[SUCCESS] Created basic placeholder: $filename"
}

### 1. Try to launch SwiftUI preview window
echo "[INFO] Attempting to launch SwiftUI preview..."
osascript <<EOF || echo "[WARNING] Unable to trigger preview via AppleScript (this is normal in some environments)"
tell application "System Events"
  keystroke "k" using {command down, shift down}
end tell
EOF

sleep 2  # Give preview 2s to render

### 2. Try to find the frontmost window ID and capture screenshot
echo "[INFO] Attempting to capture window screenshot..."
if WIN_ID=$(osascript -e 'tell application "System Events" to get id of window 1 of (process 1 where frontmost is true)' 2>/dev/null); then
    echo "[SUCCESS] Found window ID: $WIN_ID"
    if screencapture -x -l "$WIN_ID" "$OUT_IMG"; then
        echo "[SUCCESS] Screenshot captured: $OUT_IMG"
    else
        echo "[WARNING] Screenshot failed, creating placeholder"
        create_placeholder_image "$OUT_IMG"
    fi
else
    echo "[WARNING] Unable to get window ID, trying alternative method..."
    
    # Try fullscreen capture method
    if screencapture -x "$OUT_IMG"; then
        echo "[SUCCESS] Fullscreen screenshot captured: $OUT_IMG"
    else
        echo "[WARNING] Fullscreen screenshot failed, creating placeholder"
        create_placeholder_image "$OUT_IMG"
    fi
fi

### 3. Update Manifest file
echo "[INFO] Updating UI Manifest file..."

# If manifest doesn't exist in docs dir, use .UISnapshotManifest in current directory
if [ ! -f "$OUT_MD" ]; then
    if [ -f ".UISnapshotManifest" ]; then
        echo "[INFO] Using .UISnapshotManifest instead of $OUT_MD"
        OUT_MD=".UISnapshotManifest"
    else
        echo "[INFO] Creating new UI Manifest file"
        echo "### UI Snapshot Manifest" > "$OUT_MD"
        echo "" >> "$OUT_MD"
    fi
fi

# Check if component image reference already exists
COMPONENT_NAME=$(basename "${VIEW_FILE%.*}")
PATTERN="!\[.*\].*${COMPONENT_NAME}.*\.png"

if grep -q "$PATTERN" "$OUT_MD"; then
    echo "[INFO] Manifest already contains image reference for this component"
else
    echo "[INFO] Adding new image reference to Manifest"
    echo "" >> "$OUT_MD"
    echo "### ${COMPONENT_NAME}" >> "$OUT_MD"
    echo "![${COMPONENT_NAME} Preview](${OUT_IMG})" >> "$OUT_MD"
fi

echo "[SUCCESS] Complete! Image saved to $OUT_IMG, updated in $OUT_MD"
