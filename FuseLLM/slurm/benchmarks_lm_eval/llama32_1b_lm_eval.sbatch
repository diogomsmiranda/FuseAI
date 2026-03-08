#!/bin/bash
#SBATCH --job-name=llama32-1b-lm-eval
#SBATCH --time=0-04:00:00
#SBATCH --qos=gpu-short
#SBATCH -p a6000
#SBATCH -w artemis
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --output=/mnt/home/diogomiranda/FuseAI/FuseLLM/slurm/benchmarks_lm_eval/outputs/llama32-1b-lm-eval-%j.out
#SBATCH --error=/mnt/home/diogomiranda/FuseAI/FuseLLM/slurm/benchmarks_lm_eval/errors/llama32-1b-lm-eval-%j.err

export MODEL_NAME="llama32-1b"
export MODEL_PATH="/mnt/scratch-artemis/diogomiranda/Llama-3.2-1B"
export USE_CHAT_TEMPLATE="False"

"${SLURM_SUBMIT_DIR:-$(pwd)}"/run_lm_eval.sh
