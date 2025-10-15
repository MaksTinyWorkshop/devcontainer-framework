# 🐳 DevContainer — Node.js

Un environnement de développement **Node.js** prêt à l’emploi, basé sur le DevContainer universel.  
Il fournit une configuration Docker complète et persistante pour travailler sans rien installer localement.

---

## ⚙️ Contenu du DevContainer

```
.devcontainer/
├── compose.dev.yml   # Service Docker + volume persistant
├── Dockerfile        # Image Node 22 Alpine + outils de base
└── devcontainer.json # Configuration VSCode + extensions
```

---

## 🧩 Environnement inclus

- **Node.js 22 (Alpine)**
- **bash** et **git**
- **npm** préinstallé
- Extensions VSCode :
  - ESLint (linting automatique)
  - Prettier (formatage)
  - npm Intellisense
  - Path Intellisense

---

## 🚀 Utilisation

Une fois le conteneur ouvert dans VSCode :

```bash
npm install
npm run dev
```

Le code et les dépendances sont stockés dans un **volume Docker persistant**, tu peux donc reconstruire ou supprimer le conteneur sans rien perdre.

---

✨ **En résumé :**  
Ce DevContainer offre un environnement Node.js isolé, reproductible et prêt à l’emploi pour démarrer n’importe quel projet JavaScript ou TypeScript.
