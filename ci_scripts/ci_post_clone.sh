#!/bin/sh

#
# ci_post_clone.sh
#

set -e

echo "🚀 [Xcode Cloud] Downloading Qwen2.5-0.5B model from Hugging Face..."

DESTINATION_PATH="../hijaiapp/Resources/qwen2.5-0.5b-instruct-q4_k_m.gguf"

curl -L -o "$DESTINATION_PATH" \
  "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf?download=true"

echo "✅ [Xcode Cloud] Model downloaded successfully and ready to be bundled!"
