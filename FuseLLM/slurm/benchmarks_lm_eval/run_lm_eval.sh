#!/bin/bash
set -euo pipefail

SCRIPT_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"
source "${SCRIPT_DIR}/00_env.sh"

if [[ -z "${MODEL_PATH:-}" ]]; then
  echo "[ERROR] MODEL_PATH is not set" >&2
  exit 1
fi

if [[ -z "${MODEL_NAME:-}" ]]; then
  echo "[ERROR] MODEL_NAME is not set" >&2
  exit 1
fi

module load "${PYTHON_MODULE}"
source "${VENV_PATH}/bin/activate"

mkdir -p "${RESULTS_ROOT}/${MODEL_NAME}"

MODEL_ARGS="pretrained=${MODEL_PATH},dtype=${LM_EVAL_DTYPE},trust_remote_code=True"

if [[ "${USE_CHAT_TEMPLATE:-False}" == "True" ]]; then
  lm_eval \
    --model hf \
    --model_args "${MODEL_ARGS}" \
    --tasks "${LM_EVAL_TASKS}" \
    --fewshot_as_multiturn \
    --apply_chat_template \
    --batch_size "${LM_EVAL_BATCH_SIZE}" \
    --max_batch_size "${LM_EVAL_MAX_BATCH_SIZE}" \
    --device cuda \
    --confirm_run_unsafe_code \
    --output_path "${RESULTS_ROOT}/${MODEL_NAME}/results.json" \
    ${LM_EVAL_EXTRA_ARGS}
else
  lm_eval \
    --model hf \
    --model_args "${MODEL_ARGS}" \
    --tasks "${LM_EVAL_TASKS}" \
    --batch_size "${LM_EVAL_BATCH_SIZE}" \
    --max_batch_size "${LM_EVAL_MAX_BATCH_SIZE}" \
    --device cuda \
    --confirm_run_unsafe_code \
    --output_path "${RESULTS_ROOT}/${MODEL_NAME}/results.json" \
    ${LM_EVAL_EXTRA_ARGS}
fi

deactivate
