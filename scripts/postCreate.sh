#!/bin/bash
set -e

echo "🔧 Running intelligent post-create setup..."

# --- 1️⃣ Gestion du dépôt Git ---
is_template_remote() {
  local remote_url=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  [[ -z "$remote_url" ]] && return 0
  if [[ "$remote_url" == *template* ]] || [[ "$remote_url" == *starter* ]] || [[ "$remote_url" == *devcontainer* ]] || [[ "$remote_url" == *boilerplate* ]]; then
    return 0
  fi
  return 1
}

if [ -d ".git" ]; then
  remote_url=$(git remote get-url origin 2>/dev/null || echo "")
  if is_template_remote "$remote_url"; then
    echo "🧹 Template remote detected — reinitializing git repository..."
    rm -rf .git
    git init -q
    git config --global --add safe.directory "$(pwd)"
    echo "💡 New git repository initialized."
    echo "👉 Run: git remote add origin <url_de_ton_repo>"
  else
    echo "✅ Existing Git repository kept (non-template)."
  fi
else
  echo "📁 No Git repository found — initializing new one..."
  git init -q
  git config --global --add safe.directory "$(pwd)"
fi

# --- 2️⃣ Installation des dépendances ---
if [ -f "package.json" ]; then
  echo "📦 Installing npm dependencies..."
  if command -v npm >/dev/null 2>&1; then
    npm ci --no-audit --no-fund || npm install
    echo "✅ npm install complete."
  else
    echo "⚠️ npm not found, skipping dependency installation."
  fi
else
  echo "ℹ️ No package.json found — skipping npm install."
fi

# --- 3️⃣ Permissions (prévention des soucis VS Code / Codex) ---
if command -v chown >/dev/null 2>&1; then
  echo "🧩 Normalizing file ownership..."
  chown -R node:node /workspace 2>/dev/null || true
fi

echo "✅ Post-create script finished successfully!"