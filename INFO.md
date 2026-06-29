# MiMo-V2.5-UD-Q5_K_XL Model Information

## Model Overview
- Model Name: MiMo-V2.5-UD-Q5_K_XL
- Type: GGUF (for llama.cpp)
- Architecture: Sparse Mixture-of-Experts (MoE)
- Total Parameters: 310B
- Active Parameters: 15B
- Training Data: 48T tokens
- Architecture Details:
    - Language backbone: MiMo-V2-Flash (hybrid sliding-window attention)
    - Additional encoders: Visual and audio encoders (pretrained in-house)
    - Connection: Lightweight projectors

## Availability
- Hugging Face Repositories:
    - bartowski/MiMo-V2.5-GGUF
    - unsloth/MiMo-V2.5-GGUF

## Quantization
- Format: GGUF
- Quantization: Q5_K_XL (as per the model name)
- Expected VRAM usage: To be tested on P40 (24GB) + RTX 3050 (8GB) = 30GB total.

## Intended Use
- Coding tasks (specifically C++ code generation as per initial testing)
- General language understanding and generation

## Notes
- This model is a candidate for testing on the local stack (P40+3050) for coding tasks.
- The UD in the model name likely stands for "Unquantized Dynamics" or similar, but the exact meaning is not specified in the sources.