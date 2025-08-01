# Notes de Frais - Documentation Technique

## Description Générale
Cette application est une solution complète pour la gestion des notes de frais, de la capture des justificatifs à leur exportation. Elle est conçue pour être flexible et adaptable à différents cas d'utilisation grâce à une architecture modulaire et une stratégie de branches spécifique.

## Table des Matières
1.  [Stratégie de Branches](#1-stratégie-de-branches)
2.  [Fonctionnalités Clés](#2-fonctionnalités-clés)
3.  [Architecture Technique](#3-architecture-technique)
4.  [Guide de Démarrage et Configuration](#4-guide-de-démarrage-et-configuration)
5.  [Dépendances Clés](#5-dépendances-clés)
6.  [Comment Contribuer](#6-comment-contribuer)

---

## 1. Stratégie de Branches

Le projet utilise une stratégie de branches pour gérer trois versions distinctes de l'application :

*   **`master`**: Il s'agit de la branche de base qui contient le tronc commun de fonctionnalités. Elle sert de fondation pour les autres versions et peut être considérée comme une version "vanilla" de l'application.

*   **`Employer`**: Cette branche est destinée aux employés du groupe Noalys. Elle ajoute des fonctionnalités spécifiques à un environnement d'entreprise, telles que :
    *   La gestion des frais kilométriques.
    *   Des paramètres avancés pour l'entreprise.
    *   La sécurisation de l'application par un code PIN.
    *   Une personnalisation de l'interface (logo, polices).
    *   Cette branche n'inclut pas l'export vers Google Sheets.

*   **`Switch`**: Cette version est une version "sur-mesure" conçue pour le PDG, M. Durousset. Elle combine les fonctionnalités de la branche `master` et `Employer` et y ajoute des fonctionnalités avancées de reporting et de visualisation de données :
    *   Fonctionnalités étendues dans les vues de validation et de résultats par lots.
    *   Services d'arrière-plan plus complexes pour l'envoi d'e-mails et la synchronisation.
    *   Réintroduction de l'export vers Google Sheets, probablement pour des rapports consolidés.

---

## 2. Fonctionnalités Clés

### Tronc Commun (`master`)

*   **Capture de justificatifs**: Prise de photo, sélection depuis la galerie ou importation de fichiers PDF.
*   **Extraction de données par IA**: Utilise le modèle `gemini-pro-vision` de Google pour extraire les informations pertinentes des justificatifs (montant, date, catégorie, etc.).
*   **Validation et correction manuelle**: Interface pour vérifier et corriger les données extraites par l'IA.
*   **Association à une entité/entreprise**: Permet de lier chaque dépense à une entité spécifique.
*   **Historique et corbeille**: Consultation de l'historique des dépenses et gestion d'une corbeille pour les éléments supprimés.
*   **Tableau de bord et statistiques**: Visualisation des dépenses par catégorie et par mois.

### Spécificités de la branche `Employer`

*   **Gestion des frais kilométriques**: Ajout et suivi des indemnités kilométriques.
*   **Sécurité renforcée**: Verrouillage de l'application par code PIN.
*   **Paramètres d'entreprise**: Configuration spécifique à l'entreprise.
*   **Compression d'images**: Optimisation de la taille des justificatifs.
*   **Gestion de la connectivité**: Vérification de la connexion réseau avant certaines opérations.

### Spécificités de la branche `Switch`

*   **Fonctionnalités de la branche `Employer`**: Inclut toutes les fonctionnalités de la branche `Employer`.
*   **Export Google Sheets**: Réintroduction de la fonctionnalité d'export vers Google Sheets.
*   **Fonctionnalités avancées de reporting**: Vues de validation et de résultats par lots plus riches et complexes pour l'analyse des données.
*   **Tâches d'arrière-plan étendues**: Services d'envoi d'e-mails et de synchronisation plus sophistiqués.

---

## 3. Architecture Technique

Le projet suit une architecture de type **MVC (Model-View-Controller)** :

*   **`models`**: Contient les objets de données de l'application, tels que `ExpenseModel`.
*   **`views`**: Contient les écrans de l'application, responsables de l'interface utilisateur.
*   **`controllers`**: Gère la logique métier et fait le lien entre les modèles et les vues.
*   **`services`**: Contient les services externes et internes, tels que l'accès à l'API de Gemini, l'envoi d'e-mails, etc.

### Services Principaux

*   **`AiService`**:
    *   **Rôle**: Interagit avec l'API `Google Generative AI`.
    *   **Modèle**: Utilise `gemini-pro-vision` pour l'analyse d'images et de texte.
    *   **Prompt**: Un prompt détaillé est utilisé pour extraire les informations suivantes des justificatifs : `Total TTC`, `Date`, `Catégorie`, `Nom du fournisseur`, `TVA`, `Description`.

*   **`GoogleSheetsService` (`master` et `Switch` uniquement)**:
    *   **Rôle**: Gère la connexion à Google Sheets et Google Drive.
    *   **Fonctionnalités**: Formate les données des dépenses et les téléverse sur une feuille de calcul Google Sheets, et sauvegarde les justificatifs sur Google Drive.

*   **`EmailService`**:
    *   **Rôle**: Gère la mise en forme et l'envoi d'e-mails.
    *   **Fonctionnalités**: Envoi d'e-mails individuels ou par lots, avec ou without les justificatifs en pièce jointe.

*   **`StorageService`**:
    *   **Rôle**: Gère le stockage local des données.
    *   **Technologie**: Utilise la base de données NoSQL `Hive` pour une persistance rapide et efficace des données.

*   **`BackgroundService` / `BackgroundTaskService`**:
    *   **Rôle**: Gère les tâches de fond de l'application.
    *   **Technologie**: Utilise le package `workmanager` pour exécuter des tâches telles que l'envoi d'e-mails et la synchronisation avec Google Sheets, même lorsque l'application est fermée.

---

## 4. Guide de Démarrage et Configuration

### Prérequis

*   Flutter SDK (version 3.2.0 ou supérieure)
*   Un éditeur de code (VS Code, Android Studio, etc.)

### Installation

1.  Clonez le dépôt :
    ```sh
    git clone https://github.com/Maxenss-Bonnet/notes_de_frais.git
    ```
2.  Accédez au répertoire du projet :
    ```sh
    cd notes_de_frais
    ```
3.  Installez les dépendances :
    ```sh
    flutter pub get
    ```

### Configuration de l'environnement

1.  Créez un fichier `.env` à la racine du projet.
2.  Ajoutez les variables d'environnement suivantes :
    ```
    GEMINI_API_KEY=VOTRE_CLÉ_API_GEMINI
    SENDER_EMAIL=VOTRE_ADRESSE_EMAIL
    SENDER_PASSWORD=VOTRE_MOT_DE_PASSE_EMAIL
    ```

### Fichiers de service

*   Le fichier `assets/credentials.json` est nécessaire pour l'authentification auprès des services Google (Sheets et Drive). Assurez-vous d'avoir configuré un projet Google Cloud avec les API nécessaires et d'avoir généré les informations d'identification appropriées.
*   Sur la branche `Employer`, un fichier `assets/credentialsEmplyer.json` est utilisé.

---

## 5. Dépendances Clés

*   **`camera`**: Pour la capture de photos.
*   **`google_generative_ai`**: Pour l'interaction avec l'API Gemini.
*   **`hive` / `hive_flutter`**: Pour le stockage local.
*   **`mailer`**: Pour l'envoi d'e-mails.
*   **`workmanager`**: Pour la gestion des tâches de fond.
*   **`flutter_riverpod`** (branches `Employer` et `Switch`): Pour la gestion de l'état.
*   **`googleapis` / `googleapis_auth`**: Pour l'authentification et l'interaction avec les API Google.
*   **`fl_chart`**: Pour les graphiques et les statistiques.

---

## 6. Comment Contribuer

Nous accueillons les contributions ! Veuillez suivre les étapes suivantes :

1.  Forkez le projet.
2.  Créez une nouvelle branche pour votre fonctionnalité (`git checkout -b feature/ma-nouvelle-fonctionnalite`).
3.  Commitez vos changements (`git commit -am 'Ajout de ma nouvelle fonctionnalité'`).
4.  Pushez sur la branche (`git push origin feature/ma-nouvelle-fonctionnalite`).
5.  Ouvrez une Pull Request.
