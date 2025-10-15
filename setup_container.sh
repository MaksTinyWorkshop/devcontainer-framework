#!/bin/bash
set -e

echo "🌍 Bienvenue dans le setup du DevContainer Framework !"

# 1️⃣ — Collecte d’infos
read -p "Nom du projet (ex: myapp) : " RAW_PROJECT_NAME
read -p "Type d’environnement (node/nextjs/python) [node] : " PROJECT_TYPE
read -p "URL du repo Git à cloner (facultatif) : " REPO_URL
read -p "Chemin où stocker le launcher local (par défaut : /Volumes/TeraSSD/Projets_Dev) : " LAUNCHER_BASE
LAUNCHER_BASE=${LAUNCHER_BASE:-/Volumes/TeraSSD/Projets_Dev}

# 2️⃣ — Normalisation du nom
PROJECT_NAME=$(echo "$RAW_PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_-')
if [[ ! "$PROJECT_NAME" =~ ^[a-z0-9_-]+$ ]]; then
  echo "❌ Nom invalide après normalisation : \"$PROJECT_NAME\""
  echo "   (autorisés : lettres, chiffres, tirets, underscores)"
  exit 1
fi
echo "✅ Nom du projet normalisé : $PROJECT_NAME"

# 3️⃣ — Définition des chemins
VOLUME_NAME="devcontainer_${PROJECT_NAME}_workspace"
TMP_DIR="/tmp/${PROJECT_NAME}_template"
LAUNCHER_DIR="${LAUNCHER_BASE}/${PROJECT_NAME}"

# 4️⃣ — Création du volume Docker
echo "📦 Création du volume Docker : $VOLUME_NAME"
docker volume create "$VOLUME_NAME" >/dev/null

# 5️⃣ — Téléchargement du template depuis GitHub
echo "⬇️  Téléchargement du template DevContainer ($PROJECT_TYPE)..."
mkdir -p "$TMP_DIR"
curl -fsSL "https://raw.githubusercontent.com/MaksTinyWorkshop/devcontainer-framework/main/templates/${PROJECT_TYPE}/.devcontainer/devcontainer.json" \
  -o "$TMP_DIR/devcontainer.json"
curl -fsSL "https://raw.githubusercontent.com/MaksTinyWorkshop/devcontainer-framework/main/templates/${PROJECT_TYPE}/.devcontainer/Dockerfile" \
  -o "$TMP_DIR/Dockerfile"
curl -fsSL "https://raw.githubusercontent.com/MaksTinyWorkshop/devcontainer-framework/main/templates/${PROJECT_TYPE}/.devcontainer/compose.dev.yml" \
  -o "$TMP_DIR/compose.dev.yml"

# 6️⃣ — Remplacement du placeholder DEVPROJECT
find "$TMP_DIR" -type f -exec sed -i.bak "s/DEVPROJECT/${PROJECT_NAME}/g" {} + && find "$TMP_DIR" -name "*.bak" -delete

# 7️⃣ — Copie du DevContainer dans le volume Docker
echo "📂 Copie du DevContainer dans le volume..."
docker run --rm -v "$VOLUME_NAME":/workspace -v "$TMP_DIR":/tmp/template alpine \
  sh -c "mkdir -p /workspace/.devcontainer && cp -r /tmp/template/* /workspace/.devcontainer && chown -R 1000:1000 /workspace"

# 8️⃣ — Clonage du dépôt Git (si fourni)
if [ -n "$REPO_URL" ]; then
  echo "📥 Clonage du dépôt Git dans le volume..."
  docker run --rm -v "$VOLUME_NAME":/workspace alpine sh -c "
    apk add --no-cache git >/dev/null 2>&1 &&
    git clone '$REPO_URL' /workspace/${PROJECT_NAME} &&
    chown -R 1000:1000 /workspace/${PROJECT_NAME}
  "
fi

# 9️⃣ — Création du launcher local
echo "🧩 Création du launcher local..."
mkdir -p "$LAUNCHER_DIR/.vscode"
cp -r "$TMP_DIR" "$LAUNCHER_DIR/.devcontainer"

# Fichier .code-workspace
cat <<EOF > "$LAUNCHER_DIR/.vscode/devcontainer-launcher.code-workspace"
{
  "folders": [
    { "path": "." }
  ],
  "settings": {
    "remote.containers.workspaceMount": "source=${VOLUME_NAME},target=/workspace,type=volume",
    "remote.containers.workspaceFolder": "/workspace"
  },
  "extensions": [
    "ms-vscode-remote.remote-containers"
  ]
}
EOF

# 🔟 — Nettoyage du template temporaire
rm -rf "$TMP_DIR"

# 11️⃣ — Message final
echo "✅ Setup terminé !"
echo "📁 Launcher local : $LAUNCHER_DIR"
echo ""
echo "➡️  Ouvre ton DevContainer avec :"
echo "   code \"$LAUNCHER_DIR\""
echo ""

read -p "Souhaitez-vous ouvrir VS Code maintenant ? (Y/n) " OPEN_NOW
if [[ "$OPEN_NOW" =~ ^[Yy]$ || -z "$OPEN_NOW" ]]; then
  echo "🚀 Ouverture de VS Code..."
  code "$LAUNCHER_DIR"
else
  echo "👋 Vous pourrez ouvrir le conteneur plus tard avec la commande ci-dessus."
fi