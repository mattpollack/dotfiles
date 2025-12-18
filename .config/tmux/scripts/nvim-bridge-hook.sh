#!/usr/bin/env bash
# nvim-bridge-hook.sh
# Optimized hook script to notify Neovim of tmux events
# Only runs for low-frequency events to avoid performance issues

# Get event type
EVENT_TYPE="$1"

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
  exit 0
fi

# Find nvim socket directories
SOCKET_DIRS=$(find /tmp -maxdepth 2 -type d -name "nvim.*" 2>/dev/null)

# Send event to all nvim sockets
for socket_dir in $SOCKET_DIRS; do
  for socket in "$socket_dir"/nvim.*.0; do
    if [ -S "$socket" ]; then
      # Send event asynchronously without waiting for response
      nvim --server "$socket" --remote-send \
        "<Cmd>lua pcall(require('tmux-bridge')._emit_from_hook, '$EVENT_TYPE')<CR>" \
        2>/dev/null &
    fi
  done
done

# Don't wait for background jobs
exit 0
