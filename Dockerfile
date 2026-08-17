# syntax=docker/dockerfile:1.4
#
# Dockerfile dedicated to Quadro P2200 (Pascal / sm_61 / 5GB VRAM)
#  - CUDA 13.x has dropped Pascal support, so we use CUDA 12.6 + torch cu126
#    (the cu128/cu130 torch wheels don't include sm_6x code)
#  - sm_60 cubins are forward-compatible on sm_61, so the cu126 wheel works as-is
#
#   GID=$(id -g) docker compose up --build

FROM nvidia/cuda:12.6.3-devel-ubuntu24.04

# ── Environment variables ─────────────────────────────────────────────────────
ENV PIP_BREAK_SYSTEM_PACKAGES=1 \
    UV_BREAK_SYSTEM_PACKAGES=1 \
    FORCE_CUDA=1 \
    COMFY_SDP_FORCE=pytorch \
    COMFY_TORCH_COMPILE=0 \
    CUDA_HOME=/usr/local/cuda \
    PYTHONPATH="/app/ComfyUI/custom_nodes/comfyui_layerstyle/py:${PYTHONPATH}" \
    TORCH_CUDA_ARCH_LIST="6.1"

# ── System packages ────────────────────────────────────────────────────────
RUN --mount=type=cache,target=/var/cache/apt/archives \
    --mount=type=cache,target=/var/lib/apt/lists \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      python3 \
      python3-pip \
      python3-venv \
      python3-dev \
      build-essential \
      ninja-build \
      cmake \
      git \
      libgl1 \
      libsndfile1 \
      ffmpeg \
      espeak-ng \
      sox \
      libx11-dev && \
    ln -sf /usr/bin/python3 /usr/bin/python

# ── ComfyUI codebase ───────────────────────────────────────────────────────────
COPY ./app/ComfyUI /app/ComfyUI
WORKDIR /app/ComfyUI

# ── PyTorch (P2200 is pinned to cu126; do not upgrade to cu128/cu130 — no sm_6x support) ───
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --index-url https://download.pytorch.org/whl/cu126 \
      torch==2.7.1+cu126 torchvision==0.22.1+cu126 torchaudio==2.7.1+cu126

# ── ComfyUI requirements (torch packages are already pinned above) ──────────
RUN --mount=type=cache,target=/root/.cache/pip \
    grep -vE '^(torch|torchvision|torchaudio)([<>=!].*)?$' requirements.txt \
      > /tmp/requirements.no-torch.txt && \
    pip install -r /tmp/requirements.no-torch.txt

# ── ML / HuggingFace stack ─────────────────────────────────────────────────────
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install \
      uv \
      "numpy==1.26.4" \
      "huggingface_hub" \
      "tokenizers" \
      "transformers" \
      "diffusers" \
      "peft" \
      "safetensors>=0.4.5"

# ── Vision / Audio / misc ──────────────────────────────────────────────────────
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install \
      "pillow>=10,<12" \
      "scipy>=1.10,<2" \
      "timm==1.0.9" \
      "redis==5.0.8" \
      "plyfile==1.0.3" \
      "ftfy==6.1.3" \
      "hydra-core==1.3.2" \
      "librosa==0.10.2.post1" \
      "numba==0.59.1" \
      "faiss-cpu>=1.8,<2" \
      "GitPython>=3.1.43" \
      "boto3>=1.28,<2" \
      "scikit-image" \
      "imageio-ffmpeg" \
      "omegaconf" \
      "gguf" \
      "pyhocon" \
      "surrealist" \
      "matplotlib" \
      "requests>=2.31.0" \
      "ffmpeg-python>=0.2.0" \
      fal_client \
      qwen_tts \
      trimesh \
      replicate \
      blend_modes \
      kiui \
      wget \
      matrix-nio \
      "ninja~=1.11.1.4" \
      sentencepiece \
      protobuf \
      clip_interrogator \
      lark \
      modelscope \
      accelerate \
      datasets \
      dacite \
      "bitsandbytes>=0.47.0" \
      "conformer>=0.3.2" \
      x-transformers \
      torchdiffeq \
      ema-pytorch \
      vocos \
      "cn2an>=0.5.22" \
      "g2p-en>=2.1.0" \
      "munch>=4.0.0" \
      "json5>=0.12.0" \
      "textstat>=0.7.10" \
      punctuators \
      openai-whisper \
      "funasr>=1.1.3" \
      "nagisa>=0.2.11" \
      hyperpyyaml \
      monotonic-alignment-search \
      "praat-parselmouth>=0.4.6" \
      "pyworld>=0.3.5" \
      "torchfcpe>=0.0.4" \
      "inflect>=7.3.0" \
      pywavelets \
      open_clip_torch \
      torchmetrics \
      pytorch_msssim \
      pygltflib \
      xatlas \
      PyMCubes \
      pyvista \
      pymeshfix \
      igraph \
      torchtyping \
      jaxtyping \
      iopath \
      easydict \
      pyloudnorm \
      color-matcher \
      mss \
      addict \
      yacs \
      albumentations \
      fvcore \
      yapf \
      mediapipe \
      sounddevice \
      jieba \
      pypinyin \
      unidecode \
      opencv-python \
      pytorch-lightning \
      "onnx>=1.16.0" \
      phonemizer \
      "git+https://github.com/EasternJournalist/utils3d.git#egg=utils3d" \
      "s3tokenizer==0.3.0" \
      cached-path \
      vector-quantize-pytorch \
      torchcrepe

# ── amd64-dependent packages ──────────────────────────────────────────────────
# opencv: the contrib and headless variants must be pinned to the same version or they conflict
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install \
      "opencv-contrib-python-headless==4.10.0.84" \
      "opencv-python-headless==4.10.0.84" \
      "onnxruntime-gpu==1.20.2" \
      open3d \
      pymeshlab \
      gpytoolbox

RUN apt-get update && apt-get install -y --no-install-recommends libjemalloc2 \
    && rm -rf /var/lib/apt/lists/*

ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

# ── Entrypoint ─────────────────────────────────────────────────────────────────
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
