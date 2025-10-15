#!/bin/bash
set -e

echo "🌍 Bienvenue dans le setup du DevContainer Framework !"

# --- Vérification des dépendances ---
for cmd in docker curl code; do
  if ! command -v $cmd &> /dev/null; then
    echo "❌ La commande '$cmd' est requise mais n'est pas installée."
    exit 1
  fi
done

if ! docker info >/dev/null 2>&1; then
  echo "❌ Docker n’est pas démarré."
  exit 1
fi

# --- 1️⃣ Collecte d’informations ---
read -p "Nom du projet (ex: myapp) : " RAW_PROJECT_NAME

echo ""
echo "🌱 Type d’environnement à créer :"
echo "  1) Node.js"
echo "  2) Node.js + Base de données"
echo "  3) Python"
read -p "👉 Choix (1-3) [1] : " ENV_CHOICE

case "${ENV_CHOICE:-1}" in
  1) PROJECT_TYPE="node" ;;
  2) PROJECT_TYPE="node-db" ;;
  3) PROJECT_TYPE="python" ;;
  *) PROJECT_TYPE="node" ;;
esac

# --- Gestion DB ---
if [[ "$PROJECT_TYPE" == "node-db" ]]; then
  echo ""
  echo "🗄️ Type de base de données :"
  echo "  1) PostgreSQL"
  echo "  2) MySQL"
  echo "  3) MongoDB"
  read -p "👉 Choix (1-3) [1] : " DB_CHOICE

  case "${DB_CHOICE:-1}" in
    1) DB_TYPE="postgres" ;;
    2) DB_TYPE="mysql" ;;
    3) DB_TYPE="mongo" ;;
    *) DB_TYPE="postgres" ;;
  esac

  read -p "Nom d'utilisateur DB [devuser] : " DB_USER
  DB_USER=${DB_USER:-devuser}
  read -s -p "Mot de passe DB [devpass] : " DB_PASS
  echo ""
  DB_PASS=${DB_PASS:-devpass}
  read -p "Persister la base de données ? [Y/n] " DB_PERSIST
  [[ "$DB_PERSIST" =~ ^[Yy]$ || -z "$DB_PERSIST" ]] && DB_EXTERNAL="true" || DB_EXTERNAL="false"
fi

read -p "URL du repo Git à cloner (facultatif) : " REPO_URL
read -p "Chemin où stocker le launcher (défaut : /Volumes/TeraSSD/Projets_Dev) : " LAUNCHER_BASE
LAUNCHER_BASE=${LAUNCHER_BASE:-/Volumes/TeraSSD/Projets_Dev}

# --- 2️⃣ Normalisation du nom ---
PROJECT_NAME=$(echo "$RAW_PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_-')
if [[ ! "$PROJECT_NAME" =~ ^[a-z0-9_-]+$ || ! "$PROJECT_NAME" =~ ^[a-z0-9] ]]; then
  echo "❌ Nom invalide : doit commencer par une lettre/chiffre et contenir a-z, 0-9, -, _"
  exit 1
fi
echo "✅ Nom normalisé : $PROJECT_NAME"

# --- 3️⃣ Préparation des chemins ---
VOLUME_NAME="devcontainer_${PROJECT_NAME}"
TMP_DIR="/tmp/${PROJECT_NAME}"
LAUNCHER_DIR="${LAUNCHER_BASE}/${PROJECT_NAME}"

# --- 4️⃣ Création volume ---
echo "📦 Création du volume : $VOLUME_NAME"
docker volume create "$VOLUME_NAME" >/dev/null
echo "✅ Volume prêt."

# --- 5️⃣ Téléchargement du template ---
if [[ "$PROJECT_TYPE" == "node-db" ]]; then
  TEMPLATE_PATH="node-db/${DB_TYPE}"
else
  TEMPLATE_PATH="$PROJECT_TYPE"
fi

echo "⬇️ Téléchargement du template ${TEMPLATE_PATH}..."
mkdir -p "$TMP_DIR"
for FILE in devcontainer.json Dockerfile compose.dev.yml; do
  curl -fsSL "https://raw.githubusercontent.com/MaksTinyWorkshop/devcontainer-framework/main/templates/${TEMPLATE_PATH}/.devcontainer/${FILE}" \
    -o "$TMP_DIR/$FILE"
done

# --- 6️⃣ Remplacement des placeholders ---
echo "🔧 Configuration du template..."
find "$TMP_DIR" -type f \( -name "*.json" -o -name "*.yml" -o -name "Dockerfile" \) | while read -r FILE; do
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/DEVPROJECT/${PROJECT_NAME}/g" "$FILE"
  else
    sed -i "s/DEVPROJECT/${PROJECT_NAME}/g" "$FILE"
  fi
done

if [[ "$PROJECT_TYPE" == "node-db" ]]; then
  echo "🔧 Configuration des identifiants DB..."
  for VAR in DB_USER DB_PASS; do
    VAL=${!VAR}
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "s/DEV_${VAR}/${VAL}/g" "$TMP_DIR/compose.dev.yml"
    else
      sed -i "s/DEV_${VAR}/${VAL}/g" "$TMP_DIR/compose.dev.yml"
    fi
  done

  if [[ "$DB_EXTERNAL" == "true" ]]; then
    docker volume create "devcontainer_${PROJECT_NAME}_db_data" >/dev/null
    echo "    external: true" >> "$TMP_DIR/compose.dev.yml"
  fi
fi

# --- 7️⃣ Copie dans le volume ---
docker run --rm -v "$VOLUME_NAME":/workspace -v "$TMP_DIR":/tmp/template alpine \
  sh -c "mkdir -p /workspace/.devcontainer && cp -r /tmp/template/* /workspace/.devcontainer && chown -R 1000:1000 /workspace"

# --- 8️⃣ Clonage du repo ---
if [[ -n "$REPO_URL" ]]; then
  echo "📥 Clonage de $REPO_URL..."
  docker run --rm -v "$VOLUME_NAME":/workspace debian:bookworm-slim sh -c "
    apt-get update -qq && apt-get install -y git ca-certificates >/dev/null 2>&1 &&
    mkdir -p /workspace/${PROJECT_NAME} &&
    git clone --depth=1 '$REPO_URL' /workspace/${PROJECT_NAME} 2>/dev/null ||
    echo '⚠️  Clonage échoué ou privé.'
  "
fi

# --- 9️⃣ Création launcher local ---
mkdir -p "$LAUNCHER_DIR/.vscode"
cp -r "$TMP_DIR" "$LAUNCHER_DIR/.devcontainer"

cat <<EOF > "$LAUNCHER_DIR/.vscode/devcontainer-launcher.code-workspace"
{
  "folders": [{ "path": "." }],
  "settings": {
    "remote.containers.workspaceMount": "source=${VOLUME_NAME},target=/workspace,type=volume",
    "remote.containers.workspaceFolder": "/workspace"
  },
  "extensions": ["ms-vscode-remote.remote-containers"]
}
EOF

# --- 🔟 Nettoyage ---
echo "🧹 Nettoyage du dossier temporaire..."
rm -rf "$TMP_DIR"

# --- 11️⃣ Final ---
echo "✅ Setup terminé !"
echo "📁 Launcher local : $LAUNCHER_DIR"
echo "➡️  Ouvre avec : code \"$LAUNCHER_DIR\""
read -p "Souhaitez-vous ouvrir VS Code maintenant ? (Y/n) " OPEN_NOW
[[ "$OPEN_NOW" =~ ^[Yy]$ || -z "$OPEN_NOW" ]] && code "$LAUNCHER_DIR"