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
- `FORWARD_HALF_PRECISION` (default `bf16`)
- `TRAIN_BF16`, `TRAIN_FP16`, `TRAIN_TF32`, `TRAIN_USE_FLASH_ATTN`
- `PREPROC_WORKERS` and `FORWARD_PREPROC_WORKERS`

2. Verify your cluster directives:
- `--qos`
- `--gres`
- `--time`, `--mem`, `--cpus-per-task`
- `-p a6000 -w artemis`

Notes for RTX A6000:
- A6000 supports BF16, so forward passes now default to `bf16`.
- Training now defaults to `--bf16 True --fp16 False --tf32 True`.
- Training enables `--use_flash_attn True` by default for the Llama student model; set `TRAIN_USE_FLASH_ATTN=False` if `flash-attn` is not installed in your env.
- Forward array jobs now use `%4`, so each forward stage can use up to 4 A6000s at once.
- Training now requests 1 GPU because only the 1B student model is trained; the 1.7B teacher signals come from the packed dataset rather than loading both teacher models during training.
- CPU-only stages still use `--qos=cpu`, but they are pinned to `artemis` to stay on the same node-local filesystem.

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

## GPU sizing

- Forward logits jobs still need `1` GPU each. They load one model at a time (`Llama-3.2-1B`, `Qwen3-1.7B-Base`, or `SmolLM2-1.7B`), and even the 1.7B models are comfortable on a 46 GiB A6000 in BF16.
- Training now needs `1` GPU rather than `2`. The student model is only `Llama-3.2-1B` (~1.86 GiB BF16 weights), and the packed dataset changes runtime/disk size rather than per-step GPU memory.
- The expensive part of distillation during training is the dense target distributions. At sequence length `2048` and vocab size `128256`, one BF16 target distribution is about `0.49 GiB`; the base plus two aligned teacher distributions are about `1.47 GiB` total. Adding student logits, activations, gradients, and optimizer state still keeps this job well under a single 46 GiB A6000.
