#!/bin/bash
#SBATCH --job-name=fusellm-s5-pack
#SBATCH --time=0-12:00:00
#SBATCH --qos=cpu
#SBATCH -w maia
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

python ./src/utils/packing.py \
  --dataset_dir "${IDX}_${NUM_SPLITS}_${ALIGNED_1_PREFIX}" \
  --dataset_save_dir "${IDX}_${NUM_SPLITS}_${PACKED_PREFIX}" \
  --cache_dir "${CACHE_DIR}" \
  --model_max_length "${MODEL_MAX_LENGTH}" \
  --preprocessing_num_workers "${PREPROC_WORKERS}" \
  --batch_size 1000 \
  --metric_level sequence

deactivate
