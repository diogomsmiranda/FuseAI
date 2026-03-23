#!/bin/bash
#SBATCH --job-name=qwen2p5-task-arith-lm-eval
#SBATCH --time=0-04:00:00
#SBATCH --qos=gpu-short
#SBATCH -p a6000
#SBATCH -w artemis
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --output=/mnt/home/diogomiranda/FuseAI/FuseLLM/slurm/benchmarks_lm_eval/outputs/qwen2p5-task-arith-lm-eval-%j.out
#SBATCH --error=/mnt/home/diogomiranda/FuseAI/FuseLLM/slurm/benchmarks_lm_eval/errors/qwen2p5-task-arith-lm-eval-%j.err

export MODEL_NAME="Qwen2.5-1.5B-task-arithmetic"
export MODEL_PATH="/mnt/scratch-artemis/diogomiranda/Qwen/Qwen2.5-1.5B-task-arithmetic"
export USE_CHAT_TEMPLATE="False"

bash "${SLURM_SUBMIT_DIR:-$(pwd)}/run_lm_eval.sh"
