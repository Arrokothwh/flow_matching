#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 1. Install tools
# ============================================================

apt install -y build-essential cmake git curl wget tmux htop gdb python3-pip python3-venv ffmpeg libgl1 libglib2.0-0

echo 'set -g mouse on' >> ~/.tmux.conf
tmux source-file ~/.tmux.conf 2>/dev/null || true

# ============================================================
# 2. Install Claude Code and OpenAI Codex CLI
# ============================================================

curl -fsSL https://claude.ai/install.sh | bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh

# Ensure user-installed commands are on PATH.
SHELL_RC="$HOME/.bashrc"

if [[ "${SHELL:-}" == *"zsh"* ]]; then
    SHELL_RC="$HOME/.zshrc"
fi

touch "$SHELL_RC"

if ! grep -qF 'export PATH="$HOME/.local/bin:$PATH"' "$SHELL_RC"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
fi

export PATH="$HOME/.local/bin:$PATH"

# ============================================================
# 3. Install the GitHub SSH private key
# ============================================================

KEY_PATH="/weka/oe-training-default/yuhengw/beaker-interactive-image/.key"

if [[ ! -f "$KEY_PATH" ]]; then
    echo "Error: SSH key does not exist: $KEY_PATH" >&2
    exit 1
fi

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

install -m 600 "$KEY_PATH" "$HOME/.ssh/ai2"

# ============================================================
# 4. Configure GitHub SSH
# ============================================================

SSH_CONFIG="$HOME/.ssh/config"
touch "$SSH_CONFIG"
chmod 600 "$SSH_CONFIG"

if ! grep -qE '^[[:space:]]*Host[[:space:]]+github\*[[:space:]]*$' \
    "$SSH_CONFIG"; then
    cat >> "$SSH_CONFIG" <<'EOF'

Host github*
  HostName github.com
  User git
  IdentityFile ~/.ssh/ai2
  IdentitiesOnly yes
EOF
fi

git config --global user.name "Arrokothwh"
git config --global user.email "arrokothwhi@gmail.com"

# ============================================================
# 5. Enable tmux mouse support
# ============================================================

TMUX_CONFIG="$HOME/.tmux.conf"
touch "$TMUX_CONFIG"

if ! grep -qE '^[[:space:]]*set(-option)?[[:space:]]+-g[[:space:]]+mouse[[:space:]]+on' \
    "$TMUX_CONFIG"; then
    cat >> "$TMUX_CONFIG" <<'EOF'

# Enable mouse scrolling, pane selection, and resizing
set -g mouse on
EOF
fi

# Reload tmux configuration when a tmux server is already running.
if tmux list-sessions >/dev/null 2>&1; then
    tmux source-file "$TMUX_CONFIG"
fi

# ============================================================
# 6. Verification
# ============================================================

echo
echo "Installed versions:"
claude --version || true
codex --version || true
python3 --version
git --version
tmux -V
ffmpeg -version | head -n 1

echo
echo "Testing GitHub SSH authentication..."
ssh -o StrictHostKeyChecking=accept-new -T git@github.com || true

echo
echo "Setup complete."
echo "Restart your shell or run:"
echo "  source \"$SHELL_RC\""

/bin/sleep 2000000000
