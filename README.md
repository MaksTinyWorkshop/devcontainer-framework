# DevContainer Universel — Node.js avec Volume Persitant

Ce dépôt est un template DevContainer universel et autonome, conçu pour travailler sans code local : ton projet, tes dépendances et ton environnement vivent entièrement dans un volume Docker persistant.

Il te permet de créer ou de rejoindre un projet Node.js sans jamais rien installer sur ton poste.

---

## Fonctionnement général

1. Lors du lancement dans VSCode, le conteneur est créé à partir du Dockerfile :
   - basé sur Node 22 Alpine ;
   - inclut bash et git, configurés pour l’utilisateur node.
2. Le conteneur monte un volume Docker persistant :
   - ton code et tes dépendances vivent dans /workspace/DEVPROJECT ;
   - tout est conservé même si tu supprimes le conteneur.
3. Le projet peut ensuite être cloné ou mis à jour directement depuis le terminal de VSCode :
   git clone <ton-repo> .
   npm install

Résultat : tu ouvres VSCode, et tu travailles dans un environnement isolé et persistant, sans rien installer sur ton poste.

---

## Structure

.devcontainer/
├── compose.dev.yml # Service Docker principal + volume persistant
├── Dockerfile # Image Node 22 Alpine + outils de base
├── devcontainer.json # Configuration VSCode + extensions auto

---

## Extensions VSCode installées automatiquement

- christian-kohler.npm-intellisense — suggestions d’imports npm
- christian-kohler.path-intellisense — autocomplétion de chemins
- dbaeumer.vscode-eslint — linting automatique
- esbenp.prettier-vscode — formatage de code

---

## Utilisation

### Lancer ton environnement

#### Avec le launcher automatisé (setup_container.sh)

1. Exécute le script :
   bash setup_container.sh
   Il te demandera :

   - le nom du projet ;
   - l’URL du repo Git à cloner ;
   - et où stocker le launcher sur ton poste.

2. Le script :

   - clone ce template dans un dossier temporaire ;
   - crée un volume Docker dédié (devcontainer\_<nom>\_workspace) ;
   - copie la configuration DevContainer dans le volume ;
   - et lance VSCode directement sur l’environnement.

3. VSCode détecte le .devcontainer et propose d’ouvrir le dossier dans le conteneur.  
   Une fois ouvert, tu peux :
   git pull # ou git clone si le dossier est vide
   npm install # installer les dépendances
   npm run dev # lancer ton app

---

## Persistance et isolation

- Le code et les dépendances sont stockés dans un volume Docker (devcontainer_DEVPROJECT).
- Le volume reste même après suppression du conteneur.
- Le conteneur peut être reconstruit sans perdre ton travail.

---

## Personnalisation

- Change l’URL du dépôt Git ou le comportement du launcher dans setup_container.sh.
- Modifie le port exposé (3000) dans .devcontainer/compose.dev.yml.
- Ajoute d’autres extensions VSCode dans .devcontainer/devcontainer.json.
- Si tu veux changer le nom du projet, remplace DEVPROJECT dans les fichiers .yml, .json, et Dockerfile.

---

## Architecture du workflow

setup*container.sh (local)
│ crée
▼
Volume Docker devcontainer*<projet>
│ monte dans
▼
Conteneur VSCode Dev basé sur Node Alpine
│ exposé à
▼
VSCode (Remote Container)

Tout ton code vit dans le volume Docker, pas sur ton disque.  
Tu peux rouvrir ton projet quand tu veux : ton environnement revient exactement comme tu l’as laissé.

---

## Astuce

Grâce à ce template :

- Tu peux développer sur ton poste local, un serveur distant, ou dans GitHub Codespaces.
- Ton code reste proprement isolé et persistant dans Docker.
- Tu peux changer de projet simplement en exécutant à nouveau setup_container.sh.

---

## Stack technique

- Node.js 22 (Alpine 3.19)
- Docker Compose
- VSCode Dev Containers
- npm / git
- Volume persistant /workspace

---

Ce template est la base idéale pour créer des environnements de développement reproductibles :

- full-stack avec Prisma / Next.js,
- API back-end isolées,
- ou microservices avec volumes partagés.
