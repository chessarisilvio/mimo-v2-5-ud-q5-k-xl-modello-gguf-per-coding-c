#!/usr/bin/env bash
# Script to download MiMo-V2.5-UD-Q5_K_XL GGUF model parts and verify SHA256 checksums.
# Uses environment variable MODEL_DIR for target directory, with fallback to /opt/modelli-ai/ or ~/modelli-ai/.

set -euo pipefail

# Base URL for the model files on Hugging Face (unsloth repo)
BASE_URL="https://huggingface.co/unsloth/MiMo-V2.5-GGUF/resolve/main"

# Determine target directory
if [[ -n "${MODEL_DIR:-}" ]]; then
    TARGET_DIR="$MODEL_DIR"
else
    # Try /opt/modelli-ai/ first, then fallback to ~/modelli-ai/
    if [[ -w "/opt/modelli-ai" ]] || sudo -n true 2>/dev/null; then
        # Check if we can write to /opt/modelli-ai (or we can create it with sudo)
        if [[ -d "/opt/modelli-ai" ]] || sudo mkdir -p /opt/modelli-ai 2>/dev/null; then
            TARGET_DIR="/opt/modelli-ai"
        else
            TARGET_DIR="$HOME/modelli-ai"
        fi
    else
        TARGET_DIR="$HOME/modelli-ai"
    fi
fi

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"

# Change to target directory
cd "$TARGET_DIR"

# Expected checksums file (relative to script location)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CHECKSUMS_FILE="$SCRIPT_DIR/checksums.txt"

if [[ ! -f "$CHECKSUMS_FILE" ]]; then
    echo "Error: Checksums file not found at $CHECKSUMS_FILE"
    exit 1
fi

# Read checksums file and process each line
while IFS= read -r line; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^# ]] && continue

    # Expected format: <hash>  <filename>
    expected_hash=$(echo "$line" | awk '{print $1}')
    filename=$(echo "$line" | awk '{print $2}')

    # If file exists, verify its hash
    if [[ -f "$filename" ]]; then
        computed_hash=$(sha256sum "$filename" | awk '{print $1}')
        if [[ "$computed_hash" == "$expected_hash" ]]; then
            echo "✓ $filename already verified"
            continue
        else
            echo "✗ $filename exists but hash mismatch. Re-downloading..."
            rm -f "$filename"
        fi
    fi

    # Download the file
    url="${BASE_URL}/${filename}"
    echo "Downloading $filename..."
    if ! curl -L -o "$filename.part" "$url"; then
        echo "Error: Failed to download $filename"
        exit 1
    fi

    # Verify the downloaded part
    computed_hash=$(sha256sum "$filename.part" | awk '{print $1}')
    if [[ "$computed_hash" != "$expected_hash" ]]; then
        echo "Error: Hash mismatch for $filename"
        echo "Expected: $expected_hash"
        echo "Got:      $computed_hash"
        rm -f "$filename.part"
        exit 1
    fi

    # Move the part file to the final name
    mv "$filename.part" "$filename"
    echo "✓ $filename downloaded and verified"
done < "$CHECKSUMS_FILE"

echo "All files downloaded and verified successfully in $TARGET_DIR"