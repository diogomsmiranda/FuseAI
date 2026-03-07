#!/bin/bash
#SBATCH --job-name=fusellm-s1-split
#SBATCH --time=0-6:00:00
#SBATCH --qos=cpu
#SBATCH -p a6000
#SBATCH -w artemis
#SBATCH --cpus-per-task=12
#SBATCH --mem=128G
#SBATCH --output=/mnt/home/diogomiranda/FuseAI/FuseLLM/slurm/llama32_qwen3_smol/outputs/slurm_split_long_text-%j.out
#SBATCH --error=/mnt/home/diogomiranda/FuseAI/FuseLLM/slurm/llama32_qwen3_smol/errors/slurm_split_long_text-%j.err

set -euo pipefail

SCRIPT_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"
source "${SCRIPT_DIR}/00_env.sh"

module load "${PYTHON_MODULE}"
source "${VENV_PATH}/bin/activate"

cd "${PROJECT_ROOT}"

python ./src/utils/split_long_text.py \
  --base_model_name_or_path "${BASE_MODEL}" \
  --blending_model_name_or_path "${BLEND_MODEL_0}" \
  --another_blending_model_name_or_path "${BLEND_MODEL_1}" \
  --dataset "${RAW_DATASET_DIR}" \
  --dataset_save_dir "${SPLIT_DATASET_DIR}" \
  --cache_dir "${CACHE_DIR}" \
  --block_size "${MODEL_MAX_LENGTH}" \
  --preprocessing_num_workers "${PREPROC_WORKERS}"

deactivate
