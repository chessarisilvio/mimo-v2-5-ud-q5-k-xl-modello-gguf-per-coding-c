#!/usr/bin/env bash
# Manual test script for MiMo-V2.5-UD-Q5_K_XL model coding C++ capabilities
# Usage: ./test-coding-manuale.sh [prompt_number] [optional: custom_prompt]

set -euo pipefail

# Configuration - these should be set via environment variables or .env file
MODEL_PATH="${MODEL_PATH:-./MiMo-V2.5-UD-Q5_K_XL.gguf}"
LLAMA_CPP_PATH="${LLAMA_CPP_PATH:-./llama.cpp}"
N_GPU_LAYERS="${N_GPU_LAYERS:-35}"  # Adjust based on VRAM split
CTX_SIZE="${CTX_SIZE:-4096}"
BATCH_SIZE="${BATCH_SIZE:-512}"

# Default prompts file
PROMPTS_FILE="test-prompts-cpp.md"

# Function to display usage
usage() {
    echo "Usage: $0 [prompt_number] [optional: custom_prompt]"
    echo "  prompt_number: Number of the prompt to test (1-10) from $PROMPTS_FILE"
    echo "  custom_prompt: If provided, use this custom prompt instead"
    echo ""
    echo "Environment variables:"
    echo "  MODEL_PATH: Path to the GGUF model file (default: ./MiMo-V2.5-UD-Q5_K_XL.gguf)"
    echo "  LLAMA_CPP_PATH: Path to llama.cpp directory (default: ./llama.cpp)"
    echo "  N_GPU_LAYERS: Number of layers to offload to GPU (default: 35)"
    echo "  CTX_SIZE: Context size (default: 4096)"
    echo "  BATCH_SIZE: Batch size for prompt processing (default: 512)"
    exit 1
}

# Function to extract a specific prompt from the prompts file
get_prompt() {
    local prompt_num="$1"
    local file="$2"

    if [[ ! -f "$file" ]]; then
        echo "Error: Prompts file '$file' not found"
        exit 1
    fi

    # Extract the prompt content based on numbering
    # Format: "## Prompt X: Description" followed by the prompt content
    awk -v num="$prompt_num" '
        BEGIN { found=0; capture=0 }
        /^## Prompt [0-9]+:/ {
            if ($3 == num ":") {
                found=1
                capture=1
                next
            }
            if (found) {
                exit
            }
        }
        /^## Prompt [0-9]+:/ && !found { next }
        found && capture && /^$/ { exit }
        found && capture { print }
    ' "$file"
}

# Function to run llama.cpp inference
run_inference() {
    local prompt="$1"

    echo "Running inference with:"
    echo "  Model: $MODEL_PATH"
    echo "  Prompt: $prompt"
    echo "  GPU Layers: $N_GPU_LAYERS"
    echo "  Context Size: $CTX_SIZE"
    echo "  Batch Size: $BATCH_SIZE"
    echo ""

    # Check if llama.cpp exists
    if [[ ! -d "$LLAMA_CPP_PATH" ]]; then
        echo "Error: llama.cpp directory not found at $LLAMA_CPP_PATH"
        echo "Please build llama.cpp first or set LLAMA_CPP_PATH correctly"
        exit 1
    fi

    # Check if model exists
    if [[ ! -f "$MODEL_PATH" ]]; then
        echo "Error: Model file not found at $MODEL_PATH"
        echo "Please download the model first or set MODEL_PATH correctly"
        exit 1
    fi

    # Run llama.cpp
    "$LLAMA_CPP_PATH/main" \
        -m "$MODEL_PATH" \
        -p "$prompt" \
        -n 512 \
        -c "$CTX_SIZE" \
        -b "$BATCH_SIZE" \
        -ngl "$N_GPU_LAYERS" \
        --temp 0.7 \
        --top_p 0.9 \
        --repeat_penalty 1.1
}

# Main script logic
if [[ $# -eq 0 ]]; then
    usage
fi

if [[ "$1" =~ ^[0-9]+$ ]] && [[ "$1" -ge 1 ]] && [[ "$1" -le 10 ]]; then
    PROMPT_NUM="$1"
    shift
else
    # If first argument is not a number 1-10, treat as custom prompt
    PROMPT_NUM=""
fi

if [[ $# -gt 0 ]]; then
    # Custom prompt provided
    PROMPT="$*"
else
    # Get prompt from file
    if [[ -n "$PROMPT_NUM" ]]; then
        PROMPT=$(get_prompt "$PROMPT_NUM" "$PROMPTS_FILE")
        if [[ -z "$PROMPT" ]]; then
            echo "Error: Could not extract prompt $PROMPT_NUM from $PROMPTS_FILE"
            exit 1
        fi
    else
        # No prompt number and no custom prompt - show usage
        usage
    fi
fi

echo "Testing prompt:"
echo "================"
echo "$PROMPT"
echo "================"
echo ""

run_inference "$PROMPT"