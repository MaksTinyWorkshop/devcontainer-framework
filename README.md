# 🐳 DevContainer Framework

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) ![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker) ![VSCode Dev Containers](https://img.shields.io/badge/VSCode-DevContainer-007ACC?logo=visualstudiocode) ![Platforms](https://img.shields.io/badge/Platforms-macOS%20%7C%20Linux%20%7C%20WSL2-lightgrey)

Un framework léger pour créer des environnements de développement **Docker + VSCode** basés sur des templates prêts à l’emploi | Node pur, ou avec Base de données.

---

## 🚀 Fonctionnalités

- Crée automatiquement un **DevContainer** prêt à l’emploi.
- Monte un **volume Docker persistant** pour ton code (rien sur ton disque local).
- Clone automatiquement ton **projet Git** dans le conteneur si fourni.
- Gère la configuration VSCode pour une ouverture instantanée.
- Compatible **macOS, Linux et WSL2**.

---

## ⚙️ Installation

Pour lancer le setup sans télécharger le projet :

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/MaksTinyWorkshop/devcontainer-framework/main/scripts/setup_container.sh)
```

Ce script :

1. Te demande le nom de ton projet et le type d’environnement
2. Télécharge le template correspondant depuis ce repo.
3. Crée un volume Docker (`devcontainer_<nom>`).
4. Prépare un “launcher” local pour VSCode.
5. Ouvre ton DevContainer prêt à coder.

---

## 💡 Exemple d’utilisation

**Le script te demande :**

```
Nom du projet : mon super projet
Type d’environnement : node
URL du repo Git (facultatif) : https://github.com/unUserQuelconque/SonSuperProjet.git
Chemin du launcher local : /Volumes/HD/Projets_Dev/monsuperprojet
```

⚠️ Le nom du projet ne doit pas commencer part `_` ou `.`. Mais par un caractère alphanumérique. Aussi, s'il contient des espaces, il sera remplaçé par des `_`.

Résultat :

- Un volume Docker nommé `devcontainer_mon_super_projet`
- Un dossier `/Volumes/HD/Projets_Dev/monsuperprojet`
- Un environnement complet prêt à être ouvert avec :
  ```bash
  code /Volumes/HD/Projets_Dev/monsuperprojet
  ```

---

## 📦 Templates disponibles

- **Node.js** → `templates/node/.devcontainer/`
- **Node avec Base de données** → `templates/node-db/...`
- Au choix :
  - **PostgreSQL**
  - **MySQL**
  - **MongoDB**
- **Des updates seront disponibles au fil du temps.**

---

## 🧩 Structure du repo

```
devcontainer-framework/
├── setup_container.sh
├── templates/
│   └── node/
│       └── .devcontainer/
│           ├── devcontainer.json
│           ├── Dockerfile
│           └── compose.dev.yml
│   └── node-db/
│       └── mysql
│           └── .devcontainer/
│               ├── devcontainer.json
│               ├── Dockerfile
│               └── compose.dev.yml
│       └── postgres
│           └── .devcontainer/
│               ├── devcontainer.json
│               ├── Dockerfile
│               └── compose.dev.yml
│       └── mongodb
│           └── .devcontainer/
│               ├── devcontainer.json
│               ├── Dockerfile
│               └── compose.dev.yml
├── LICENSE
└── README.md
```

---

## 📜 Licence

Distribué sous la licence **MIT**.  
© 2025 Maks — libre d’utilisation, modification et distribution.
