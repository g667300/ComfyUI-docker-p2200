# ComfyUI Docker — Quadro P2200

A Docker Compose setup for running [ComfyUI](https://github.com/comfyanonymous/ComfyUI) on an
NVIDIA **Quadro P2200** (Pascal architecture, `sm_61`, 5 GB VRAM).

## Why a dedicated setup

Pascal-generation GPUs (`sm_6x`) are no longer supported by the CUDA 13 toolchain, and the
PyTorch wheels built against CUDA 12.8/13.0 no longer ship `sm_6x` kernels. This image therefore
pins everything to **CUDA 12.6** and **PyTorch 2.7.1+cu126**, which still includes `sm_60`
kernels that run on `sm_61` via forward compatibility.

Key points:

- Base image: `nvidia/cuda:12.6.3-devel-ubuntu24.04`
- PyTorch: `2.7.1+cu126` / torchvision `0.22.1+cu126` / torchaudio `2.7.1+cu126`
- `TORCH_CUDA_ARCH_LIST=6.1` — do **not** upgrade to cu128/cu130, they drop `sm_6x` support
- ComfyUI is started with `--lowvram` to fit within the P2200's 5 GB VRAM

## Requirements

- Docker with the NVIDIA Container Toolkit (`nvidia-docker2`)
- `docker compose` v2
- Git

## Usage

### 1. Build

```bash
./build.sh
```

This clones (or updates) ComfyUI into `./app/ComfyUI` and then builds the Docker image via
`docker compose build`.

### 2. Run

```bash
GID=$(id -g) docker compose up --build
```

ComfyUI will be available at http://localhost:8188.

### GPU selection

If the host has multiple GPUs, check which index the P2200 is at with `nvidia-smi -L` and update
`device_ids` under `deploy.resources.reservations.devices` in `docker-compose.yml` accordingly
(a GPU UUID can be used instead of an index).

## Directory layout

The following directories are bind-mounted into the container and are not tracked in this repo
(see `.gitignore`):

| Host path      | Container path                              | Purpose                     |
|-----------------|----------------------------------------------|------------------------------|
| `./app/ComfyUI` | `/app/ComfyUI`                                | ComfyUI source (cloned by `build.sh`) |
| `./workflows`   | `/app/ComfyUI/user/default/workflows`         | Saved workflows              |
| `./custom_nodes`| `/app/ComfyUI/custom_nodes`                   | Custom nodes                 |
| `./output`      | `/app/ComfyUI/output`                         | Generated output             |
| `./input`       | `/app/ComfyUI/input`                          | Input images                 |
| `./models`      | `/app/ComfyUI/models`                         | Model checkpoints            |
| `./temp`        | `/app/ComfyUI/temp`                           | Temporary files               |

Hugging Face model/tokenizer caches are also mounted from `~/.cache/huggingface` on the host.

## Files

- `Dockerfile` — image definition (CUDA 12.6, pinned PyTorch, ComfyUI dependencies)
- `docker-compose.yml` — service, volumes, and GPU configuration
- `build.sh` — clones/updates ComfyUI and builds the image
- `entrypoint.sh` — container entrypoint, starts ComfyUI on port 8188
