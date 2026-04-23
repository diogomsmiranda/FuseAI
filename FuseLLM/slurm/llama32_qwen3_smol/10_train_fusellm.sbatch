#!/bin/bash
#SBATCH --job-name=fusellm-s6-train
#SBATCH --time=2-00:00:00
#SBATCH --qos=gpu-h100
#SBATCH -p h100
#SBATCH -w dionysus
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=140G
#SBATCH --output=/mnt/home/diogomiranda/FuseAI/FuseLLM/slurm/llama32_qwen3_smol/outputs/slurm_train_fusellm-%j.out
#SBATCH --error=/mnt/home/diogomiranda/FuseAI/FuseLLM/slurm/llama32_qwen3_smol/errors/slurm_train_fusellm-%j.err

mkdir -p /mnt/scratch-$HOSTNAME/$USER/.cache
mkdir -p /mnt/scratch-$HOSTNAME/$USER/.venvs
mkdir -p /mnt/scratch-$HOSTNAME/$USER/.hf
mkdir -p /mnt/scratch-$HOSTNAME/$USER/.torch
mkdir -p /mnt/scratch-$HOSTNAME/$USER/.conda
mkdir -p /mnt/scratch-$HOSTNAME/$USER/tmp
mkdir -p /mnt/scratch-$HOSTNAME/$USER/wandb
mkdir -p /mnt/scratch-$HOSTNAME/$USER/.triton/autotune

export TMPDIR=/mnt/scratch-$HOSTNAME/$USER/tmp
export XDG_CACHE_HOME=/mnt/scratch-$HOSTNAME/$USER/.cache
export HF_HOME=/mnt/scratch-$HOSTNAME/$USER/.hf
export HF_DATASETS_CACHE=/mnt/scratch-$HOSTNAME/$USER/.hf/datasets
export TORCH_HOME=/mnt/scratch-$HOSTNAME/$USER/.torch
export PIP_CACHE_DIR=/mnt/scratch-$HOSTNAME/$USER/.cache/pip
export CONDA_PKGS_DIRS=/mnt/scratch-$HOSTNAME/$USER/.conda/pkg
export WANDB_PROJECT="fusellm-llama32-qwen3-smol"
export WANDB_NAME="fusellm-lr1e5-bs${TRAIN_PER_DEVICE_BATCH_SIZE}-ga${TRAIN_GRADIENT_ACCUMULATION_STEPS}-len${MODEL_MAX_LENGTH}-job${SLURM_JOB_ID}"
export WANDB_DIR=/mnt/scratch-$HOSTNAME/$USER/wandb
export CUDA_HOME="$(dirname "$(dirname "$(readlink -f "$(which nvcc)")")")"
export PATH="$CUDA_HOME/bin:$PATH"
export LD_LIBRARY_PATH="$CUDA_HOME/lib64:${LD_LIBRARY_PATH:-}"
export TRITON_CACHE_DIR=/mnt/scratch-$HOSTNAME/$USER/.triton

export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True # pytorch memory management 

set -euo pipefail

SCRIPT_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"
source "${SCRIPT_DIR}/00_env.sh"

module load cuda
module load "${PYTHON_MODULE}"
source "${VENV_PATH}/bin/activate"

cd "${PROJECT_ROOT}"

DATASET_LIST=()
for i in $(seq 0 $((NUM_SPLITS - 1))); do
  DATASET_LIST+=("${PACKED_PREFIX}_${i}_${NUM_SPLITS}")
done
DATASET_NAME=$(IFS=, ; echo "${DATASET_LIST[*]}")

deepspeed --master_port "${MASTER_PORT}" ./src/train.py \
  --training_mode full \
  --deepspeed ./config/zero_stage2_config.json \
  --model_name_or_path "${BASE_MODEL}" \
  --output_dir "${TRAIN_OUTPUT_DIR}" \
  --model_max_length "${MODEL_MAX_LENGTH}" \
  --logging_steps 1 \
  --save_strategy steps \
  --save_steps 500 \
  --save_total_limit 1 \
  --evaluation_strategy steps \
  --per_device_eval_batch_size 1 \
  --logging_strategy steps \
  --do_train \
  --do_eval \
  --bf16 "${TRAIN_BF16}" \
  --fp16 "${TRAIN_FP16}" \
  --tf32 "${TRAIN_TF32}" \
  --warmup_ratio 0.008 \
  --lr_scheduler_type cosine \
  --dataset_name "${DATASET_NAME}" \
  --per_device_train_batch_size "${TRAIN_PER_DEVICE_BATCH_SIZE}" \
  --gradient_accumulation_steps "${TRAIN_GRADIENT_ACCUMULATION_STEPS}" \
  --num_train_epochs 1 \
  --eval_steps 500 \
  --optim adamw_torch \
  --adam_beta1 0.9 \
  --adam_beta2 0.95 \
  --learning_rate 1e-5 \
  --weight_decay 0.1 \
  --max_grad_norm 1.0 \
  --seed 42 \
  --gradient_checkpointing True \
  --use_flash_attn "${TRAIN_USE_FLASH_ATTN}" \
  --report_to wandb \
  --do_distill \
  --distill_with_ref_model True \
  --distill_with_aligned_model_0 True \
  --distill_with_aligned_model_1 True \
  --distill_loss_type ce \
  --distill_teacher_temperature 1.0 \
  --lm_loss_weight 0.9 \
  --distill_greater_as_gt True \
  --distill_greater_as_gt_type hard \
  --dataloader_num_workers 8 \
  --remove_unused_columns False 2>&1 | tee "${LOG_DIR}/train.log"

deactivate
