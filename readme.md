# 🚀 ComfyUI Modern (CUDA 12.4 + SageAttention 2)

**The ultimate high-performance ComfyUI container for cloud GPUs.**

**Docker Pull:** `docker pull devilonplay/comfyui-devilonplay:latest`
**Maintainer:** @devilonplay
**Architecture:** NVIDIA CUDA 12.4 | Python 3.11 | PyTorch 2.4.0 (FlashAttn Pinned)

This image is engineered for maximum speed on **NVIDIA Blackwell (RTX 50-series)**, **Ada Lovelace (RTX 40‑series)**, and **Hopper (H100)** GPUs, while maintaining compatibility with **Ampere (RTX 30‑series / A100)**.

---

## ⚡ GPU Compatibility & Performance

| GPU Tier     | Supported Models                | Performance Status                       |
| ------------ | ------------------------------- | ---------------------------------------- |
| 🏆 Ultimate  | RTX 5090, H100, RTX 4090, L40S, A6000 Ada | SageAttention 2 Enabled (Max Throughput) |
| 🚀 High Perf | A100, RTX 3090 / 3090 Ti, A6000 | Flash Attention 2 Enabled                |
| ✅ Compatible | RTX 5080/5070, RTX 4080, RTX 4070, A5000, A40  | Excellent Standard Performance           |
| ⚠️ Legacy    | V100, T4, RTX 2080, P100        | Functional, limited acceleration         |

---

## 🔥 Key Features

### 1. High‑Performance Speed Stack

| Component        | Details                                           |
| ---------------- | ------------------------------------------------- |
| CUDA             | NVIDIA CUDA 12.4                                  |
| PyTorch          | 2.4.0 (Python 3.11)                               |
| Attention        | SageAttention 2.1 + Flash Attention 2             |
| Memory Allocator | TCMalloc (prevents fragmentation)                 |
| GPU Memory       | expandable_segments:True (OOM-safe for 24GB GPUs) |

### 2. Universal Cloud Watchdog (Auto‑Sync)

A background service continuously monitors `/comfyui/output` and uploads files automatically.

| Feature       | Description                                        |
| ------------- | -------------------------------------------------- |
| Providers     | Cloudflare R2, AWS S3, Wasabi, DigitalOcean, MinIO |
| Configuration | Environment variables only (no code edits)         |
| Disk Handling | Deletes local files after successful upload        |
| Security      | Endpoints & filenames hidden in logs               |
| Use Case      | Ideal for ephemeral cloud GPUs                     |

### 3. Pre‑Installed Custom Nodes

| Category    | Nodes Included                |
| ----------- | ----------------------------- |
| Core        | ComfyUI‑Manager               |
| Monitoring  | ComfyUI‑Crystools             |
| Utilities   | ComfyUI‑KJNodes, ComfyUI‑Bleh |
| File Access | ComfyUI‑Browser               |
| Models      | ComfyUI‑Model‑Downloader      |

### 4. Pre‑Installed CLI Tools

| Tool               | Purpose                      |
| ------------------ | ---------------------------- |
| aria2c             | Multi‑threaded downloads     |
| ffmpeg             | Video & animation processing |
| git‑lfs            | Large model repositories     |
| hf‑downloader      | Hugging Face model fetch     |
| civitai‑downloader | Civitai model fetch          |

---

## 🛠️ Deployment Guide

### Option A — RunPod (Recommended)

| Setting        | Value                                  |
| -------------- | -------------------------------------- |
| GPU            | RTX 4090 / A100                        |
| Image          | devilonplay/comfyui-devilonplay:latest |
| Container Disk | ≥ 20 GB                                |
| Network Volume | ≥ 50 GB                                |
| Mount Path     | /comfyui                               |
| Port           | 8188 (HTTP)                            |
| Persistence    | Models + custom_nodes retained         |

### Option B — Vast.ai

| Setting         | Value                                  |
| --------------- | -------------------------------------- |
| Docker Image    | devilonplay/comfyui-devilonplay:latest |
| Launch Mode     | Interactive (SSH)                      |
| Disk Space      | ≥ 40 GB                                |
| On‑Start Script | Unified provisioning script            |
| Persistence     | /workspace linked automatically        |

---|---|
| Image | devilonplay/comfyui-devilonplay:latest |
| GPU | RTX 4090 / A100 |
| Container Disk | ≥ 20 GB |
| Volume Disk | ≥ 50 GB |
| Volume Mount | /comfyui |
| Exposed Port | 8188 |

### Option B — Vast.ai

| Setting         | Value                                  |
| --------------- | -------------------------------------- |
| Docker Image    | devilonplay/comfyui-devilonplay:latest |
| Launch Mode     | Interactive (SSH)                      |
| Disk Space      | ≥ 40 GB                                |
| On‑Start Script | Paste unified provisioning script      |

---

## 🔑 Environment Variables (Set at Launch)

### 1️⃣ Cloud Storage (Auto‑Sync Output)

#### Mode A — Cloudflare R2

| Variable              | Example Value      |
| --------------------- | ------------------ |
| AWS_ACCESS_KEY_ID     | 76e65123f185489889 |
| AWS_SECRET_ACCESS_KEY | 48988976e65123f185 |
| R2_BUCKET             | my-comfy-images    |
| R2_ACCOUNT_ID         | 8d26f0c353023e105f |

#### Mode B — AWS S3

| Variable              | Example Value                  |
| --------------------- | ------------------------------ |
| AWS_ACCESS_KEY_ID     | AKIAIOSFODNN7EXAMPLE           |
| AWS_SECRET_ACCESS_KEY | wJalrXUtnFEMI/K7MDENG/bPxRfiCY |
| R2_BUCKET             | my-aws-bucket                  |
| AWS_DEFAULT_REGION    | us-east-1                      |

