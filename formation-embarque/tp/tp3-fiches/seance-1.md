# TP 3 — Fiche de séance 1 : analyse fonctionnelle (2 h)

> **Aucune ligne de code cette séance.** En automatisme, 40 % du travail est
> l'analyse. Un GRAFCET juste rend le codage trivial ; un GRAFCET bâclé rend
> le codage impossible. C'est la séance la plus importante du TP.

## En-tête pédagogique

| | |
|---|---|
| **Objectifs** | Rédiger une liste d'E/S ; tracer un GRAFCET point de vue partie commande ; analyser les défauts avec leurs conditions de réarmement |
| **Prérequis** | Module 07 en entier ; TD 07 (auto-maintien, front, GRAFCET) |
| **Outils** | Papier/crayon (ou draw.io) ; TIA Portal pas encore nécessaire |
| **Livrable** | 3 documents : liste d'E/S, GRAFCET, analyse de défauts |

## Rappel du cahier des charges

Ligne de remplissage de bouteilles : convoyeur → cellule détecte la
bouteille sous le bec → arrêt convoyeur, électrovanne ouverte pendant un
temps réglable (2-10 s) → 1 s de stabilisation → convoyeur repart. Compteur
de lot réglable ; lot atteint → arrêt + message + acquittement. Modes
AUTO/MANU. Défauts : bourrage (cellule occupée > 15 s hors remplissage),
arrêt d'urgence (NF câblé).

## Déroulé minuté

### 0:00-0:40 — Livrable 1 : la liste d'E/S

C'est le contrat entre le programme et l'armoire électrique. Complète ce
tableau (repère, description, type, adresse, actif) :

| Repère | Description | Type | Adresse | Actif |
|---|---|---|---|---|
| S1 | BP Marche | DI | %I0.0 | NO |
| S2 | BP Arrêt | DI | %I0.1 | NO |
| S3 | Arrêt d'urgence | DI | %I0.2 | **NF** |
| S4 | Cellule bouteille présente | DI | %I0.3 | NO |
| S5 | Sélecteur AUTO/MANU | DI | %I0.4 | — |
| S6 | BP Acquit défauts | DI | %I0.5 | NO |
| KM1 | Moteur convoyeur | DO | %Q0.0 | — |
| YV1 | Électrovanne remplissage | DO | %Q0.1 | — |
| H1 | Voyant défaut | DO | %Q0.2 | — |
| H2 | Voyant lot terminé | DO | %Q0.3 | — |

Questions à trancher (note tes choix) :
- L'arrêt d'urgence : pourquoi NF et pas NO ? *(fil coupé = sécurité
  déclenchée — sécurité positive)*
- Faut-il un capteur « carton/bec en position » ? Pour ce CdC simplifié,
  non — mais énonce l'hypothèse.

### 0:40-1:30 — Livrable 2 : le GRAFCET

Trace le GRAFCET point de vue partie commande (les actions = les sorties,
les transitions = les capteurs) :

```
 ┌──────────────┐
 │ 0  Attente   │  (convoyeur arrêté, vanne fermée)
 └──────┬───────┘
        ┼ S1·auto·aucun_defaut
 ┌──────┴───────┐
 │ 10 Convoyage │  N: KM1
 └──────┬───────┘
        ┼ S4  (bouteille détectée sous le bec)
 ┌──────┴───────┐
 │ 20 Remplissage│ N: YV1 ; lancer tempo T_remplissage (réglable)
 └──────┬───────┘
        ┼ tempo_remplissage.Q
 ┌──────┴───────┐
 │ 30 Stabilise │  tempo 1 s ; P1: compteur := compteur + 1
 └──┬────────┬──┘
    │        │
    ┼(t·      ┼(t·compteur ≥ lot)
    │ compteur│
    │ < lot)  │
    │  ↑10    ▼
 ┌──────────────┐
 │ 40 Lot fini  │  N: H2 ; tout arrêté
 └──────┬───────┘
        ┼ S6 (acquit) → compteur := 0 → ↑0
```

Les 3 règles que le correcteur vérifie :
1. **Chaque transition est un événement observable** par un capteur ou une
   tempo. « La bouteille est pleine » n'est pas observable ici ; « la tempo
   est écoulée » l'est.
2. **Une seule étape active à la fois** dans cette séquence linéaire (pas de
   divergence ET).
3. Les **actions au franchissement** (incrément compteur : qualificatif P1)
   se distinguent des **actions continues** (N : maintenues tant que l'étape
   est active).

### 1:30-2:00 — Livrable 3 : l'analyse des défauts

Un tableau par défaut. C'est ici qu'on gagne ou perd des points en revue :

| Défaut | Détection | Action immédiate | Réarmement |
|---|---|---|---|
| Arrêt d'urgence | S3 = 0 (NF) | KM1 et YV1 coupés instantanément, mémorisation défaut | disparition (S3=1) **ET** S6 |
| Bourrage | S4 = 1 maintenu 15 s **hors** étapes 20/30 | KM1 coupé, défaut mémorisé | disparition cause **ET** S6 |
| (implicite) mode incohérent | changement AUTO↔MANU en cycle | à définir : figer ? revenir à l'étape 0 ? | ton choix argumenté |

Le point clé : **le réarmement n'est jamais automatique**. Disparition de la
cause **+** action volontaire de l'opérateur (S6). Une machine qui redémarre
seule après un AU est un danger (et hors norme).

**✅ Point de contrôle** : relis ton GRAFCET à voix haute comme si tu
l'expliquais à un collègue. Chaque transition doit se dire « quand [capteur]
alors [étape suivante] ». Si tu dois dire « quand c'est fini » sans nommer
de capteur, la transition est mal posée.

## Erreurs fréquentes

| Erreur | Pourquoi c'est faux | Correction |
|---|---|---|
| Transition « bouteille pleine » | pas de capteur de niveau dans le CdC | c'est la tempo qui décide |
| Incrément compteur en action N | il s'incrémenterait à chaque cycle automate (ms) | qualificatif P1 (au franchissement) |
| AU géré comme une transition du GRAFCET | l'AU doit agir depuis N'IMPORTE quel état | logique transversale, hors séquence |
| Réarmement = juste relâcher l'AU | redémarrage intempestif | exiger S6 en plus |

## Travail à la maison (30 min)

Ajoute au GRAFCET la gestion du **mode MANU** : soit une branche parallèle,
soit (mieux) une logique séparée hors GRAFCET qui court-circuite la
séquence. Réfléchis : en MANU, les sécurités (AU, verrouillages) restent-elles
actives ? *(réponse : oui, toujours — le mode manuel n'est pas un mode
« sans sécurité »)*.

➡️ Fiche suivante : **[Séance 2 — Programme structuré](seance-2.md)**
