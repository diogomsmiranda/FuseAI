#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

# Optional extra sbatch flags for training job only.
# Examples:
#   TRAIN_SBATCH_EXTRA="--gres=gpu:quadro_rtx_6000:2"
#   TRAIN_SBATCH_EXTRA="--constraint=quadro --gres=gpu:2"
TRAIN_SBATCH_EXTRA="${TRAIN_SBATCH_EXTRA:-}"

jid_split=$(sbatch 01_split_long_text.sbatch | awk '{print $4}')

jid_fwd_base=$(sbatch --dependency=afterok:${jid_split} 02_forward_logits_llama32.sbatch | awk '{print $4}')
jid_fwd_qwen=$(sbatch --dependency=afterok:${jid_split} 03_forward_logits_qwen3.sbatch | awk '{print $4}')
jid_fwd_smol=$(sbatch --dependency=afterok:${jid_split} 04_forward_logits_smol2.sbatch | awk '{print $4}')

jid_map_qwen=$(sbatch --dependency=afterok:${jid_split} 05_vocab_map_qwen_to_llama.sbatch | awk '{print $4}')
jid_map_smol=$(sbatch --dependency=afterok:${jid_split} 06_vocab_map_smol_to_llama.sbatch | awk '{print $4}')

jid_align_qwen=$(sbatch --dependency=afterok:${jid_fwd_base}:${jid_fwd_qwen}:${jid_map_qwen} 07_align_qwen_to_llama.sbatch | awk '{print $4}')
jid_align_smol=$(sbatch --dependency=afterok:${jid_align_qwen}:${jid_fwd_smol}:${jid_map_smol} 08_align_smol_to_llama.sbatch | awk '{print $4}')

jid_pack=$(sbatch --dependency=afterok:${jid_align_smol} 09_pack_features.sbatch | awk '{print $4}')
jid_train=$(sbatch ${TRAIN_SBATCH_EXTRA} --dependency=afterok:${jid_pack} 10_train_fusellm.sbatch | awk '{print $4}')

echo "split job: ${jid_split}"
echo "forward base job: ${jid_fwd_base}"
echo "forward qwen job: ${jid_fwd_qwen}"
echo "forward smol job: ${jid_fwd_smol}"
echo "map qwen job: ${jid_map_qwen}"
echo "map smol job: ${jid_map_smol}"
echo "align qwen job: ${jid_align_qwen}"
echo "align smol job: ${jid_align_smol}"
echo "pack job: ${jid_pack}"
echo "train job: ${jid_train}"
