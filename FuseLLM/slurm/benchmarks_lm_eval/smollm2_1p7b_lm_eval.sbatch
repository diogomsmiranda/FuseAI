#!/bin/bash
#SBATCH --job-name=smollm2-1p7b-lm-eval
#SBATCH --time=0-04:00:00
#SBATCH --qos=gpu-short
#SBATCH -p a6000
#SBATCH -w artemis
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --output=/mnt/home/diogomiranda/FuseAI/FuseLLM/slurm/benchmarks_lm_eval/outputs/smollm2-1p7b-lm-eval-%j.out
#SBATCH --error=/mnt/home/diogomiranda/FuseAI/FuseLLM/slurm/benchmarks_lm_eval/errors/smollm2-1p7b-lm-eval-%j.err

export MODEL_NAME="smollm2-1p7b"
export MODEL_PATH="/mnt/scratch-artemis/diogomiranda/SmolLM2-1.7B"
export USE_CHAT_TEMPLATE="False"

bash "${SLURM_SUBMIT_DIR:-$(pwd)}/run_lm_eval.sh"
