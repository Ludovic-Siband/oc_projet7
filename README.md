<p align="center">
   <img src="./front/src/favicon.png" width="192px" />
</p>

# MicroCRM (P7 - Développeur Full-Stack - Java et Angular - Mettez en œuvre l'intégration et le déploiement continu d'une application Full-Stack)

## Sommaire

- [Code source](#code-source)
- [Exécution des tests](#exécution-des-tests)
- [Images Docker](#images-docker)
- [Orchestration Docker Compose](#orchestration-docker-compose)
- [CI/CD (GitHub Actions)](#cicd-github-actions)
- [Matrice des commandes clés](#matrice-des-commandes-clés)

MicroCRM est une application de démonstration basique ayant pour être objectif de servir de socle pour le module "P7 - Développeur Full-Stack".

L'application MicroCRM est une implémentation simplifiée d'un ["CRM" (Customer Relationship Management)](https://fr.wikipedia.org/wiki/Gestion_de_la_relation_client). Les fonctionnalités sont limitées à la création, édition et la visualisations des individus liés à des organisations.

![Page d'accueil](./misc/screenshots/screenshot_1.png)
![Édition de la fiche d'un individu](./misc/screenshots/screenshot_2.png)

## Code source

### Organisation

Ce [monorepo](https://en.wikipedia.org/wiki/Monorepo) contient les 2 composantes du projet "MicroCRM":

- La partie serveur (ou "backend"), en Java SpringBoot 3;
- La partie cliente (ou "frontend"), en Angular 17.

### Démarrer avec les sources

#### Serveur

##### Dépendances

- [OpenJDK >= 17](https://openjdk.org/)

##### Procédure

1. Se positionner dans le répertoire `back` avec une invite de commande:

   ```shell
   cd back
   ```

2. Construire le JAR:

   ```shell
   # Sur Linux
   ./gradlew build

   # Sur Windows
   gradlew.bat build
   ```

3. Démarrer le service:

   ```shell
   java -jar build/libs/microcrm-0.0.1-SNAPSHOT.jar
   ```

Puis ouvrir l'URL http://localhost:8080 dans votre navigateur.

#### Client

##### Dépendances

- [NPM >= 10.2.4](https://www.npmjs.com/)

##### Procédure

1. Se positionner dans le répertoire `front` avec une invite de commande:

   ```shell
   cd front
   ```

2. (La première fois seulement) Installer les dépendances NodeJS:

   ```shell
   npm install
   ```

3. Démarrer le service de développement:

   ```shell
   npx @angular/cli serve
   ```

Puis ouvrir l'URL http://localhost:4200 dans votre navigateur.

### Exécution des tests

#### Client

**Dépendances**

- Google Chrome ou Chromium

Dans votre terminal:

```shell
cd front
CHROME_BIN=</path/to/google/chrome> npm test
```

#### Serveur

Dans votre terminal:

```shell
cd back
./gradlew test
```

### Images Docker

#### Client

##### Construire l'image

```shell
docker build --target front -t orion-microcrm-front:latest .
```

##### Exécuter l'image

```shell
docker run -it --rm -p 80:80 -p 443:443 orion-microcrm-front:latest
```

L'application sera disponible sur https://localhost.

#### Serveur

##### Construire l'image

```shell
docker build --target back -t orion-microcrm-back:latest .
```

##### Exécuter l'image

```shell
docker run -it --rm -p 8080:8080 orion-microcrm-back:latest
```

L'API sera disponible sur http://localhost:8080.

#### Tout en un

```shell
docker build --target standalone -t orion-microcrm-standalone:latest .
```

##### Exécuter l'image

```shell
docker run -it --rm -p 8080:8080 -p 80:80 -p 443:443 orion-microcrm-standalone:latest
```

L'application sera disponible sur https://localhost et l'API sur http://localhost:8080.

### Orchestration Docker Compose

L'application complète (front + back) peut être lancée avec Docker Compose:

```shell
docker compose up --build
```

Accès:

- Frontend: http://localhost
- Backend API: http://localhost:8080

Arrêt:

```shell
docker compose down
```

## CI/CD (GitHub Actions)

Les workflows sont définis dans:

- `.github/workflows/ci.yml`
- `.github/workflows/release.yml`

### Workflow CI (`ci.yml`)

Déclenchement:

- `pull_request`
- `push` sur les branches (hors tags `v*`)

Étapes:

1. Build + tests backend (Gradle)
2. Build + tests frontend (npm + Karma/Chrome Headless)
3. Analyse SonarQube Cloud + Quality Gate bloquant (obligatoire)
4. Validation de sécurité des images Docker avec Trivy (informatif, non bloquant)
5. Validation de démarrage via `docker compose up --build`

Important:

- `ci.yml` ne publie pas d'image sur GHCR.

### Workflow Release (`release.yml`)

Déclenchement:

- Push de tag `vX.Y.Z` (ex: `v1.4.0`)

Règles:

1. Vérifie qu'un run `ci.yml` est en succès sur le SHA du tag (`github.sha`).
2. Vérifie le format du tag (`vMAJOR.MINOR.PATCH`).
3. Build des artefacts (JAR + build Angular)
4. Build des images Docker (`back`, `front`)
5. Push GHCR (uniquement ici)
6. Création de la GitHub Release et attachement des artefacts
7. Rollback automatique en cas d'échec: suppression de la release (si créée) puis suppression du tag

### Configuration GitHub requise

Secrets:

- `SONAR_TOKEN` (pour SonarQube Cloud)
- `SONAR_PROJECT_KEY`
- `SONAR_ORGANIZATION`

## Matrice des commandes clés

| Commande | Objectif | Définie dans | Exécutée quand |
| --- | --- | --- | --- |
| `./gradlew --no-daemon clean build` | Build + tests backend | `ci.yml` | CI |
| `npm run build` | Build frontend | `ci.yml`, `release.yml` | CI, Release |
| `npm test -- --watch=false --browsers=ChromeHeadlessNoSandbox --code-coverage` | Tests frontend + coverage | `ci.yml` | CI |
| `docker compose up --build -d` | Vérifier démarrage app complète | `ci.yml` | CI |
| `docker build --target back/front ...` | Construire images Docker | `release.yml` | Release |
| Trivy (`aquasecurity/trivy-action`) | Scanner vulnérabilités images | `ci.yml` | CI |
| `docker push ghcr.io/...` | Publier images conteneurisées | `release.yml` | Release |
