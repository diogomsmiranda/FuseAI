# LM-Eval Benchmark Jobs

This folder contains one `sbatch` file per model for running `lm-eval` on:

- `mmlu`
- `arc_easy`
- `arc_challenge`
- `gsm8k`
- `hellaswag`

Defaults are shared in `00_env.sh`.

Before submitting on `artemis`, create log directories:

```bash
mkdir -p /mnt/home/diogomiranda/FuseAI/FuseLLM/slurm/benchmarks_lm_eval/outputs
mkdir -p /mnt/home/diogomiranda/FuseAI/FuseLLM/slurm/benchmarks_lm_eval/errors
```

Then submit any model job manually with `sbatch`.

Notes:

- The scripts default to `/mnt/home/diogomiranda/.venv` to match your existing `lm_eval` setup.
- Only the instruct model script enables `--apply_chat_template` and `--fewshot_as_multiturn`.
- The default walltime is `0-04:00:00` now that `humaneval` is not included.
- Verify the path for `Qwen2.5-1.5B-Instruc` if your actual directory is named `Qwen2.5-1.5B-Instruct`.
