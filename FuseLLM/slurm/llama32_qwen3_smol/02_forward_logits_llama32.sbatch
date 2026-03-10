#!/bin/bash
#SBATCH --job-name=fusellm-s2-llama
#SBATCH --time=2-00:00:00
#SBATCH --qos=gpu-medium
#SBATCH -p a6000
#SBATCH -w artemis
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=64G
#SBATCH --array=0-15%4
#SBATCH --output=/mnt/home/diogomiranda/FuseAI/FuseLLM/slurm/llama32_qwen3_smol/outputs/slurm_forward_logits_llama32-%A_%a.out
#SBATCH --error=/mnt/home/diogomiranda/FuseAI/FuseLLM/slurm/llama32_qwen3_smol/errors/slurm_forward_logits_llama32-%A_%a.err

set -euo pipefail

SCRIPT_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"
source "${SCRIPT_DIR}/00_env.sh"

module load "${PYTHON_MODULE}"
source "${VENV_PATH}/bin/activate"

cd "${PROJECT_ROOT}"

IDX="${SLURM_ARRAY_TASK_ID}"

python ./src/utils/forward_for_logits.py \
  --model_name_or_path "${BASE_MODEL}" \
  --dataset "${SPLIT_DATASET_DIR}" \
  --dataset_save_dir "${IDX}_${NUM_SPLITS}_${LOGITS_BASE_PREFIX}" \
  --dataset_split_num "${NUM_SPLITS}" \
  --dataset_index "${IDX}" \
  --cache_dir "${CACHE_DIR}" \
  --model_max_length "${MODEL_MAX_LENGTH}" \
  --training_mode full \
  --load_in_half "${FORWARD_HALF_PRECISION}" \
  --batch_size "${FORWARD_BATCH_SIZE}" \
  --preprocessing_num_workers "${FORWARD_PREPROC_WORKERS}" \
  --top_k_logits "${TOP_K_LOGITS}" \
  --save_per_token_metric

deactivate
