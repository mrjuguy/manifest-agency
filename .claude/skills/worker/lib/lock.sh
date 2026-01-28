#!/usr/bin/env bash
# lock.sh - Atomic lock file management for worker
#
# Usage:
#   source .claude/skills/worker/lib/lock.sh
#   acquire_lock 42         # Normal acquisition
#   acquire_lock 42 true    # Force stale lock
#   release_lock            # Explicit release (also happens on EXIT)
#   check_lock_status 42    # Check if locked and by whom
#
# NOTE: Uses mkdir for atomic locking (flock not available on Windows/MINGW64)

# Global variables
LOCK_DIR=""

# Load staleness threshold from config
get_staleness_threshold() {
  local config=".worker/config.json"
  if [ -f "$config" ]; then
    jq -r '.lock_staleness_threshold_seconds // 1800' "$config"
  else
    echo "1800"  # Default 30 minutes
  fi
}

# Acquire lock for an issue
# Arguments: issue_number [force=false]
# Returns: 0 on success, 1 on failure
acquire_lock() {
  local issue="$1"
  local force="${2:-false}"

  LOCK_DIR=".worker/locks/issue-${issue}.lock"
  local lock_metadata="$LOCK_DIR/metadata.json"

  # Create parent locks directory if needed
  mkdir -p ".worker/locks"

  # Try atomic lock acquisition using mkdir
  # mkdir is atomic on most filesystems including NTFS
  if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    # Lock exists - check staleness
    if [ ! -f "$lock_metadata" ]; then
      # No metadata - consider very stale
      local lock_age=999999
    else
      local lock_mtime
      lock_mtime=$(stat -c %Y "$lock_metadata" 2>/dev/null || stat -f %m "$lock_metadata" 2>/dev/null || echo 0)
      local lock_age=$(( $(date +%s) - lock_mtime ))
    fi

    local threshold
    threshold=$(get_staleness_threshold)

    if [ "$lock_age" -gt "$threshold" ]; then
      if [ "$force" = "true" ]; then
        echo "[worker] Forcing stale lock (${lock_age}s old, threshold: ${threshold}s)"
        rm -rf "$LOCK_DIR"
        if ! mkdir "$LOCK_DIR" 2>/dev/null; then
          echo "[error] Failed to acquire lock after force"
          return 1
        fi
      else
        echo "[error] Stale lock detected (${lock_age}s old, threshold: ${threshold}s)"
        echo ""
        echo "Options:"
        echo "  --force     Override stale lock"
        echo "  --inspect   View crash state"
        return 1
      fi
    else
      echo "[error] Worker already running for issue #${issue}"
      echo "Lock age: ${lock_age}s (threshold: ${threshold}s)"
      return 1
    fi
  fi

  # Lock acquired - write metadata
  jq -nc \
    --arg issue "$issue" \
    --arg pid "$$" \
    --arg started "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    --arg hostname "$(hostname)" \
    '{issue: $issue, pid: $pid, started: $started, hostname: $hostname}' > "$lock_metadata"

  # Set up trap for cleanup
  trap 'release_lock' EXIT SIGTERM SIGINT

  echo "[worker] Lock acquired: $LOCK_DIR"
  return 0
}

# Release the current lock
release_lock() {
  if [ -n "$LOCK_DIR" ] && [ -d "$LOCK_DIR" ]; then
    rm -rf "$LOCK_DIR"
    LOCK_DIR=""
  fi
}

# Check lock status for an issue
# Arguments: issue_number
# Returns: 0 if locked, 1 if not locked
# Outputs: Lock metadata if locked
check_lock_status() {
  local issue="$1"
  local lock_dir=".worker/locks/issue-${issue}.lock"
  local lock_metadata="$lock_dir/metadata.json"

  if [ ! -d "$lock_dir" ]; then
    echo "Not locked"
    return 1
  fi

  # Read lock metadata
  local metadata
  metadata=$(cat "$lock_metadata" 2>/dev/null || echo '{}')

  local lock_mtime
  if [ -f "$lock_metadata" ]; then
    lock_mtime=$(stat -c %Y "$lock_metadata" 2>/dev/null || stat -f %m "$lock_metadata" 2>/dev/null || echo 0)
  else
    lock_mtime=0
  fi
  local lock_age=$(( $(date +%s) - lock_mtime ))
  local threshold
  threshold=$(get_staleness_threshold)

  echo "Lock status for issue #${issue}:"
  echo "  Directory: $lock_dir"
  echo "  Age: ${lock_age}s"
  echo "  Stale: $([ "$lock_age" -gt "$threshold" ] && echo "yes" || echo "no")"
  echo "  Metadata: $metadata"

  return 0
}
