# Table of Contents

1. [Introduction](#introduction)
   - 1.1 [Methods to Launch Jobs](#methods-to-launch-jobs)
   - 1.2 [Checking Job Status](#checking-job-status)
2. [Launching Jobs](#launching-jobs)
   - 2.1 [Important Parameters](#important-parameters)
   - 2.2 [Quality of Service (QoS) Options](#quality-of-service-qos-options)
3. [Job Submission Methods](#job-submission-methods)
   - 3.1 [Running a simple script with `srun`](#running-a-simple-script-with-srun)
   - 3.2 [Using tmux sessions to leave jobs running](#using-tmux-sessions-to-leave-jobs-running)
   - 3.3 [Debugging with interactive jobs using `srun --pty`](#debugging-with-interactive-jobs-using-srun---pty)
   - 3.4 [Running complex scripts with `sbatch` (advanced)](#running-complex-scripts-with-sbatch-advanced)
   - 3.5 [Using Jupyter Notebooks with Vscode](#using-jupyter-notebooks-with-vscode)
4. [Slurm Flags](#slurm-flags)
5. [Monitoring Jobs](#monitoring-jobs)
6. [Updating Jobs](#updating-jobs)
7. [Canceling Jobs](#canceling-jobs)
8. [Examining Jobs](#examining-jobs)
9. [Why my job is PENDING?](#why-my-job-is-pending)
   - 9.1 [Which job will run next?](#which-job-will-run-next)

# Introduction

#### Methods to Launch Jobs

Slurm can be used to launch new jobs in three ways:

- `srun --pty` to run a shell (interactive mode)
- `srun` to run a single command
- `sbatch` to run a full script

#### Checking Job Status

Once a `slurm` job is launched, it will be available in the `slurm` queue:

```bash
squeue
```

You may want to use `psqueue`, our pretty squeue. For that, install `rich` first:

```bash
pip install --user rich
```

The output now looks prettier:

```bash
psqeuue
```

**IMPORTANT:** After launching a job, **always** check its status with `squeue`. Sometimes you may think your job was launched and it will run shortly, but due to an unexpected error it will remain on the queue indefinitely. In such cases, you should get an error message from `squeue`.

**Note:** Slurm calculates this field only once per minute so it might not contain a meaningful value right after submitting a job.

# Launching jobs

#### Important parameters

When launching new jobs, there are three important parameters to specify:

- `--gres=gpu:n` the number of gpus required to that job (do **not** use `--gpus=n` to request gpus unless you know what you are doing, this split allocated gpus across different nodes. see [here](https://www.run.ai/guides/slurm/understanding-slurm-gpu-management))
- `--time=[days]-hh:mm:ss` a time estimate required to that job
- `--qos` the name of a QOS (quality of service), which specifies the properties of the job
- `-w` the name of the node to run the script. **Important: At this moment, the filesystem is not shared between nodes. This means that if you have your code on poseidon, you will need to execute your script on poseidon. Thus, you should use this flag to specify that. We are working on sharing the filesystem so that you can run your code on any available node.**

#### Quality of Service (QoS) Options

The available QOS options are:

| name       | priority | max jobs | max cpus/gpus | max time   |
| ---------- | -------- | -------- | ------------- | ---------- |
| cpu        | 10       | 4        | 32            | ∞          |
| gpu-debug  | 20       | 1        | 8             | 01:00:00   |
| gpu-short  | 10       | 4        | 4             | 04:00:00   |
| gpu-medium | 5        | 1        | 4             | 2-00:00:00 |
| gpu-long   | 2        | 2        | 2             | 7-00:00:00 |
| gpu-h100   | 10       | 2        | 4             | 2-00:00:00 |
| gpu-h200   | 10       | 2        | 4             | 4-00:00:00 |
| gpu-hero   | 100      | 3        | 3             | ∞          |

- **NOTE:** You may request `gpu-hero` access in urgent situations, such as when you are nearing the completion of your thesis and facing a tight deadline. In these instances, please check with an admin who will evaluate your case and, if appropriate, grant you the `gpu-hero` QOS.

- **NOTE 2:** `gpu-h100` is reserved for Dionysus and `gpu-h200` for Hades.

# Job Submission Methods

## Running a simple script with `srun`

The simplest way to run a script with slurm is using `srun`. You specify all flags through the command line and then the command you want to execute. For example, the following command allocates one gpu on poseidon for 1 hour:

```
srun --time=01:00:00 --gres=gpu:1 --qos=gpu-debug -w poseidon python3 your_script.py
```

## Using tmux sessions to leave jobs running

The previous option will launch a job associated as if you would have launched it in your shell. Therefore, when you close your ssh session, your job will stop. You can use tmux to avoid this. First, launch tmux. Inside tmux, launch jobs using `srun` as before. In this way, your job will keep running after you log out. Here, we execute the command inside a tmux session so we can leave and the script will run.

```bash
# in artemis, launch a tmux session
$ tmux

# in the tmux session, prepare your job and launch a new slurm job
$ cd myproject
$ source myenv/bin/activate
$ srun --time=04:00:00 --gres=gpu:1 --qos=gpu-long -w poseidon python3 your_script.py
```

## Debugging with interactive jobs using `srun --pty`

The previous alternatives are good to launch a job and forget about it until it finishes. However, you sometimes want to more closely follow your job.
Interactive jobs are useful when a job requires some sort of direct intervention, for example when you want to debug.
Here, we allocate a new shell where you have access to your requested resources. Inside it, you can run your programs as usual. For example: `python3 your_script.py`. To exit, press `CTRL-D` or type `exit` in your terminal:

```
srun --time=01:00:00 --gres=gpu:1 --qos=gpu-debug -w poseidon --pty bash
```

## Running complex scripts with `sbatch` (advanced)

Slurm offers a way to run entire scripts with many options using `sbatch`.
Create a script like this, called `test.sbatch`:

```
#!/bin/bash

#SBATCH --job-name=my_script    # Job name
#SBATCH --output="job.%x.%j.out # Name of stdout output file (%x expands to job name and %j expands to %jobId)
#SBATCH --time=01:00:00         # Run time (hh:mm:ss) - 1.5 hours
#SBATCH --gres=gpu:1            # Number of GPUs to be used
#SBATCH --qos=gpu-debug         # QOS to be used

python3 your_script.py
```

Then run it with:

```
sbatch -w poseidon ./test.sbatch
```

Check that it was submitted using

```
squeue
```

Once it ran through it should show a `job.X.out` file containing the job's output.

## Using Jupyter Notebooks with Vscode

Launch a tmux session within the Vscode Terminal and request for the required gpu(s) using:

```
srun --gres=gpu:1 --qos=gpu-long -w artemis --pty bash
```

Activate your desired environment and launch the notebook using:

```
jupyter notebook --port <port_num> --no-browser
```

Choose "Select Another Kernel" from the notebook you wish to run (within Vscode interface) and then go to "Existing Jupyter Server". Specify the link generated via the above command in the prompt.

Note that the above works by itself when requesting gpu(s) from Artemis.

# Slurm Flags

Expanding your command with flags can provide better control over job management and resource allocation.

<table>
  <thead>
    <tr>
      <th width="25%" align="left">Flag</th>
      <th>Info</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>--job-name=name</code></td>
      <td>Name of the job.</td>
    </tr>
    <tr>
      <td><code>--output=filename</code></td>
      <td>Filename patterns may use the following place-holders such as <code>%x</code> for Job name and <code>%j</code> for Job ID (<a href="https://slurm.schedmd.com/sbatch.html#lbAH">more here</a>).</td>
    </tr>
    <tr>
      <td><code>--time=time</code></td>
      <td>Wallclock time limit of the job. Times may be specified as <code>[days-]hours:minutes:seconds</code>. Example: <code>--time=1-12:00:00</code> for a 36h job.</td>
    </tr>
    <tr>
      <td><code>--mem=size[KMGT]</code></td>
      <td>Memory requirement per node. Example: <code>--mem=4G</code> for 4GB.</td>
    </tr>
    <tr>
      <td><code>--cpus-per-task=n</code></td>
      <td>Number of CPUs needed per task. Useful for multi-threaded applications. Default is one CPU per task.</td>
    </tr>
    <tr>
      <td><code>--gres=gpu:1</code></td>
      <td>Gres specifies your resources. In this case, it specifies the requested number of GPUs.</td>
    </tr>
  </tbody>
</table>

Note that slurm automatically sets the following environment variables:

- `$SLURM_JOB_NAME` (name of the job)
- `$SLURM_JOB_ID` (ID of the job).

# Monitoring Jobs

To get information about running or waiting jobs use

```
squeue [options]
```

The command squeue displays a list of all running or waiting jobs of all users.

The (in our opinion) most interesting additional field is `START_TIME` which for **pending jobs** shows the date and time when Slurm plans to run this job. It is always possible that a job will start earlier but not (much) later.

#### Pretty output

For a prettier squeue output, you may want to add this to your `~/.bashrc`:

```
export SQUEUE_FORMAT="%.7i %9P %35j %.8u %.2t %.12M %.12L %.5C %.7m %.4D %R"
```

And activate it `source ~/.bashrc`.

# Updating Jobs

You can change the configuration of pending jobs with

```
scontrol update job jobid SETTING=VALUE [...]
```

To find out which settings are available we recommend to first run

```
scontrol show job jobid.
```

If then for example you want to change the run-time limit of your job to let's say three hours you would use

```
scontrol update job jobid TimeLimit=03:00:00
```

# Canceling Jobs

To delete pending or running jobs you have to look up their numerical job identifiers aka job-ids. You can e.g. use squeue or squ and take the value(s) from the JOBID column. Then run

```
scancel -u <your_username> <job_id> [...]
```

and the corresponding job will be removed from the wait queue or stopped if it's running. You can specify more than one job identifier after scancel.

If you want to cancel all your pending and running jobs without being asked for confirmation you may use

```
squeue -h -o %i | xargs scancel -u <your_username>.
```

Those options tell squeue to only output the JOBID column (`-o %i`) and to omit the column header (`-h`). Then we pipe those values as arguments to `scancel`.

# Examining Jobs

`sacct` lets you examine your pending, running, and finished Slurm jobs in much more detail than the job statistics page.

```bash
$ sacct
JobID           JobName  Partition    Account  AllocCPUS      State ExitCode
------------ ---------- ---------- ---------- ---------- ---------- --------
```

To view a specific job, run `sacct --jobs=job_id`.

# Why my job is `PENDING`?

These are the most [common reasons](https://docs.hpc.shef.ac.uk/en/latest/referenceinfo/scheduler/SLURM/Common-commands/squeue.html):

| Reason Code             | Explanation                                                                                             |
| ----------------------- | ------------------------------------------------------------------------------------------------------- |
| Priority                | One or more higher priority jobs is in queue for running. Your job will eventually run.                 |
| Dependency              | This job is waiting for a dependent job to complete and will run afterwards.                            |
| Resources               | The job is waiting for resources to become available and will eventually run.                           |
| InvalidAccount          | The job’s account is invalid. Cancel the job and rerun with correct account.                            |
| InvaldQoS               | The job’s QoS is invalid. Cancel the job and rerun with correct account.                                |
| QOS[something]          | This tells you which limit the job is exceeding in the particular QOS. (examples below                  |
| QOSGrpMaxJobsLimit      | Maximum number of jobs for your job’s QoS have been met; job will run eventually.                       |
| QOSMaxGRESPerUser       | The request exceeds the maximum number of a GRES each user is allowed to use for the requested QOS.     |
| PartitionMaxJobsLimit   | Maximum number of jobs for your job’s partition have been met; job will run eventually.                 |
| AssociationMaxJobsLimit | Maximum number of jobs for your job’s association have been met; job will run eventually.               |
| JobLaunchFailure        | The job could not be launched. This may be due to a file system problem, invalid program name, etc.     |
| NonZeroExitCode         | The job terminated with a non-zero exit code.                                                           |
| SystemFailure           | Failure of the Slurm system, a file system, the network, etc.                                           |
| TimeLimit               | The job exhausted its time limit.                                                                       |
| WaitingForScheduling    | No reason has been set for this job yet. Waiting for the scheduler to determine the appropriate reason. |
| BadConstraints          | The job’s constraints can not be satisfied.                                                             |

There is also this one:

- **Nodes required for job are DOWN, DRAINED or reserved for jobs in higher priority partitions**: I think it means the same as `Priority`. Your job should start as soon as the queue is free.

More details:

- [Full list of reasons](https://slurm.schedmd.com/squeue.html#SECTION_JOB-REASON-CODES)
- [Full list of resource limits](https://slurm.schedmd.com/resource_limits.html)

## Which job will run next?

You can filter the jobs and sort them by priority by passing additional args to `psqueue`:

```bash
psqueue --sort=-p,i --states=PD
```

The ones at the top of the list will be launched first.

---

#### References

- https://www.uibk.ac.at/zid/systeme/hpc-systeme/common/tutorials/slurm-tutorial.html
- https://blog.ronin.cloud/slurm-intro/
- https://research-computing.git-pages.rit.edu/docs/slurm_quick_start_tutorial.html
- https://researchcomputing.princeton.edu/support/knowledge-base/job-priority
