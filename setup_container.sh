#!/bin/bash
set -e

echo "🌍 Bienvenue dans le setup du DevContainer Framework !"

# --- 1️⃣ Collecte d’informations ---
read -p "Nom du projet (ex: myapp) : " RAW_PROJECT_NAME

LOG_FILE="/tmp/devcontainer_setup_${RAW_PROJECT_NAME}.log"
exec > >(tee -a "$LOG_FILE") 2>&1

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

echo ""
echo "🌱 Type d’environnement à créer :"
echo "  1) Node.js"
echo "  2) Node.js + Base de données"
read -p "👉 Choix (1-2) [1] : " ENV_CHOICE

case "${ENV_CHOICE:-1}" in
  1) PROJECT_TYPE="node" ;;
  2) PROJECT_TYPE="node-db" ;;
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
read -p "Chemin où stocker le launcher en local : " LAUNCHER_BASE
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
if docker volume inspect "$VOLUME_NAME" >/dev/null 2>&1; then
  echo "📦 Volume $VOLUME_NAME existe déjà, réutilisation."
else
  echo "📦 Création du volume : $VOLUME_NAME"
  docker volume create "$VOLUME_NAME" >/dev/null
  echo "✅ Volume prêt."
fi

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
while IFS= read -r -d '' FILE; do
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/DEVPROJECT/${PROJECT_NAME}/g" "$FILE" || echo "⚠️ Échec sed sur $FILE"
  else
    sed -i "s/DEVPROJECT/${PROJECT_NAME}/g" "$FILE" || echo "⚠️ Échec sed sur $FILE"
  fi
done < <(find "$TMP_DIR" -type f \( -name "*.json" -o -name "*.yml" -o -name "Dockerfile" \) -print0)

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

if [[ -n "$REPO_URL" ]]; then
  echo "    external: true" >> "$TMP_DIR/compose.dev.yml"
fi



# --- 7️⃣ Initialisation du volume et clonage du repo (si applicable) ---
echo "📂 Préparation du volume..."

# Récupère l'UID/GID de l'utilisateur hôte pour des permissions cohérentes
HOST_UID=$(id -u)
HOST_GID=$(id -g)

if [[ -n "$REPO_URL" ]]; then
  echo "📥 Clonage de $REPO_URL dans le volume..."
  docker run --rm \
    -u "$HOST_UID:$HOST_GID" \
    -v "$VOLUME_NAME":/workspace \
    debian:bookworm-slim /bin/bash -c "
      set -e
      apt-get update -qq &&
      apt-get install -y git ca-certificates >/dev/null 2>&1 &&
      mkdir -p /workspace/${PROJECT_NAME} &&
      if git clone --depth=1 '$REPO_URL' /workspace/${PROJECT_NAME} 2>/dev/null; then
        echo '✅ Dépôt cloné avec succès.'
      else
        echo '⚠️  Clonage échoué ou privé (vérifie ton accès ou le repo).'
      fi

      chown -R $HOST_UID:$HOST_GID /workspace/${PROJECT_NAME}

      if [ -d /workspace/${PROJECT_NAME}/.git ]; then
        echo '🔄 Réinitialisation du dépôt Git...'
        cd /workspace/${PROJECT_NAME} &&
        git config --system --add safe.directory /workspace/${PROJECT_NAME} &&
        git config --system user.email \"devcontainer@local\" &&
        git config --system user.name \"DevContainer Bot\" &&
        rm -rf .git &&
        git init &&
        git add . &&
        git commit -m \"🎉 Initialisation du dépôt à partir du template ${REPO_URL}\"
      fi
    "
else
  echo "📂 Initialisation d’un projet vide..."
  docker run --rm \
    -u "$HOST_UID:$HOST_GID" \
    -v "$VOLUME_NAME":/workspace \
    alpine sh -c "
      mkdir -p /workspace/${PROJECT_NAME} &&
      chown -R $HOST_UID:$HOST_GID /workspace/${PROJECT_NAME}
    "
fi

# --- 8️⃣ Création launcher local ---
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

# --- 9️⃣ Nettoyage ---
echo "🧹 Nettoyage du dossier temporaire..."
rm -rf "$TMP_DIR"

echo "🪶 Log disponible dans : $LOG_FILE"

# --- 1️⃣0️⃣ Final ---
echo "✅ Setup terminé !"
echo "📁 Launcher local : $LAUNCHER_DIR"
echo "➡️  Ouvre avec : code \"$LAUNCHER_DIR\""
read -p "Souhaitez-vous ouvrir VS Code maintenant ? (Y/n) " OPEN_NOW
[[ "$OPEN_NOW" =~ ^[Yy]$ || -z "$OPEN_NOW" ]] && code "$LAUNCHER_DIR"