#### Mode C — Custom S3 (Wasabi / DigitalOcean / MinIO)

| Variable              | Example Value                                                                  |
| --------------------- | ------------------------------------------------------------------------------ |
| AWS_ACCESS_KEY_ID     | ACCESS_KEY                                                                     |
| AWS_SECRET_ACCESS_KEY | SECRET_KEY                                                                     |
| R2_BUCKET             | my-bucket                                                                      |
| S3_ENDPOINT_URL       | [https://s3.us-central-1.wasabisys.com](https://s3.us-central-1.wasabisys.com) |

---

### 2️⃣ Model Authentication (Optional)

| Variable      | Description             | Example          |
| ------------- | ----------------------- | ---------------- |
| HF_TOKEN      | Hugging Face Read Token | hf_AbCdEf123456  |
| CIVITAI_TOKEN | Civitai API Key         | civitai_1234abcd |

---

## 📂 Important Paths

| Type         | Path                           |
| ------------ | ------------------------------ |
| Checkpoints  | /comfyui/models/checkpoints    |
| LoRAs        | /comfyui/models/loras          |
| VAE          | /comfyui/models/vae            |
| ControlNet   | /comfyui/models/controlnet     |
| Upscalers    | /comfyui/models/upscale_models |
| Embeddings   | /comfyui/models/embeddings     |
| Outputs      | /comfyui/output                |
| Custom Nodes | /comfyui/custom_nodes          |
| Tools        | /comfyui/tools                 |

---|---|
| Checkpoints | /comfyui/models/checkpoints |
| LoRAs | /comfyui/models/loras |
| VAE | /comfyui/models/vae |
| ControlNet | /comfyui/models/controlnet |
| Output | /comfyui/output |

---

## 📥 Manual Download Examples

| Task           | Command                                                                                       |
| -------------- | --------------------------------------------------------------------------------------------- |
| Juggernaut XL  | `wget -O juggernautXL.safetensors https://civitai.com/api/download/models/357609`             |
| Pony V6 (Fast) | `aria2c -x16 -s16 -o pony_v6.safetensors https://civitai.com/api/download/models/290640`      |
| SDXL VAE       | `wget https://huggingface.co/madebyollin/sdxl-vae-fp16-fix/resolve/main/sdxl_vae.safetensors` |
| ControlNet     | `wget <url> -P /comfyui/models/controlnet`                                                    |
| LoRA           | `wget <url> -P /comfyui/models/loras`                                                         |

---

## 🧠 Unified On‑Start Provisioning (Concept)

This container supports a single startup script that:
• Links persistent volumes
• Downloads checkpoints, VAEs, LoRAs
• Uses HF_TOKEN / CIVITAI_TOKEN automatically
• Works on RunPod & Vast.ai

(Recommended for all ephemeral GPU providers)

---

## 🎯 Intended Use Cases

• Long‑running ComfyUI sessions
• Flux / SDXL / SD3 pipelines
• Cloud GPU rentals
• Auto‑synced outputs + persistent models

---

**Maintained by @devilonplay — production‑grade ComfyUI for 2025 cloud GPUs.**

## 🧪 Model & Workflow Compatibility Matrix

| Category         | Supported                           |
| ---------------- | ----------------------------------- |
| Stable Diffusion | SD 1.5, SDXL, SDXL Turbo            |
| Flux             | FLUX.1 Schnell, Dev, Tools          |
| SD3              | SD3 Medium / Large                  |
| Video            | AnimateDiff, VideoHelper nodes      |
| Control          | ControlNet, IP-Adapter, T2I-Adapter |
| Precision        | FP16, BF16, FP8 (Ada/Hopper)        |

---

## 🧠 GPU Architecture Tuning

| Architecture | GPUs           | Optimization                |
| ------------ | -------------- | --------------------------- |
| Blackwell    | RTX 5090       | SageAttention 2 + FP8       |
| Hopper       | H100           | SageAttention 2 + FP8       |
| Ada Lovelace | RTX 4090, L40S | SageAttention 2 (Max Speed) |
| Ampere       | A100, RTX 3090 | Flash Attention 2           |
| Pre-Ampere   | V100, T4       | Standard PyTorch Attention  |

---

## ⏱️ Cold Start vs Warm Start

| Scenario          | Behavior                              |
| ----------------- | ------------------------------------- |
| Cold Start        | Container boot + model load (2–5 min) |
| Warm Start        | Instant UI, cached models             |
| Restart           | Models persist via volume             |
| Spot Interruption | Safe if output already synced         |

---

## 🔐 Security & Best Practices

• Use **read-only tokens** for HF & Civitai
• Do not bake secrets into images
• Prefer bucket-level IAM over full account keys
• Outputs are deleted locally after upload (watchdog)
• **Secure Mode**: Set `CLEAN_ON_EXIT=true` to wipe all models and outputs when the container stops.
• **Secret Isolation**: AWS/R2 keys are isolated to the watchdog process and NOT visible to ComfyUI nodes.
• **No History**: Bash history is disabled and wiped to prevent leaking commands.

---

## 🧯 Troubleshooting (Quick)

| Issue              | Fix                             |
| ------------------ | ------------------------------- |
| OOM on 24GB GPU    | Reduce batch / enable tiled VAE |
| Models missing     | Check volume mount path         |
| Slow downloads     | Use aria2c                      |
| Output not syncing | Verify bucket vars              |

---

## 🏁 Final Notes

This image is designed for **serious ComfyUI users** running on **ephemeral cloud GPUs** who require:
• Maximum throughput
• Persistent models
• Automatic output safety
• Minimal manual setup

**Maintained by @devilonplay — production-ready ComfyUI for 2025 cloud GPUs.**
