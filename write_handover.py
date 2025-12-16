content = """# 🏁 ComfyUI Docker Image - Project Handover

## 📦 System Specification (Final Configuration)
| Component | Version | Source | Notes |
| :--- | :--- | :--- | :--- |
| **Base Image** | `nvidia/cuda:12.4.1-cudnn-devel` | Docker Hub | Ubuntu 22.04 LTS |
| **Python** | `3.11` | Apt/Pip | - |
| **PyTorch** | **2.4.0** (cu124) | PyPi | Downgraded from 2.5/2.6 to match Flash Attn wheel. |
| **Flash Attention**| **2.6.3** | Wheel | Pre-built `cu123` wheel (Compatible with Torch 2.4). |
| **SageAttention** | **2.0+** (Source) | GitHub | **Patched via `sage_patch.py`** during build. |
| **xformers** | Latest | PyPi | Additional speedup. |

## 🛡️ Security Implementation
This image is "Community Cloud Ready" (RunPod/Vast.ai) with strict credential protection:
1.  **Secret Isolation**: `entrypoint.sh` sources secrets in a subshell. Env vars like `AWS_ACCESS_KEY_ID` are **NOT** visible to ComfyUI or Custom Nodes.
2.  **Clean On Exit**: Set `CLEAN_ON_EXIT=true` to wipe `/comfyui/models` and `/comfyui/output` when the container stops.
3.  **Log Privacy**: `watchdog.sh` suppresses `stdout` for S3 syncs to hide file names/endpoints. Bash history is disabled.

## 🔧 Build & Deployment (Crucial Fixes)
### The SageAttention Fix
*   **Problem**: GitHub Actions runners have no GPU, causing `SageAttention/setup.py` to crash with `RuntimeError: No GPUs found`.
*   **Solution**: We injected a script named **`sage_patch.py`**.
*   **Mechanism**: This Python script uses Regex to rewrite `setup.py` on the fly, disabling the GPU check and forcing it to compile for **Compute Capabilities 8.0, 8.6, 8.9, 9.0** (RTX 30/40/50 Series).
*   **Constraint**: Do not remove `sage_patch.py` from the repo or the Dockerfile.

### Deployment Kit (Local Files)
Detailed guides and templates are available in your local folder (ignored by git):
*   **`deployment_guide.md`**: Step-by-step PDF-style guide.
*   **`onstart_template.sh`**: Startup script for downloading models.
*   **`vast_secrets.env`**: Template for quick environment variables.

## 🚀 Known Constraints
*   **Image Size**: Large (~10GB+) due to multiple CUDA architectures compiled in. Use `cache-from` in CI to speed up builds.
*   **First Boot**: SageAttention kernels are pre-compiled, so boot time should be fast, but first-time model loads might still take a moment.

---
**Status**: 🟢 **READY FOR PRODUCTION**
"""

with open("handover.md", "w", encoding="utf-8") as f:
    f.write(content)

print("handover.md updated successfully.")
