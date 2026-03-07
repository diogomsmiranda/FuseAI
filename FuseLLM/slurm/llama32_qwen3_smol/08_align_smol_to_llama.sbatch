#!/bin/bash
#SBATCH --job-name=fusellm-s4-align-smol
#SBATCH --time=1-00:00:00
#SBATCH --qos=cpu
#SBATCH -p a6000
#SBATCH -w artemis
#SBATCH --cpus-per-task=12
#SBATCH --mem=96G
#SBATCH --array=0-7%1
#SBATCH --output=slurm-%A_%a.out
#SBATCH --error=slurm-%A_%a.err

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/00_env.sh"

module load "${PYTHON_MODULE}"
source "${VENV_PATH}/bin/activate"

cd "${PROJECT_ROOT}"

IDX="${SLURM_ARRAY_TASK_ID}"

python ./src/utils/token_alignment.py \
  --base_model_name_or_path "${BASE_MODEL}" \
  --blending_model_name_or_path "${BLEND_MODEL_1}" \
  --base_dataset_dir "${IDX}_${NUM_SPLITS}_${ALIGNED_0_PREFIX}" \
  --blending_dataset_dir "${IDX}_${NUM_SPLITS}_${LOGITS_BLEND1_PREFIX}" \
  --dataset_save_dir "${IDX}_${NUM_SPLITS}_${ALIGNED_1_PREFIX}" \
  --cache_dir "${CACHE_DIR}" \
  --model_max_length "${MODEL_MAX_LENGTH}" \
  --preprocessing_num_workers "${PREPROC_WORKERS}" \
  --batch_size 100 \
  --blending_model_index 1 \
  --vocab_align_type soft \
  --vocab_mapping_save_dir "${VOCAB_MAP_1}" \
  --metric_level sequence

deactivate
