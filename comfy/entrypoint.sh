#!/usr/bin/env bash
set -e

# =================================================================================================
# 🔒 SECURE ENTRYPOINT
# Implements: Secret Isolation, History Wiping, and Auto-Cleanup for Community Clouds
# =================================================================================================

# 1. Disable Bash History (Prevent leaking commands)
ln -sf /dev/null ~/.bash_history
history -c
export HISTFILE=/dev/null

# 2. Setup Cleanup Trap (Self-Destruct Mode)
cleanup() {
    echo "🛑 Container stopping..."
    if [ "$CLEAN_ON_EXIT" = "true" ]; then
        echo "🔒 SECURE MODE: Wiping sensitive data..."
        rm -rf /comfyui/output/*
        rm -rf /comfyui/models/checkpoints/*
        rm -rf /comfyui/models/loras/*
        rm -rf /comfyui/models/vae/*
        rm -rf /comfyui/models/controlnet/*
        rm -rf /comfyui/models/upscale_models/*
        rm -rf /comfyui/models/embeddings/*
        echo "✅ All models and outputs wiped."
    fi
}
trap cleanup SIGTERM SIGINT

clear
echo "🔒 Starting ComfyUI (CUDA 12.4 | SageAttn 2 | Custom Nodes)..."

# ---- HuggingFace Optimization ----
export HF_HUB_DISABLE_TELEMETRY=1
export HF_HUB_DISABLE_PROGRESS_BARS=1
export TRANSFORMERS_NO_ADVISORY_WARNINGS=1

# ---- Memory Management (Modern PyTorch) ----
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

# ---- Start Watchdog (Secure Subshell) ----
# We run watchdog in a subshell so secrets are NOT exported to the main ComfyUI process
if [ -f /watchdog.sh ]; then
  (
    # Only load secrets inside this subshell
    if [ -f /run/secrets/r2.env ]; then
      set -a
      source /run/secrets/r2.env
      set +a
      echo "🔑 Secrets loaded for Watchdog (Isolated)."
    fi
    
    # Start Watchdog
    /watchdog.sh
  ) &
  echo "🛡️ Watchdog service started (Background)."
fi

# ---- Start ComfyUI ----
# TCMalloc + High Performance Mode
echo "🚀 Booting ComfyUI..."
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libtcmalloc_minimal.so.4 \
python3 main.py \
  --listen 0.0.0.0 \
  --port 8188 \
  --fast \
  --use-pytorch-cross-attention
