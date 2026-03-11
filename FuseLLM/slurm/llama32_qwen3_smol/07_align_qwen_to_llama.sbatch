#!/bin/bash
#SBATCH --job-name=fusellm-s4-align-qwen
#SBATCH --time=0-12:00:00
#SBATCH --qos=cpu
#SBATCH -p a6000
#SBATCH -w artemis
#SBATCH --cpus-per-task=12
#SBATCH --mem=96G
#SBATCH --array=0-15%1
#SBATCH --output=/mnt/home/diogomiranda/FuseAI/FuseLLM/slurm/llama32_qwen3_smol/outputs/slurm_align_qwen_to_llama-%A_%a.out
#SBATCH --error=/mnt/home/diogomiranda/FuseAI/FuseLLM/slurm/llama32_qwen3_smol/errors/slurm_align_qwen_to_llama-%A_%a.err

set -euo pipefail

SCRIPT_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"
source "${SCRIPT_DIR}/00_env.sh"

module load "${PYTHON_MODULE}"
source "${VENV_PATH}/bin/activate"

cd "${PROJECT_ROOT}"

IDX="${SLURM_ARRAY_TASK_ID}"

python ./src/utils/token_alignment.py \
  --base_model_name_or_path "${BASE_MODEL}" \
  --blending_model_name_or_path "${BLEND_MODEL_0}" \
  --base_dataset_dir "${LOGITS_BASE_PREFIX}_${IDX}_${NUM_SPLITS}" \
  --blending_dataset_dir "${LOGITS_BLEND0_PREFIX}_${IDX}_${NUM_SPLITS}" \
  --dataset_save_dir "${ALIGNED_0_PREFIX}_${IDX}_${NUM_SPLITS}" \
  --cache_dir "${CACHE_DIR}" \
  --model_max_length "${MODEL_MAX_LENGTH}" \
  --preprocessing_num_workers "${PREPROC_WORKERS}" \
  --batch_size 100 \
  --blending_model_index 0 \
  --vocab_align_type soft \
  --vocab_mapping_save_dir "${VOCAB_MAP_0}" \
  --metric_level sequence

deactivate
