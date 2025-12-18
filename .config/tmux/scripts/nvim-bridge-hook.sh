#!/usr/bin/env bash
# nvim-bridge-hook.sh
# Optimized hook script to notify Neovim of tmux events
# Only runs for low-frequency events to avoid performance issues

# Debug mode: set to 1 to enable logging
DEBUG="${NVIM_BRIDGE_DEBUG:-0}"
DEBUG_LOG="/tmp/nvim-bridge-hook.log"

debug_log() {
  if [ "$DEBUG" = "1" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$DEBUG_LOG"
  fi
}

# Get event type
EVENT_TYPE="$1"
debug_log "Hook triggered: EVENT_TYPE=$EVENT_TYPE"

# Validate event type - only allow low-frequency events
case "$EVENT_TYPE" in
  pane:*|window:*|session:*)
    # Only allow low-frequency events
    ;;
  *)
    # Reject high-frequency events (client:*, keys:*, etc.)
    exit 0
    ;;
esac

# Quick check if nvim is even running
if ! pgrep -q nvim 2>/dev/null; then
  debug_log "No nvim processes found, exiting"
  exit 0
fi

# Get all tmux panes in current window
TMUX_PANES=$(tmux list-panes -F '#{pane_pid}' 2>/dev/null)
if [ -z "$TMUX_PANES" ]; then
  debug_log "No tmux panes found, exiting"
  exit 0
fi

debug_log "Found panes: $TMUX_PANES"

# Track processed sockets to avoid duplicates (using simple string list)
PROCESSED_SOCKETS=""

# Helper function to check if socket was already processed
is_socket_processed() {
  local socket=$1
  echo "$PROCESSED_SOCKETS" | grep -q "$socket"
}

# Helper function to find and notify nvim instances recursively
find_and_notify_nvim() {
  local parent_pid=$1
  
  # Get all child processes
  local children=$(pgrep -P "$parent_pid" 2>/dev/null)
  
  for child_pid in $children; do
    # Check if this process is nvim
    if ps -p "$child_pid" -o comm= 2>/dev/null | grep -q "^nvim$"; then
      # Found an nvim process, find its socket
      debug_log "Found nvim process: $child_pid"
      
      # Try multiple socket locations
      local socket=""
      
      # Try $TMPDIR first (macOS default)
      if [ -n "$TMPDIR" ]; then
        socket=$(find "$TMPDIR" -maxdepth 3 -name "nvim.${child_pid}.0" -type s 2>/dev/null | head -1)
      fi
      
      # Try /tmp if not found
      if [ -z "$socket" ]; then
        socket=$(find /tmp -maxdepth 3 -name "nvim.${child_pid}.0" -type s 2>/dev/null | head -1)
      fi
      
      # Try /var/folders if still not found (macOS fallback)
      if [ -z "$socket" ]; then
        socket=$(find /var/folders -maxdepth 5 -name "nvim.${child_pid}.0" -type s 2>/dev/null | head -1)
      fi
      
      debug_log "Socket search result: $socket"
      
      if [ -S "$socket" ] && ! is_socket_processed "$socket"; then
        # Mark as processed
        PROCESSED_SOCKETS="$PROCESSED_SOCKETS $socket"
        debug_log "Notifying nvim at socket: $socket"
        
        # Send event asynchronously
        nvim --server "$socket" --remote-send \
          "<Cmd>lua pcall(require('tmux-bridge')._emit_from_hook, '$EVENT_TYPE')<CR>" \
          2>/dev/null &
      elif [ ! -S "$socket" ]; then
        debug_log "Socket not found or not a socket for PID $child_pid"
      fi
    fi
    
    # Recursively check children (for nested shells, etc.)
    find_and_notify_nvim "$child_pid"
  done
}

# Find nvim processes in all panes of current window
for pane_pid in $TMUX_PANES; do
  debug_log "Searching pane PID: $pane_pid"
  find_and_notify_nvim "$pane_pid"
done

# Count notified instances
NOTIFIED_COUNT=$(echo "$PROCESSED_SOCKETS" | wc -w | tr -d ' ')
debug_log "Hook complete, notified $NOTIFIED_COUNT nvim instance(s)"

# Don't wait for background jobs
exit 0
