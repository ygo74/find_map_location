# Feature Specification: Carte avec Carroyage Alphanumérique

**Feature Branch**: `004-grid-overlay`
**Created**: 2025-12-16
**Updated**: 2025-12-27
**Status**: Completed
**Input**: User description: "Carroyage paramétrable sur carte OpenStreetMap avec numérotation alphanumérique pour localiser l'adresse recherchée. Taille des cases configurable (défaut 500m)"

## Clarifications

### Session 2025-12-16

- Q: Positionnement de l'origine de la grille (lettre A, ligne 1) → A: Origine calculée pour centrer la grille sur le centre de la ville sélectionnée
- Q: Style visuel de mise en évidence de la case contenant l'adresse → A: Aucune mise en évidence automatique - le but du jeu est que l'utilisateur trouve lui-même la case correspondant à l'adresse
- Q: Options de taille de cases prédéfinies ou saisie libre → A: Liste de valeurs prédéfinies uniquement (250m, 500m, 1000m, 2000m)
- Q: Comportement du carroyage lors de recherches d'adresses successives → A: Le carroyage reste fixe et couvre toute la ville seulement (pas de déplacement)
- Q: Règle de décision lorsqu'une adresse est exactement sur une ligne de séparation → A: Règle de priorité géographique nord-ouest (l'adresse appartient à la case supérieure-gauche)

### Session 2025-12-27

- Q: Étendue de la grille → A: La grille couvre uniquement la zone de la ville (rayon de 5km par défaut autour du centre)
- Q: Navigation sur la carte → A: La carte est bloquée aux limites de la ville pour empêcher l'utilisateur de sortir de la zone de jeu
- Q: Alignement de la grille → A: La grille s'aligne sur les limites de la ville (coin nord-ouest des limites) pour une couverture optimale

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Affichage du Carroyage sur la Carte (Priority: P1)

L'utilisateur visualise la carte avec un carroyage superposé composé de cases carrées de taille uniforme. Chaque case est identifiée par une combinaison de lettres (colonnes) et de chiffres (lignes), similaire à une grille de tableur Excel (A1, A2, B1, B2, etc.).

**Why this priority**: C'est le cœur de la fonctionnalité. Sans l'affichage du carroyage, aucune autre fonctionnalité ne peut fonctionner. Cette story livre une valeur immédiate en permettant aux utilisateurs de visualiser comment la carte est divisée.

**Independent Test**: Peut être testé en lançant l'application et en vérifiant visuellement que la grille s'affiche sur la carte avec les identifiants alphanumériques corrects.

**Acceptance Scenarios**:

1. **Given** l'utilisateur ouvre la carte, **When** la carte est chargée avec une ville sélectionnée, **Then** une grille de cases carrées de 500m est superposée sur la carte
2. **Given** le carroyage est affiché, **When** l'utilisateur se déplace sur la carte, **Then** les identifiants des cases (lettres pour colonnes, chiffres pour lignes) sont clairement visibles
3. **Given** le carroyage est affiché, **When** l'utilisateur zoome sur la carte, **Then** la grille reste alignée avec les coordonnées géographiques et les cases maintiennent leur taille de 500m
4. **Given** le carroyage est affiché, **When** l'utilisateur dézoome pour voir une zone plus large, **Then** davantage de cases deviennent visibles tout en conservant la numérotation cohérente

---

### User Story 2 - Défi de Localisation de la Case (Priority: P2)

Lorsqu'une adresse est recherchée et localisée sur la carte, l'utilisateur doit deviner dans quelle case de la grille se trouve cette adresse. Le système ne met PAS en évidence automatiquement la case - c'est le défi du jeu. L'utilisateur peut vérifier sa réponse en demandant la solution.

**Why this priority**: Cette fonctionnalité constitue le cœur du mécanisme de jeu/défi. Elle transforme la recherche d'adresse en une activité ludique où l'utilisateur doit analyser la carte et le carroyage pour localiser l'adresse.

**Independent Test**: Peut être testé en recherchant une adresse et en vérifiant que le système calcule correctement l'identifiant de la case mais ne la révèle pas automatiquement.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a recherché une adresse, **When** l'adresse est trouvée et affichée sur la carte, **Then** le marqueur de l'adresse est visible mais aucune case n'est mise en évidence automatiquement
2. **Given** une adresse est localisée, **When** l'utilisateur observe la carte, **Then** il peut voir le carroyage et le marqueur d'adresse pour déterminer visuellement la case correspondante
3. **Given** l'utilisateur souhaite vérifier sa réponse, **When** il demande la solution (via un bouton dédié), **Then** le système affiche l'identifiant de la case correcte (ex: "C7")
3. **Given** le carroyage a été initialisé pour une ville, **When** l'utilisateur recherche une nouvelle adresse dans la même ville, **Then** le carroyage reste fixe et couvre toute la zone de la ville
4. **Given** le carroyage est affiché, **When** l'utilisateur tente de déplacer la carte en dehors des limites de la ville, **Then** la carte reste bloquée aux limites définies

---

### User Story 3 - Configuration de la Taille des Cases (Priority: P3)

L'utilisateur peut modifier la taille des cases du carroyage depuis les paramètres de l'application. La taille par défaut est de 500 mètres, mais l'utilisateur peut choisir d'autres valeurs (par exemple 250m, 1000m, 2000m) selon le niveau de difficulté souhaité.

**Why this priority**: Cette fonctionnalité ajoute de la flexibilité et permet d'adapter le niveau de difficulté du jeu. Elle est moins critique que l'affichage de base et peut être ajoutée après.

