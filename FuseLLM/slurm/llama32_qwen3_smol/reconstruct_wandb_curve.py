#!/usr/bin/env python3
"""Reconstruct a clean FuseLLM W&B curve from Slurm output logs.

The training resumed from checkpoints several times. Some jobs continued past the
last saved checkpoint and then failed/cancelled, so those tail steps were later
replayed by the next resume job. This script keeps only the non-overlapping
checkpoint lineage that produced the final model.
"""

from __future__ import annotations

import argparse
import ast
import csv
import re
from pathlib import Path


TOTAL_STEPS = 5525

# job id, useful inclusive step range
LINEAGE = [
    ("307161", 0, 500),
    ("308081", 501, 2500),
    ("308895", 2501, 4500),
    ("309488", 4501, 5525),
]


def repo_root_from_script() -> Path:
    return Path(__file__).resolve().parent


def output_for_job(outputs_dir: Path, job_id: str) -> Path:
    matches = sorted(outputs_dir.glob(f"slurm_train_fusellm*{job_id}.out"))
    if len(matches) != 1:
        raise FileNotFoundError(f"expected one output for job {job_id}, found {len(matches)}")
    return matches[0]


def last_progress_step(text: str, end: int) -> int | None:
    window = text[max(0, end - 4000) : end]
    matches = re.findall(r"(\d+)/" + str(TOTAL_STEPS), window)
    return int(matches[-1]) if matches else None


def parse_loss_records(path: Path) -> list[dict[str, object]]:
    text = path.read_text(errors="ignore")
    records: list[dict[str, object]] = []
    previous_step: int | None = None

    for match in re.finditer(r"\{'loss':\s*[^\n]+?\}", text):
        payload = ast.literal_eval(match.group(0))
        step = last_progress_step(text, match.start())
        if step is None:
            step = 10 if previous_step is None else previous_step + 10
        previous_step = step
        records.append(
            {
                "step": step,
                "epoch": payload.get("epoch"),
                "loss": payload.get("loss"),
                "learning_rate": payload.get("learning_rate"),
                "grad_norm": payload.get("grad_norm"),
                "source_file": path.name,
            }
        )

    return records


def duration_to_seconds(value: str) -> float:
    parts = value.split(":")
    if len(parts) == 3:
        hours, minutes, seconds = parts
        return int(hours) * 3600 + int(minutes) * 60 + float(seconds)
    if len(parts) == 2:
        minutes, seconds = parts
        return int(minutes) * 60 + float(seconds)
    return float(value)


def parse_final_metrics(path: Path) -> dict[str, float]:
    text = path.read_text(errors="ignore")
    metrics: dict[str, float] = {}

    train_match = re.search(r"\{'train_runtime':\s*[^\n]+?\}", text)
    if train_match:
        train_payload = ast.literal_eval(train_match.group(0))
        for key in ["train_runtime", "train_samples_per_second", "train_steps_per_second", "train_loss"]:
            if key in train_payload:
                metrics[key] = float(train_payload[key])

    for key in [
        "eval_loss",
        "eval_runtime",
        "eval_samples_per_second",
        "eval_steps_per_second",
        "perplexity",
    ]:
        match = re.search(rf"{key}\s*=\s*([0-9:.]+)", text)
        if match:
            metrics[key] = duration_to_seconds(match.group(1))
    return metrics


def reconstruct(outputs_dir: Path) -> tuple[list[dict[str, object]], dict[str, float]]:
    clean: list[dict[str, object]] = []
    seen_steps: set[int] = set()
    final_metrics: dict[str, float] = {}

    for job_id, start, end in LINEAGE:
        path = output_for_job(outputs_dir, job_id)
        for record in parse_loss_records(path):
            step = int(record["step"])
            if start <= step <= end and step not in seen_steps:
                record["source_job"] = job_id
                clean.append(record)
                seen_steps.add(step)
        if job_id == "309488":
            final_metrics = parse_final_metrics(path)

    clean.sort(key=lambda row: int(row["step"]))
    return clean, final_metrics


def write_csv(records: list[dict[str, object]], metrics: dict[str, float], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fieldnames = ["step", "epoch", "loss", "learning_rate", "grad_norm", "source_job", "source_file"]
    with path.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(records)

    metrics_path = path.with_name(path.stem + "_final_metrics.csv")
    with metrics_path.open("w", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(["metric", "value"])
        for key, value in sorted(metrics.items()):
            writer.writerow([key, value])


def upload_to_wandb(records: list[dict[str, object]], metrics: dict[str, float], project: str, name: str) -> None:
    import wandb

    run = wandb.init(project=project, name=name, id="fusellm-clean-reconstructed", resume="allow")
    for row in records:
        wandb.log(
            {
                "train/loss": row["loss"],
                "train/learning_rate": row["learning_rate"],
                "train/grad_norm": row["grad_norm"],
                "epoch": row["epoch"],
                "source_job": row["source_job"],
            },
            step=int(row["step"]),
        )
    for key, value in metrics.items():
        run.summary[key] = value
    run.finish()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--outputs-dir", type=Path, default=repo_root_from_script() / "outputs")
    parser.add_argument("--csv", type=Path, default=repo_root_from_script() / "outputs" / "fusellm_clean_training_curve.csv")
    parser.add_argument("--upload", action="store_true", help="upload reconstructed curve to a clean W&B run")
    parser.add_argument("--project", default="fusellm-llama32-qwen3-smol")
    parser.add_argument("--name", default="fusellm-clean-reconstructed")
    args = parser.parse_args()

    records, metrics = reconstruct(args.outputs_dir)
    write_csv(records, metrics, args.csv)

    print(f"wrote {len(records)} train records to {args.csv}")
    print(f"wrote final metrics to {args.csv.with_name(args.csv.stem + '_final_metrics.csv')}")
    if records:
        print(f"step range: {records[0]['step']}..{records[-1]['step']}")
    if metrics:
        print("final metrics:")
        for key, value in sorted(metrics.items()):
            print(f"  {key}: {value}")

    if args.upload:
        upload_to_wandb(records, metrics, args.project, args.name)


if __name__ == "__main__":
    main()
