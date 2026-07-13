# TP 3 — Fiche de séance 3 : mise au point sous PLCSIM (2 h)

> **Règle d'or : la recette de test s'écrit AVANT de tester.** Sinon on
> « bidouille jusqu'à ce que ça marche » sans jamais savoir si tout marche.

## En-tête pédagogique

| | |
|---|---|
| **Objectifs** | Simuler sans automate ; forcer des entrées ; dérouler une recette de test systématique ; corriger sans régression |
| **Prérequis** | Séance 2 : projet compilé, FB_Defauts fait |
| **Outils** | TIA Portal + PLCSIM |
| **Livrable** | Recette de 7 scénarios déroulée, colonne OK datée |

## Déroulé minuté

### 0:00-0:15 — Lancer la simulation

1. « Démarrer la simulation » → PLCSIM s'ouvre, charge le programme.
2. Mettre la CPU en RUN.
3. Ouvrir la table de visualisation `Visu_Cycle` en mode « surveiller »
   (lunettes). C'est ton tableau de bord.

Dans PLCSIM, tu forces les %I (les capteurs) à la main puisqu'il n'y a pas
de vraie machine. Pense à **S3 (AU) = 1** au départ (NF : 1 = OK).

### 0:15-0:35 — Écrire la recette (livrable 4)

Avant de forcer quoi que ce soit, remplis ce tableau :

| # | Scénario | Actions | Résultat attendu | OK ? |
|---|---|---|---|---|
| 1 | Cycle nominal | marche, puis S4 pulsé | 10→20→30→10, compteur +1 | |
| 2 | Lot de 3 | lot=3, 3 passages | étape 40, H2 allumé | |
| 3 | AU en remplissage | S3→0 pendant étape 20 | YV1 ET KM1 tombent < 1 cycle | |
| 4 | Réarmement sans acquit | S3→1 seul | rien ne repart | |
| 5 | Réarmement complet | S3→1 puis S6 | cycle reprend | |
| 6 | Bourrage | S4 maintenu 16 s hors remplissage | H1, défaut mémorisé | |
| 7 | Consigne hors borne | temps=99 s via table | borné à 10 s | |

### 0:35-1:40 — Dérouler la recette

Scénario par scénario, dans PLCSIM :

**Scénario 1** — force `marche_demandee`=1 (ou pulse S1) : `etape` passe à
10, KM1 s'allume. Pulse S4 (1 puis 0) : `etape`→20, YV1 s'allume, la tempo
tourne. Après le temps réglé : `etape`→30, tempo 1 s, puis compteur=1 et
retour à 10. **Coche OK ou note l'écart.**

**Scénario 3 (le plus important)** — pendant l'étape 20 (YV1 allumé), force
S3→0. Attendu : dans le cycle suivant, YV1 **et** KM1 retombent, H1
s'allume, la mémoire de défaut est posée. Vérifie sur la table que les deux
sorties sont bien à 0. C'est la vérif de sécurité : un défaut qui ne coupe
pas les sorties est éliminatoire.

**Scénario 7** — depuis la table, écris `temps_remplissage_ms` = 99000
(99 s). Le programme doit le **borner à 10000** (10 s max). Si ton
`FC_Modes`/`FB_Sequence` ne borne pas, tu viens de trouver un bug : ajoute
le bornage (`IF temps > 10000 THEN temps := 10000`).

### 1:40-1:55 — Corriger sans régression

Chaque écart trouvé → correction → **re-déroule TOUTE la recette** (pas
seulement le scénario qui bloquait). Une correction du scénario 7 peut
casser le 1. C'est la discipline « non-régression » : le vrai coût d'un bug
est dans les bugs qu'introduit sa correction.

**✅ Point de contrôle** : les 7 scénarios verts, colonne OK datée. Prends
une capture d'écran de la table de visu pour le scénario 3 (preuve de la
coupure sécurité).

### 1:55-2:00 — Commit + journal

Note dans ton journal : combien d'itérations recette → correction ? Quel bug
t'a le plus surpris ? (souvent : le bornage de consigne ou le réarmement).

## Erreurs fréquentes

| Symptôme | Cause | Remède |
|---|---|---|
| Rien ne démarre | S3 (AU, NF) oublié à 1 | forcer S3=1 au départ |
| S4 déclenche 2 remplissages | pas de front sur S4, ou S4 resté à 1 | remettre S4 à 0 après pulse |
| AU coupe mais tout repart seul au relâché | réarmement automatique | exiger S6 |
| Consigne 99 s appliquée | pas de bornage | ajouter `IF > max THEN = max` |
| PLCSIM « déconnecté » | CPU pas en RUN, ou recompilation non rechargée | recharger dans l'appareil |

## Travail à la maison (30 min)

Ajoute un **8ᵉ scénario** à ta recette : que se passe-t-il si S4 reste
collé à 1 (cellule masquée en permanence) ? Le bourrage doit se déclencher
15 s après une bouteille non évacuée. Vérifie-le et documente.

➡️ Fiche suivante : **[Séance 4 — HMI WinCC](seance-4.md)**