**Independent Test**: Peut être testé en accédant aux paramètres, en modifiant la taille des cases, et en vérifiant que le carroyage est redessiné avec la nouvelle taille.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est dans l'écran des paramètres, **When** il accède à la section de configuration du carroyage, **Then** il voit une liste de choix prédéfinis (250m, 500m, 1000m, 2000m) avec la valeur actuelle sélectionnée (500m par défaut)
2. **Given** l'utilisateur sélectionne la taille 1000m dans la liste, **When** il retourne à la carte, **Then** le carroyage est redessiné avec des cases de 1000m et la numérotation est ajustée en conséquence
3. **Given** l'utilisateur change la taille des cases, **When** le carroyage est redessiné, **Then** les proportions restent carrées et l'alignement avec les coordonnées géographiques est préservé
4. **Given** l'utilisateur a modifié la taille des cases, **When** il ferme et rouvre l'application, **Then** le paramètre personnalisé est conservé

---

### Edge Cases

- Lorsque l'adresse recherchée se trouve exactement sur la ligne de séparation entre deux cases, le système applique la règle de priorité nord-ouest (l'adresse appartient à la case située au nord et/ou à l'ouest)
- Comment le système gère-t-il la numérotation lorsque la carte couvre plus de 26 colonnes (nécessitant AA, AB, AC, etc.)?
- Que se passe-t-il si l'utilisateur configure une taille de case très petite (ex: 50m) sur une vue très large (risque de surcharge de rendu)?
- Comment le carroyage s'affiche-t-il aux pôles ou dans des zones avec des projections cartographiques particulières?
- Que se passe-t-il si aucune ville n'est sélectionnée et que l'utilisateur essaie d'activer le carroyage?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT superposer une grille de cases carrées sur la carte OpenStreetMap affichée
- **FR-002**: Le système DOIT utiliser une taille de case par défaut de 500 mètres (500m × 500m)
- **FR-003**: Le système DOIT numéroter les colonnes de la grille avec des lettres (A, B, C, etc.) et les lignes avec des chiffres (1, 2, 3, etc.)
- **FR-003a**: Le système DOIT calculer l'origine de la grille (case A1) en l'alignant sur les limites de la ville sélectionnée (coin nord-ouest)
- **FR-003b**: Le système DOIT maintenir la grille fixe pour couvrir uniquement la zone de la ville sélectionnée
- **FR-003c**: Le système DOIT calculer les limites de la ville avec un rayon de 5km autour du centre de la ville par défaut
- **FR-004**: Le système DOIT afficher les identifiants alphanumériques (lettres + chiffres) pour chaque case de manière lisible sur la carte
- **FR-005**: Le système DOIT calculer dans quelle case se trouve une adresse recherchée (sans révélation automatique à l'utilisateur)
- **FR-005a**: Le système DOIT appliquer une règle de priorité nord-ouest lorsqu'une adresse se trouve exactement sur une ligne de séparation (l'adresse appartient à la case située au nord et/ou à l'ouest)
- **FR-006**: Le système DOIT fournir un mécanisme (bouton "Afficher la solution") permettant à l'utilisateur de révéler volontairement l'identifiant de la case contenant l'adresse
- **FR-006a**: Le système NE DOIT PAS mettre en évidence automatiquement la case lors de la recherche d'une adresse (préserver l'aspect défi)
- **FR-007**: L'utilisateur DOIT pouvoir accéder à un paramètre permettant de modifier la taille des cases du carroyage
- **FR-008**: Le système DOIT proposer une liste de tailles de cases prédéfinies: 250m, 500m, 1000m, 2000m (pas de saisie libre)
- **FR-009**: Le système DOIT persister le paramètre de taille de case choisi par l'utilisateur entre les sessions
- **FR-010**: Le système DOIT maintenir l'alignement géographique correct du carroyage lors des opérations de zoom et de déplacement sur la carte
- **FR-011**: Le système DOIT gérer la numérotation des colonnes au-delà de Z en utilisant AA, AB, AC, etc.
- **FR-012**: Le système DOIT recalculer et redessiner le carroyage lorsque l'utilisateur change la taille des cases dans les paramètres
- **FR-013**: Le système DOIT restreindre la navigation de la carte aux limites de la ville pour empêcher l'utilisateur de sortir de la zone de jeu
- **FR-014**: Le système DOIT définir des niveaux de zoom minimum (12) et maximum (18) appropriés pour la visualisation de la grille
- **FR-015**: Le système DOIT aligner la grille sur les limites calculées de la ville pour une couverture optimale de la zone de jeu

### Key Entities

- **Case de Grille**: Représente une cellule individuelle du carroyage, identifiée par une colonne (lettre) et une ligne (chiffre). Possède des coordonnées géographiques (coins nord-ouest et sud-est) et une dimension (en mètres).
- **Configuration de Carroyage**: Représente les paramètres du carroyage, notamment la taille des cases (en mètres), l'état d'activation/désactivation, et les préférences d'affichage.
- **Point d'Adresse**: Représente la position géographique d'une adresse recherchée. Utilisé pour déterminer dans quelle case de grille se situe l'adresse.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Les utilisateurs peuvent identifier visuellement le carroyage sur la carte dès le premier chargement avec une ville sélectionnée
- **SC-002**: Le système identifie correctement la case contenant une adresse recherchée dans 100% des cas testés (y compris les cas de bordure avec la règle nord-ouest)
- **SC-003**: Les utilisateurs peuvent modifier la taille des cases et voir le carroyage mis à jour en moins de 3 secondes
- **SC-004**: Le carroyage reste visuellement cohérent et aligné lors de 20 opérations consécutives de zoom/déplacement sur la carte
- **SC-005**: Les identifiants de cases (alphanumériques) sont lisibles à tous les niveaux de zoom standards (du niveau ville au niveau quartier)
