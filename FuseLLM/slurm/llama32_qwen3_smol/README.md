# SLURM pipeline: Llama-3.2-1B + Qwen3-1.7B-Base + SmolLM2-1.7B

This folder contains one sbatch file per FuseLLM data-construction/training stage.

Model roles in this setup:
- Base/student model: `Llama-3.2-1B`
- Blending model 0: `Qwen3-1.7B-Base`
- Blending model 1: `SmolLM2-1.7B`

## Files

- `00_env.sh`: shared paths and hyperparameters.
- `01_split_long_text.sbatch`
- `02_forward_logits_llama32.sbatch`
- `03_forward_logits_qwen3.sbatch`
- `04_forward_logits_smol2.sbatch`
- `05_vocab_map_qwen_to_llama.sbatch`
- `06_vocab_map_smol_to_llama.sbatch`
- `07_align_qwen_to_llama.sbatch`
- `08_align_smol_to_llama.sbatch`
- `09_pack_features.sbatch`
- `10_train_fusellm.sbatch`
- `submit_pipeline.sh`: submits the full chain with dependencies.

## Before submitting

1. Edit `00_env.sh`:
- `PROJECT_ROOT` (repo path on cluster)
- `RAW_DATASET_DIR` (must be a `datasets.load_from_disk` directory)
- `RUN_ROOT` / `CACHE_DIR` if needed
- precision/worker defaults if needed:
- `FORWARD_HALF_PRECISION` (default `fp16`)
- `PREPROC_WORKERS` and `FORWARD_PREPROC_WORKERS`

2. Verify your cluster directives:
- `--qos`
- `--gres`
- `--time`, `--mem`, `--cpus-per-task`
- `-w` node pinning (current scripts pin to `maia`)

Notes for mixed Turing GPUs (RTX 2080 Ti / Quadro RTX 6000):
- Use FP16 rather than BF16.
- FlashAttention is disabled in training script by default.
- Training job is set to 2 GPUs by default (safer starting point).
- CPU requests are capped for a 12-core node:
- CPU-heavy single jobs use 12 CPUs.
- Forward array jobs use 2 CPUs each with `%2` concurrency cap.
- Alignment/packing arrays use `%1` (one task at a time) to avoid oversubscription.
- CPU-only stages use `--qos=cpu`.
- All stages pin node with `-w maia` to match non-shared filesystem guidance.

## Pin training to Quadro GPUs

Use `TRAIN_SBATCH_EXTRA` when launching the pipeline so only training job gets pinned:

```bash
TRAIN_SBATCH_EXTRA="--constraint=quadro --gres=gpu:2" ./submit_pipeline.sh
```

If your cluster uses typed GRES names, use your site-specific label, for example:

```bash
TRAIN_SBATCH_EXTRA="--gres=gpu:quadro_rtx_6000:2" ./submit_pipeline.sh
```

You can run `sinfo -o \"%N %G %f\"` or ask admins for the exact GPU type string.

3. Make scripts executable:

```bash
chmod +x *.sbatch submit_pipeline.sh 00_env.sh
```

## Submit

```bash
./submit_pipeline.sh
```

Or submit manually in order using `sbatch`.

## Manual `sbatch` order

If you prefer not to use `submit_pipeline.sh`, submit in this order:

1. Split text

```bash
sbatch 01_split_long_text.sbatch
```

2. Forward logits (all three model jobs)

```bash
sbatch 02_forward_logits_llama32.sbatch
sbatch 03_forward_logits_qwen3.sbatch
sbatch 04_forward_logits_smol2.sbatch
```

3. Vocab mappings

```bash
sbatch 05_vocab_map_qwen_to_llama.sbatch
sbatch 06_vocab_map_smol_to_llama.sbatch
```

4. Alignment

```bash
sbatch 07_align_qwen_to_llama.sbatch
sbatch 08_align_smol_to_llama.sbatch
```

5. Packing

```bash
sbatch 09_pack_features.sbatch
```

6. Training

```bash
sbatch 10_train_fusellm.sbatch
```

Recommended:
- Wait for each stage to finish successfully before submitting the next stage.
- Use `squeue -u $USER` and check `slurm-*.out` / `slurm-*.err` between stages.
