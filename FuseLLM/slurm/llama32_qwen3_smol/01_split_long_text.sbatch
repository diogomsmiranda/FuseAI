#!/bin/bash
#SBATCH --job-name=fusellm-s1-split
#SBATCH --time=0-12:00:00
#SBATCH --qos=cpu
#SBATCH -w maia
#SBATCH --cpus-per-task=12
#SBATCH --mem=128G
#SBATCH --output=slurm-%j.out
#SBATCH --error=slurm-%j.err

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
