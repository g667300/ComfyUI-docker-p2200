#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "[build] Quadro P2200 (Pascal sm_61 / CUDA 12.6 / port 8188)"

# ── Prepare the ComfyUI codebase (clone if missing, pull if present) ────────
mkdir -p app

if [ -d "app/ComfyUI/.git" ]; then
    echo "ComfyUI exists → git pull"
    git -C app/ComfyUI pull
else
    echo "ComfyUI not found → git clone"
    git -C app clone https://github.com/comfyanonymous/ComfyUI.git
fi

# ── Build ─────────────────────────────────────────────────────────────────
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
export GID=$(id -g)

docker compose build "$@"
