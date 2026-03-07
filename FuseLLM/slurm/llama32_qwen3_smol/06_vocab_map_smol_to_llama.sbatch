#!/bin/bash
#SBATCH --job-name=fusellm-s3-vmap-smol
#SBATCH --time=0-4:00:00
#SBATCH --qos=cpu
#SBATCH -p a6000
#SBATCH -w artemis
#SBATCH --cpus-per-task=12
#SBATCH --mem=128G
#SBATCH --output=/mnt/home/diogomiranda/FuseAI/FuseLLM/slurm/llama32_qwen3_smol/outputs/slurm_vocab_map_smol_to_llama-%j.out
#SBATCH --error=/mnt/home/diogomiranda/FuseAI/FuseLLM/slurm/llama32_qwen3_smol/errors/slurm_vocab_map_smol_to_llama-%j.err

set -euo pipefail

SCRIPT_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"
source "${SCRIPT_DIR}/00_env.sh"

module load "${PYTHON_MODULE}"
source "${VENV_PATH}/bin/activate"

cd "${PROJECT_ROOT}"

python ./src/utils/vocab_mapping.py \
  --base_model_name_or_path "${BASE_MODEL}" \
  --blending_model_name_or_path "${BLEND_MODEL_1}" \
  --dataset_dir "${SPLIT_DATASET_DIR}" \
  --vocab_mapping_save_dir "${VOCAB_MAP_1}" \
  --cache_dir "${CACHE_DIR}" \
  --model_max_length "${MODEL_MAX_LENGTH}" \
  --vocab_mapping_type default \
  --num_process "${PREPROC_WORKERS}"

deactivate
