# BMAD METHODOLOGY (Core Logic)

Pour chaque fonctionnalité ou projet, suis scrupuleusement le cycle BMAD :

## 1. BUILD (Conception & Code)
- **Atomicité** : Découper le problème en composants isolés (ex: `ProductCard.astro`, `api/process_image.py`).
- **Prompting** : Générer le code pour l'IDE Antigravity.
- **Priorité** : Faire fonctionner le "Happy Path" d'abord, gérer les cas limites ensuite.

## 2. MANAGE (Data & State)
- **Source of Truth** : Où est la donnée ? (JSON local, DB, API externe ?).
- **Typing** : Définir les interfaces (TypeScript) et les modèles (Pydantic) AVANT de coder la logique.
- **Organization** : Structure de fichiers claire et modulaire.

## 3. AUTOMATE (Workflows & AI)

## 4. DEPLOY (Ship & Host)
- **CI/CD Light** : Scripts simples pour update le conteneur.
