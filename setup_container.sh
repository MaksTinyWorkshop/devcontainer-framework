#!/bin/bash
set -e

echo "🌍 Bienvenue dans le setup du DevContainer Framework !"

# Vérification des dépendances

for cmd in docker curl code; do
  if ! command -v $cmd &> /dev/null; then
    echo "❌ La commande '$cmd' est requise mais n'est pas installée. Veuillez l'installer avant de continuer."
    exit 1
  fi
done

# Vérification que Docker est bien démarré
if ! docker info >/dev/null 2>&1; then
  echo "❌ Docker ne semble pas démarré. Lance Docker Desktop ou le daemon avant de continuer."
  exit 1
fi

# 1️⃣ — Collecte d’infos
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

# Si l’utilisateur choisit un environnement avec base de données
if [[ "$PROJECT_TYPE" == "node-db" ]]; then
  echo ""
  echo "🗄️  Choisis le type de base de données :"
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
  echo "✅ Base de données sélectionnée : $DB_TYPE"

  read -p "Nom d'utilisateur pour la base de données [devuser] : " DB_USER
  DB_USER=${DB_USER:-devuser}
  read -s -p "Mot de passe pour la base de données [devpass] : " DB_PASS
  echo ""
  DB_PASS=${DB_PASS:-devpass}
  echo ""
  read -p "Souhaitez-vous que la base de données soit persistante (ne pas être effacée à la suppression du conteneur) ? [Y/n] " DB_PERSIST
  if [[ "$DB_PERSIST" =~ ^[Yy]$ || -z "$DB_PERSIST" ]]; then
    DB_EXTERNAL="true"
  else
    DB_EXTERNAL="false"
  fi
fi

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
if [[ ! "$PROJECT_NAME" =~ ^[a-z0-9] ]]; then
  echo "❌ Le nom du projet doit commencer par une lettre ou un chiffre."
  exit 1
fi
echo "✅ Nom du projet normalisé : $PROJECT_NAME"

# 3️⃣ — Définition des chemins
VOLUME_NAME="devcontainer_${PROJECT_NAME}"
TMP_DIR="/tmp/${PROJECT_NAME}"
LAUNCHER_DIR="${LAUNCHER_BASE}/${PROJECT_NAME}"

# 4️⃣ — Création du volume Docker
echo "📦 Création du volume Docker : $VOLUME_NAME"
docker volume create "$VOLUME_NAME" >/dev/null

# 5️⃣ — Téléchargement du template depuis GitHub
if [[ "$PROJECT_TYPE" == "node-db" && -n "$DB_TYPE" ]]; then
  TEMPLATE_PATH="node-db/${DB_TYPE}"
else
  TEMPLATE_PATH="$PROJECT_TYPE"
fi

echo "⬇️  Téléchargement du template DevContainer ..."

mkdir -p "$TMP_DIR"
curl -fsSL "https://raw.githubusercontent.com/MaksTinyWorkshop/devcontainer-framework/main/templates/${TEMPLATE_PATH}/.devcontainer/devcontainer.json" \
  -o "$TMP_DIR/devcontainer.json"
curl -fsSL "https://raw.githubusercontent.com/MaksTinyWorkshop/devcontainer-framework/main/templates/${TEMPLATE_PATH}/.devcontainer/Dockerfile" \
  -o "$TMP_DIR/Dockerfile"
curl -fsSL "https://raw.githubusercontent.com/MaksTinyWorkshop/devcontainer-framework/main/templates/${TEMPLATE_PATH}/.devcontainer/compose.dev.yml" \
  -o "$TMP_DIR/compose.dev.yml"


# 6️⃣ — Remplacement du placeholder DEVPROJECT
find "$TMP_DIR" -type f -exec sed -i.bak "s/DEVPROJECT/${PROJECT_NAME}/g" {} + && find "$TMP_DIR" -name "*.bak" -delete


# 6️⃣bis — Remplacement des placeholders database
if [[ "$PROJECT_TYPE" == "node-db" ]]; then
  find "$TMP_DIR" -type f -exec sed -i.bak "s/DEV_DB_USER/${DB_USER}/g" {} +
  find "$TMP_DIR" -type f -exec sed -i.bak "s/DEV_DB_PASS/${DB_PASS}/g" {} +
  find "$TMP_DIR" -name "*.bak" -delete

  # Configuration du volume DB persistant ou non
  COMPOSE_FILE="$TMP_DIR/compose.dev.yml"
  if [[ "$DB_EXTERNAL" == "true" ]]; then
    if grep -q "devcontainer_${PROJECT_NAME}_db_data:" "$COMPOSE_FILE"; then
      sed -i.bak "s|devcontainer_${PROJECT_NAME}_db_data:|devcontainer_${PROJECT_NAME}_db_data:\n    external: true|" "$COMPOSE_FILE"
    else
      echo -e "  devcontainer_${PROJECT_NAME}_db_data:\n    external: true" >> "$COMPOSE_FILE"
    fi
    docker volume create "devcontainer_${PROJECT_NAME}_db_data" >/dev/null
  else
    sed -i.bak "/external: true/d" "$COMPOSE_FILE"
  fi
  find "$TMP_DIR" -name "*.bak" -delete
fi


# 7️⃣ — Copie du DevContainer dans le volume Docker
echo "📂 Copie du DevContainer dans le volume..."
docker run --rm -v "$VOLUME_NAME":/workspace -v "$TMP_DIR":/tmp/template alpine \
  sh -c "mkdir -p /workspace/.devcontainer && cp -r /tmp/template/* /workspace/.devcontainer && chown -R 1000:1000 /workspace"


# Avertissement pour dépôt Git potentiellement privé ou non accessible
if [[ -n "$REPO_URL" ]]; then
  if [[ "$REPO_URL" == *"github.com"* && "$REPO_URL" == https://* ]]; then
    echo "⚠️  Le dépôt Git semble être un dépôt GitHub HTTPS. Assurez-vous que vous avez accès au dépôt et que l'authentification est configurée si nécessaire."
  fi
fi

# 8️⃣ — Clonage du dépôt Git (si fourni)
if [ -n "$REPO_URL" ]; then
  if ! git ls-remote "$REPO_URL" &> /dev/null; then
    echo "⚠️  Impossible d'accéder au dépôt $REPO_URL — vérifie ton URL ou ton authentification."
  else
    echo "📥 Clonage du dépôt Git dans le volume..."
    docker run --rm -v "$VOLUME_NAME":/workspace alpine sh -c "
      apk add --no-cache git >/dev/null 2>&1 &&
      git clone '$REPO_URL' /workspace/${PROJECT_NAME} &&
      chown -R 1000:1000 /workspace/${PROJECT_NAME}
    "
  fi
fi


# 9️⃣ — Création du launcher local
echo "🧩 Création du launcher local..."
if [[ -d "$LAUNCHER_DIR" ]]; then
  read -p "⚠️  Un launcher existe déjà à cet emplacement. Voulez-vous le remplacer ? [y/N] " CONFIRM
  if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "🚫 Opération annulée."
    exit 0
  fi
  rm -rf "$LAUNCHER_DIR"
fi
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
echo "🧹 Nettoyage du dossier temporaire..."
find "$TMP_DIR" -name "*.bak" -delete
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