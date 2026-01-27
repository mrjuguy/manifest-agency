## Worker Error

**Phase:** FAILURE_PHASE
**Error:** ERROR_MESSAGE

<details>
<summary>Error Details</summary>

```
ERROR_DETAILS
```

**Log file:** `LOG_FILE_PATH`

</details>

**Recovery Options:**
- `retry` - Retry from the failed step
- `skip` - Skip the failed step and continue
- `commit-partial` - Commit completed work as-is
- `abort` - Abandon work and clean up

Reply with a recovery command or fix the issue and re-run the worker.

<!-- agent:metadata
status: failed
agent: claude-worker
failed_at: TIMESTAMP
failure_phase: FAILURE_PHASE
error: ERROR_MESSAGE
-->
