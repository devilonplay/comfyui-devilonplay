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

# 1.1 Ensure SSH directories exist (for SSH Launch Mode)
mkdir -p /var/run/sshd
mkdir -p /root/.ssh
chmod 700 /root/.ssh

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
echo "🔒 Starting ComfyUI (CUDA 12.8 | SageAttn 2.2 | Custom Nodes)..."

# ---- HuggingFace Optimization ----
export HF_HUB_DISABLE_TELEMETRY=1
export HF_HUB_DISABLE_PROGRESS_BARS=1
export TRANSFORMERS_NO_ADVISORY_WARNINGS=1

# ---- Memory Management (Modern PyTorch) ----
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

# ---- Vast.ai On-Start Script Support ----
if [ -f "/root/onstart.sh" ]; then
    echo "📜 Found Vast.ai On-Start Script. Executing..."
    chmod +x /root/onstart.sh
    /root/onstart.sh
    echo "✅ On-Start Script finished."
fi

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

# ---- Smart SageAttention Dispatcher ----
# Automatically selects or forces the best wheel for the GPU architecture
if [ "$USE_SAGE" = "1" ] && [ -d "/opt/sage_wheels" ]; then
    echo "🎯 SageAttention: Enabled."
    
    if [ -n "$FORCE_GPU" ]; then
        echo "🛡️  FORCED GPU: $FORCE_GPU"
        case $FORCE_GPU in
            "5090"|"120"|"Blackwell") SM_VER="120" ;;
            "4090"|"89"|"Ada")       SM_VER="89" ;;
            "3090"|"86"|"Ampere")    SM_VER="86" ;;
            "A100"|"80")             SM_VER="80" ;;
            "H100"|"90")             SM_VER="90" ;;
            *) echo "⚠️  Unknown FORCE_GPU value. Falling back to auto-detection."; SM_VER="" ;;
        esac
    fi

    if [ -z "$SM_VER" ]; then
        echo "🔍 Detecting GPU Architecture..."
        SM_VER=$(python3 -c "import torch; major, minor = torch.cuda.get_device_capability(); print(f'{major}{minor}')" 2>/dev/null || echo "80")
    fi

    echo "🏎️  Targeting SM $SM_VER. Selecting optimal SageAttention wheel..."

    case $SM_VER in
        "120"|"100") WHEEL_TAG="sm120" ;;
        "90")         WHEEL_TAG="sm90"  ;;
        "89")         WHEEL_TAG="sm89"  ;;
        "86")         WHEEL_TAG="sm86"  ;;
        *)            WHEEL_TAG="sm80"  ;;
    esac

    echo "📦 Installing SageAttention ($WHEEL_TAG)..."
    pip install --no-cache-dir /opt/sage_wheels/sageattention-*${WHEEL_TAG}*.whl
else
    echo "💤 SageAttention: Disabled."
fi

# ---- ComfyUI Argument Builder ----
COMFY_ARGS="--listen 0.0.0.0 --port 8188 --fast"

if [ "$USE_XFORMERS" = "1" ]; then
    echo "🧩 xformers: Enabled."
    COMFY_ARGS="$COMFY_ARGS --use-xformers"
else
    echo "🧩 xformers: Disabled."
fi

if [ "$USE_FLASH" = "1" ]; then
    echo "⚡ Flash Attention: Enabled."
    COMFY_ARGS="$COMFY_ARGS --use-pytorch-cross-attention"
else
    echo "⚡ Flash Attention: Disabled."
fi

# ---- Start ComfyUI ----
# TCMalloc + High Performance Mode
# ---- Start ComfyUI (Always Run in Background) ----
echo "🚀 Booting ComfyUI (Background Mode for Jupyter Compatibility)..."

# Use nohup to ensure it survives the exec transition
# Removed LD_PRELOAD/TCMalloc as it was causing crashes in some environments
nohup python3 main.py $COMFY_ARGS > /comfyui.log 2>&1 &

COMFY_PID=$!
echo "✅ ComfyUI started with PID $COMFY_PID"

# ---- Handle Passed Command or Wait ----
# If arguments are provided (e.g., from Vast.ai Jupyter mode), run them as the primary process.
if [ $# -gt 0 ]; then
    echo "📜 Executing passed command: $@"
    exec "$@"
else
    # Default: Wait for ComfyUI to finish (Keep container alive)
    echo "📡 No command passed. Monitoring ComfyUI..."
    wait $COMFY_PID
fi
