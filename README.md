# HealthChecks.io

Helper scripts for running jobs and pinging [Healthchecks](https://healthchecks.io) to track success/failure.

## Contents

- `scripts/hc-ping.sh`: Wrapper that pings Healthchecks at start/success/fail and runs a job.
- `scripts/sleep.job.sh`: Example job script. Appends a timestamp to `scripts/job-date.log` and sleeps 1–4 seconds.
- `scripts/job-date.log`: Log file produced by the example job.

## Requirements

- Bash (tested on Linux)
- `curl`

## Usage

Replace `<PING_URL>` with your check’s unique ping URL from Healthchecks.
Do not share this URL publicly.

### Run the built-in job
Appends a timestamp to `scripts/job-date.log`, sleeps 3s, and pings start/success.

```bash
bash scripts/hc-ping.sh - <PING_URL>
```

### Run an external job script
Runs your script (executes directly if executable, otherwise with `bash`). Exports `LOG_FILE` and `SIMULATE_FAIL` for the child script.

```bash
bash scripts/hc-ping.sh scripts/sleep.job.sh <PING_URL>
```

### Simulate a failure
Send a fail signal (useful for testing alerting). Non‑zero exit triggers the fail ping.

```bash
bash scripts/hc-ping.sh scripts/sleep.job.sh <PING_URL> 1
# or with built-in job:
bash scripts/hc-ping.sh - <PING_URL> 1
```

## What the wrapper does

- Pings `<PING_URL>/start` before running the job.
- Runs either:
  - the built-in job (timestamp → `scripts/job-date.log`, sleep 3s), or
  - your provided script path.
- On any error while the job runs, automatically pings `<PING_URL>/fail`.
- On success, pings `<PING_URL>`.

Exit codes:
- `2`: bad usage (missing args)
- `3`: script file not found

## Environment exposed to job scripts

- `LOG_FILE`: set to `scripts/job-date.log` (absolute path). The example job uses it.
- `SIMULATE_FAIL`: `"0"` by default, `"1"` to force a failure in the wrapper after the job.

Example from `scripts/sleep.job.sh`:

```bash
date '+%Y-%m-%d %H:%M:%S %z' >> "$LOG_FILE"
sleep $((RANDOM % 4 + 1))
```

## Cron examples

Run every 5 minutes:

```bash
*/5 * * * * /usr/bin/bash scripts/hc-ping.sh - <PING_URL> >/dev/null 2>&1
```

Run a custom script daily at 03:15:

```bash
15 3 * * * /usr/bin/bash scripts/hc-ping.sh scripts/sleep.job.sh <PING_URL> >/dev/null 2>&1
```

Tip: keep your `<PING_URL>` in a file with restricted permissions and reference it, e.g.:

```bash
PING_URL="$(cat /home/mahdi-darabi/.secrets/hc_url)"
/usr/bin/bash scripts/hc-ping.sh - "$PING_URL"
```

## Troubleshooting

- Ensure `curl` is installed and outbound HTTPS is allowed.
- If your job needs a different log location, set `LOG_FILE` before calling your script or handle logging inside your script.
- For debugging, temporarily remove output redirection in cron or run manually to see stderr.
- Non‑zero exits from your script will trigger the fail ping.

## Security

- Treat `<PING_URL>` as a secret. Anyone with it can signal success/failure for your check.
- Avoid echoing the URL in logs or command history.