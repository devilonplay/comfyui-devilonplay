FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PATH="/usr/local/cuda/bin:${PATH}"
ENV CUDA_HOME="/usr/local/cuda"

WORKDIR /comfyui

# ----------------------------------------------------------------------------
# 1. System Dependencies
# ----------------------------------------------------------------------------
RUN apt-get update && apt-get install -y \
    python3.11 python3.11-dev python3.11-venv python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    git git-lfs wget curl jq aria2 \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --fix-missing \
    libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    libtcmalloc-minimal4 \
    ninja-build \
    && ln -sf /usr/bin/python3.11 /usr/bin/python3 \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# ----------------------------------------------------------------------------
# 2. Python & PyTorch (CUDA 12.4)
# ----------------------------------------------------------------------------
# 2. Python & PyTorch (CUDA 12.4)
# ----------------------------------------------------------------------------
RUN pip3 install --upgrade pip wheel setuptools packaging ninja && \
    pip3 install torch==2.4.0 torchvision==0.19.0 torchaudio==2.4.0 \
    --index-url https://download.pytorch.org/whl/cu124

# ----------------------------------------------------------------------------
# 3. Performance Libraries ("The Speed Stack")
# ----------------------------------------------------------------------------
# xformers
RUN pip3 install xformers --index-url https://download.pytorch.org/whl/cu124

# Flash Attention 2 (Pre-built Wheel for Torch 2.4)
RUN pip3 install https://github.com/Dao-AILab/flash-attention/releases/download/v2.6.3/flash_attn-2.6.3+cu123torch2.4cxx11abiFALSE-cp311-cp311-linux_x86_64.whl

# SageAttention 2.0+ (Build from source for Max Performance)
# We set TORCH_CUDA_ARCH_LIST to force compilation for Ampere/Ada/Hopper
# This prevents it from failing on CPU-only GitHub Runners
ENV TORCH_CUDA_ARCH_LIST="8.0;8.6;8.9;9.0"
RUN pip3 install triton>=3.0.0 && \
    git clone https://github.com/thu-ml/SageAttention.git && \
    cd SageAttention && \
    sed -i 's/compute_capabilities = set()/compute_capabilities = { "8.0", "8.6", "8.9", "9.0" }/g' setup.py && \
    pip3 install . && \
    cd .. && \
    rm -rf SageAttention

# AWS CLI for Cloud Sync
RUN pip3 install awscli huggingface_hub

# ----------------------------------------------------------------------------
# 4. ComfyUI Core & Custom Nodes
# ----------------------------------------------------------------------------
# Clone Core
RUN git clone https://github.com/comfyanonymous/ComfyUI.git .

# Clone Manager
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git custom_nodes/ComfyUI-Manager

# --- PRE-INSTALLED CUSTOM NODES ---
WORKDIR /comfyui/custom_nodes

# Requested Nodes
RUN git clone https://github.com/crystian/ComfyUI-Crystools.git
RUN git clone https://github.com/kijai/ComfyUI-KJNodes.git
RUN git clone https://github.com/blepping/ComfyUI-bleh.git
RUN git clone https://github.com/talesofai/comfyui-browser.git
RUN git clone https://github.com/ciri/comfyui-model-downloader.git

# Auto-install requirements for all custom nodes
RUN for dir in *; do \
    if [ -d "$dir" ] && [ -f "$dir/requirements.txt" ]; then \
    echo "Installing reqs for $dir..."; \
    pip3 install --no-cache-dir -r "$dir/requirements.txt"; \
    fi; \
    done

# ----------------------------------------------------------------------------
# 5. External Tools (Downloaders)
# ----------------------------------------------------------------------------
WORKDIR /comfyui/tools

# HF Downloader Script
RUN git clone https://github.com/Solonce/HFDownloader.git && \
    pip3 install ./HFDownloader

# Civitai Downloader Script
RUN git clone https://github.com/ashleykleynhans/civitai-downloader.git

# ----------------------------------------------------------------------------
# 6. Final Setup
# ----------------------------------------------------------------------------
WORKDIR /comfyui
# Install ComfyUI Core Requirements
RUN pip3 install -r requirements.txt

# Copy Scripts
COPY entrypoint.sh /entrypoint.sh
COPY watchdog.sh /watchdog.sh
RUN sed -i 's/\r$//' /entrypoint.sh /watchdog.sh && \
    chmod +x /entrypoint.sh /watchdog.sh

EXPOSE 8188

ENTRYPOINT ["/entrypoint.sh"]