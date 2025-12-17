# =================================================================================================
# STAGE 1: BUILDER (Heavy - Devel Image)
# =================================================================================================
FROM nvidia/cuda:12.4.1-devel-ubuntu22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PATH="/usr/local/cuda/bin:${PATH}"
ENV CUDA_HOME="/usr/local/cuda"
ENV TORCH_CUDA_ARCH_LIST="8.0;8.6;8.9;9.0"

# 1. Install Build Tools
RUN apt-get update && apt-get install -y \
    python3.11 python3.11-dev python3.11-venv python3-pip \
    git git-lfs wget curl jq aria2 cmake pkg-config ninja-build \
    && rm -rf /var/lib/apt/lists/*

# 2. Upgrade Pip & Install Build Deps
RUN pip3 install --upgrade pip wheel setuptools packaging ninja

# 3. Install PyTorch (Needed for compilation)
RUN --mount=type=cache,target=/root/.cache/pip \
    pip3 install torch==2.4.0 --index-url https://download.pytorch.org/whl/cu124

# 4. Build SageAttention Wheel
# We build it into a wheel so we can easily copy and install it in the final stage
COPY sage_patch.py /sage_patch.py
RUN --mount=type=cache,target=/root/.cache/pip \
    pip3 install triton>=3.0.0 && \
    git clone https://github.com/thu-ml/SageAttention.git && \
    cd SageAttention && \
    cp /sage_patch.py . && \
    python3 sage_patch.py && \
    # Create the wheel
    python3 setup.py bdist_wheel && \
    mkdir /build_artifacts && \
    cp dist/*.whl /build_artifacts/

# =================================================================================================
# STAGE 2: RUNTIME (Lite - Runtime Image)
# =================================================================================================
FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04 AS final

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PATH="/usr/local/cuda/bin:${PATH}"

WORKDIR /comfyui

# 1. Runtime Dependencies (No Compilers!)
RUN apt-get update && apt-get install -y \
    python3.11 python3.11-venv python3-pip \
    git git-lfs wget curl jq aria2 ffmpeg libgl1 \
    libtcmalloc-minimal4 \
    && ln -sf /usr/bin/python3.11 /usr/bin/python3 \
    && rm -rf /var/lib/apt/lists/*

# 2. Python Setup
RUN pip3 install --upgrade pip wheel setuptools packaging

# 3. Install PyTorch (Runtime)
RUN --mount=type=cache,target=/root/.cache/pip \
    pip3 install torch==2.4.0 torchvision==0.19.0 torchaudio==2.4.0 \
    --index-url https://download.pytorch.org/whl/cu124 && \
    pip3 install xformers --index-url https://download.pytorch.org/whl/cu124

# 4. Install Pre-Built Flash Attention
RUN --mount=type=cache,target=/root/.cache/pip \
    pip3 install https://github.com/Dao-AILab/flash-attention/releases/download/v2.6.3/flash_attn-2.6.3+cu123torch2.4cxx11abiFALSE-cp311-cp311-linux_x86_64.whl

# 5. Install SageAttention (From Builder)
COPY --from=builder /build_artifacts/ /tmp/sage_wheels/
RUN pip3 install /tmp/sage_wheels/*.whl && rm -rf /tmp/sage_wheels

# 6. AWS CLI
RUN --mount=type=cache,target=/root/.cache/pip \
    pip3 install awscli huggingface_hub

# 7. ComfyUI Core
RUN git clone https://github.com/comfyanonymous/ComfyUI.git . && \
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git custom_nodes/ComfyUI-Manager

# 8. Custom Nodes
WORKDIR /comfyui/custom_nodes
RUN git clone https://github.com/crystian/ComfyUI-Crystools.git && \
    git clone https://github.com/kijai/ComfyUI-KJNodes.git && \
    git clone https://github.com/blepping/ComfyUI-bleh.git && \
    git clone https://github.com/talesofai/comfyui-browser.git && \
    git clone https://github.com/ciri/comfyui-model-downloader.git

# Install Custom Node Requirements
RUN for dir in *; do \
    if [ -d "$dir" ] && [ -f "$dir/requirements.txt" ]; then \
    echo "Installing reqs for $dir..."; \
    pip3 install --no-cache-dir -r "$dir/requirements.txt"; \
    fi; \
    done

# 9. Tools
WORKDIR /comfyui/tools
RUN git clone https://github.com/Solonce/HFDownloader.git && \
    pip3 install ./HFDownloader && \
    git clone https://github.com/ashleykleynhans/civitai-downloader.git

# 10. Final Setup
WORKDIR /comfyui
COPY requirements.txt .
RUN pip3 install -r requirements.txt

# Performance Vars
ENV PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

COPY entrypoint.sh /entrypoint.sh
COPY watchdog.sh /watchdog.sh
RUN sed -i 's/\r$//' /entrypoint.sh /watchdog.sh && \
    chmod +x /entrypoint.sh /watchdog.sh

EXPOSE 8188
ENTRYPOINT ["/entrypoint.sh"]
