#!/bin/bash
# Shared configuration for FuseLLM pipeline (Llama-3.2-1B base + Qwen3/SmolLM2 blending).
# Override any variable before sbatch if needed, for example:
#   RAW_DATASET_DIR=/mnt/scratch-artemis/diogomiranda/datasets/minipile_disk sbatch 01_split_long_text.sbatch

export PROJECT_ROOT="${PROJECT_ROOT:-/home/diogomiranda/FuseAI/FuseLLM}"
export VENV_PATH="${VENV_PATH:-/mnt/home/diogomiranda/mopd}"
export PYTHON_MODULE="${PYTHON_MODULE:-python/3.10.14}"

export BASE_MODEL="${BASE_MODEL:-/mnt/scratch-artemis/diogomiranda/Llama-3.2-1B}"
export BLEND_MODEL_0="${BLEND_MODEL_0:-/mnt/scratch-artemis/diogomiranda/Qwen/Qwen3-1.7B-Base}"
export BLEND_MODEL_1="${BLEND_MODEL_1:-/mnt/scratch-artemis/diogomiranda/SmolLM2-1.7B}"

# Must be a datasets.load_from_disk directory with train/validation splits containing a text column.
export RAW_DATASET_DIR="${RAW_DATASET_DIR:-/mnt/scratch-artemis/diogomiranda/datasets/minipile_hf_disk}"

export RUN_ROOT="${RUN_ROOT:-/mnt/scratch-artemis/diogomiranda/fusellm_llama32_qwen3_smol}"
export CACHE_DIR="${CACHE_DIR:-/mnt/scratch-artemis/diogomiranda/hf_cache}"

export NUM_SPLITS="${NUM_SPLITS:-8}"
export MODEL_MAX_LENGTH="${MODEL_MAX_LENGTH:-2048}"
export PREPROC_WORKERS="${PREPROC_WORKERS:-12}"
export FORWARD_PREPROC_WORKERS="${FORWARD_PREPROC_WORKERS:-2}"
export FORWARD_BATCH_SIZE="${FORWARD_BATCH_SIZE:-4}"
export FORWARD_HALF_PRECISION="${FORWARD_HALF_PRECISION:-fp16}"
export TOP_K_LOGITS="${TOP_K_LOGITS:-10}"

export SPLIT_DATASET_DIR="${RUN_ROOT}/01_minipile_split"
export LOGITS_BASE_PREFIX="${RUN_ROOT}/02_logits_llama32_1b"
export LOGITS_BLEND0_PREFIX="${RUN_ROOT}/02_logits_qwen3_1p7b"
export LOGITS_BLEND1_PREFIX="${RUN_ROOT}/02_logits_smol2_1p7b"

export VOCAB_MAP_0="${RUN_ROOT}/03_vocabmap_qwen_to_llama.json"
export VOCAB_MAP_1="${RUN_ROOT}/03_vocabmap_smol_to_llama.json"

export ALIGNED_0_PREFIX="${RUN_ROOT}/03_aligned_llama_qwen"
export ALIGNED_1_PREFIX="${RUN_ROOT}/03_aligned_llama_qwen_smol"

export PACKED_PREFIX="${RUN_ROOT}/04_packed_fusellm"
export TRAIN_OUTPUT_DIR="${RUN_ROOT}/05_fusellm_llama32_qwen3_smol"
export LOG_DIR="${RUN_ROOT}/logs"

export MASTER_PORT="${MASTER_PORT:-20001}"

mkdir -p "${RUN_ROOT}" "${CACHE_DIR}" "${LOG_DIR}" "${TRAIN_OUTPUT_DIR}"

if [[ ! -d "${PROJECT_ROOT}" ]]; then
  echo "[ERROR] PROJECT_ROOT does not exist: ${PROJECT_ROOT}" >&2
  exit 1
fi

if [[ ! -d "${RAW_DATASET_DIR}" ]]; then
  echo "[ERROR] RAW_DATASET_DIR does not exist: ${RAW_DATASET_DIR}" >&2
  exit 1
fi
