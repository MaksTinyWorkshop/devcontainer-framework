# 🐳 DevContainer Framework

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) ![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker) ![VSCode Dev Containers](https://img.shields.io/badge/VSCode-DevContainer-007ACC?logo=visualstudiocode) ![Platforms](https://img.shields.io/badge/Platforms-macOS%20%7C%20Linux%20%7C%20WSL2-lightgrey)

Un framework léger pour créer des environnements de développement **Docker + VSCode** basés sur des templates prêts à l’emploi (Node, Next.js, Python, etc.).

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
bash <(curl -fsSL https://raw.githubusercontent.com/MaksTinyWorkshop/devcontainer-framework/main/setup_container.sh)
```

Ce script :

1. Te demande le nom de ton projet et le type d’environnement (Node, Next.js, etc.)
2. Télécharge le template correspondant depuis ce repo.
3. Crée un volume Docker (`devcontainer_<nom>_workspace`).
4. Prépare un “launcher” local pour VSCode.
5. Ouvre ton DevContainer prêt à coder.

---

## 💡 Exemple d’utilisation

```bash
bash setup_container.sh
```

**Exemple de réponses au prompt :**

```
Nom du projet : mindleaf
Type d’environnement : node
URL du repo Git : https://github.com/tonuser/mindleaf.git
Chemin du launcher local : /Volumes/TeraSSD/Projets_Dev
```

Résultat :

- Un volume Docker nommé `devcontainer_mindleaf_workspace`
- Un dossier `/Volumes/TeraSSD/Projets_Dev/mindleaf`
- Un environnement complet prêt à être ouvert avec :
  ```bash
  code /Volumes/TeraSSD/Projets_Dev/mindleaf
  ```

---

## 📦 Templates disponibles

- **Node.js** → `templates/node/.devcontainer/`
- _(d’autres templates viendront : Next.js, Python, NestJS, Prisma, etc.)_

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
└── README.md
```

---

## 🧠 À venir

- Support multi-template (monorepo, fullstack, etc.)
- Auto-détection du langage
- Setup Prisma / Postgres / Redis préconfiguré
- Interface CLI interactive

---

## 📜 Licence

Distribué sous la licence **MIT**.  
© 2025 Maks — libre d’utilisation, modification et distribution.
