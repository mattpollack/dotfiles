#!/usr/bin/env bash
# nvim-bridge-hook.sh
# Lightweight hook script to notify Neovim of tmux events

# Get event type
EVENT_TYPE="$1"

# Validate event type (allow all events through)
case "$EVENT_TYPE" in
  pane:*|window:*|session:*|client:*|layout:*|alert:*|copy-mode:*|keys:*|command:*)
    # Valid event
    ;;
  *)
    exit 0
    ;;
esac

# Find and notify all Neovim instances in remaining panes
PANES=$(tmux list-panes -F '#{pane_id}')

for PANE_ID in $PANES; do
  PANE_PID=$(tmux display-message -p -t "$PANE_ID" '#{pane_pid}')

  # Check if nvim is running in this pane (check all child processes)
  HAS_NVIM=$(pgrep -P "$PANE_PID" | xargs -I {} ps -p {} -o comm= 2>/dev/null | grep -q nvim && echo "yes" || echo "no")

  if [ "$HAS_NVIM" = "yes" ]; then
    # Find Neovim sockets by matching TMUX_PANE
    # Check both /tmp and /var/folders for macOS compatibility
    SOCKET_DIRS=$(find /tmp /var/folders -type d -name "nvim.*" 2>/dev/null)

    for socket_dir in $SOCKET_DIRS; do
      for socket_subdir in "$socket_dir"/*; do
        if [ -d "$socket_subdir" ]; then
          for socket in "$socket_subdir"/*; do
            if [ -S "$socket" ]; then
              # Check if this socket belongs to this pane
              SOCKET_PANE=$(nvim --server "$socket" --remote-expr "vim.env.TMUX_PANE" 2>/dev/null)
              if [ "$SOCKET_PANE" = "$PANE_ID" ]; then
                # Send event to Neovim - directly emit the event
                nvim --server "$socket" \
                   --remote-send "<Esc>:lua require('tmux-bridge')._emit_from_hook('$EVENT_TYPE')<CR>" 2>/dev/null
              fi
            fi
          done
        fi
      done
    done
  fi
done

exit 0
