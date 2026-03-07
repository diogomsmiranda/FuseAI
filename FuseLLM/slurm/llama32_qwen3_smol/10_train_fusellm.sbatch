#!/bin/bash
#SBATCH --job-name=fusellm-s6-train
#SBATCH --time=2-00:00:00
#SBATCH --qos=gpu-medium
#SBATCH -p a6000
#SBATCH -w artemis
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=140G
#SBATCH --output=slurm-%j.out
#SBATCH --error=slurm-%j.err

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/00_env.sh"

module load "${PYTHON_MODULE}"
source "${VENV_PATH}/bin/activate"

cd "${PROJECT_ROOT}"

DATASET_LIST=()
for i in $(seq 0 $((NUM_SPLITS - 1))); do
  DATASET_LIST+=("${i}_${NUM_SPLITS}_${PACKED_PREFIX}")
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
  --report_to tensorboard \
  --do_distill \
  --distill_with_ref_model True \
  --distill_with_aligned_model_0 True \
  --distill_with_aligned_model_1 True \
  --distill_loss_type ce \
  --distill_teacher_temperature 1.0 \
  --lm_loss_weight 0.9 \
  --distill_greater_as_gt True \
  --distill_greater_as_gt_type hard \
  --dataloader_num_workers 10 \
  --remove_unused_columns False 2>&1 | tee "${LOG_DIR}/train.log"

deactivate
