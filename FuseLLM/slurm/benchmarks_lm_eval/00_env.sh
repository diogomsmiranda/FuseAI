#!/bin/bash

export PYTHON_MODULE="${PYTHON_MODULE:-python/3.12.5}"
export VENV_PATH="${VENV_PATH:-/mnt/home/diogomiranda/.venv}"
export RESULTS_ROOT="${RESULTS_ROOT:-/mnt/scratch-artemis/diogomiranda/lmeval_results/mopd}"
export LM_EVAL_TASKS="${LM_EVAL_TASKS:-mmlu,arc_easy,arc_challenge,gsm8k,hellaswag}"
export LM_EVAL_DTYPE="${LM_EVAL_DTYPE:-bfloat16}"
export LM_EVAL_BATCH_SIZE="${LM_EVAL_BATCH_SIZE:-auto}"
export LM_EVAL_MAX_BATCH_SIZE="${LM_EVAL_MAX_BATCH_SIZE:-32}"
export LM_EVAL_EXTRA_ARGS="${LM_EVAL_EXTRA_ARGS:-}"

mkdir -p "${RESULTS_ROOT}"

if [[ ! -d "${VENV_PATH}" ]]; then
  echo "[ERROR] VENV_PATH does not exist: ${VENV_PATH}" >&2
  exit 1
fi
