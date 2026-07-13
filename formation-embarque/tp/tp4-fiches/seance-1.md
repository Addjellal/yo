# TP 4 — Fiche de séance 1 : programme M221 (3 h)

## En-tête pédagogique

| | |
|---|---|
| **Objectifs** | Créer un projet Machine Expert Basic ; mise à l'échelle analogique ; régulation à hystérésis ; alternance de pompes ; chien de garde capteur |
| **Prérequis** | Module 08 ; TD 08 exercices 1-2 ; TP 3 terminé (la méthode n'est pas répétée) |
| **Outils** | EcoStruxure Machine Expert – Basic (gratuit) + simulateur M221 |
| **Livrable** | Programme M221 régulant une cuve, testé au simulateur |

## Rappel du cahier des charges

Cuve avec mesure de niveau analogique 0-10 V (`%IW0.0`, 0..1000 brut = 0-100 %),
deux pompes de remplissage à hystérésis (départ < 40 %, arrêt > 60 %) avec
alternance selon l'usure, vanne de soutirage, sécurités (niveau très haut
> 90 %, très bas < 5 %, capteur figé > 30 s).

## Déroulé minuté

### 0:00-0:20 — Projet et configuration

1. Nouveau projet → TM221CE16R (version Ethernet, pour le Modbus de la
   séance 2).
2. Onglet configuration : régler l'entrée analogique 0-10 V, adresse IP
   192.168.1.50 (le simulateur l'émule).
3. **Table de symboles** complète AVANT le code (réflexe du TP 3) :
   `NIVEAU_POURMILLE` (%MW10), `CMD_P1` (%Q0.0), `CMD_P2` (%Q0.1),
   `VANNE` (%Q0.2), `DEF_CAPTEUR` (%M20), `DEMANDE_REMPLIR` (%M0).

### 0:20-0:40 — Mise à l'échelle

`%IW0.0` (0..1000) → `%MW10` en pour-mille (0..1000 = 0..100,0 %). Sur M221,
un bloc opération dans une section « Échelle » :

```
%MW10 := %IW0.0    (ici 1:1 ; si le module rend 0..27648, faire une règle de 3)
```

Convention (TD 08) : entiers ×10, pas de flottants. `470` = 47,0 %.

### 0:40-1:30 — Régulation à hystérésis (LADDER)

Section « Régulation », avec blocs comparaison :

```
  [%MW10 < 400]   %M1(anti-rebond?)              DEMANDE_REMPLIR
 ──┤     ├──────────────────────────┬───────────────(S)──
  [%MW10 > 600]                                  DEMANDE_REMPLIR
 ──┤     ├──────────────────────────────────────────(R)──
```

Départ sous 40 %, arrêt au-dessus de 60 % : la bande morte de 20 points
évite que les pompes « battent » autour d'un seuil unique (même principe que
l'hystérésis du thermostat Arduino, TD 03). La demande est une **bascule
Set/Reset**.

### 1:30-2:20 — Alternance des pompes

Machine Expert Basic n'a pas de FB utilisateur : implémente l'alternance
(TD 08 exercice 2) en LADDER + mots. Logique :
- `%MW30` = heures P1, `%MW31` = heures P2 (compteurs d'usure).
- Au **front montant** de `DEMANDE_REMPLIR` : choisir la pompe la moins usée
  (`%M10` = « choix P1 » si `%MW30 <= %MW31`).
- Commandes : `CMD_P1 = DEMANDE_REMPLIR AND choix_P1 AND NOT def_P1`,
  symétrique pour P2.
- Comptage : un `%TM` cadencé à 1 s (ou le bit système `%S6`) incrémente le
  compteur de la pompe en marche.

Documente ton choix d'implémentation (LADDER vs liste d'instructions) dans
le journal — les deux sont acceptés, l'important est que ce soit lisible.

### 2:20-2:45 — Chien de garde capteur

Le plus subtil : détecter un capteur figé. Un niveau immobile est **normal**
si rien ne bouge — il n'est anormal que si une pompe tourne ou la vanne est
ouverte et que le niveau ne varie pas.

```
Condition d'armement : (CMD_P1 OU CMD_P2 OU VANNE) ET |%MW10 - %MW_precedent| < 2
Si maintenue 30 s (%TM à 30 s) → DEF_CAPTEUR
Remise à zéro du %TM dès que le niveau varie de ±2
```

Mémorise `%MW10` dans `%MW11` à chaque scrutation pour comparer.

### 2:45-3:00 — Sécurités (section la plus en aval)

Comme au TP 3 : **une seule section écrit les %Q**, en dernier, avec la
sécurité intégrée :
- `%MW10 > 900` → `CMD_P1 = CMD_P2 = 0` (interdiction de remplir).
- `%MW10 < 50` → `VANNE = 0` (protéger la pompe aval).
- `DEF_CAPTEUR` → tout à l'état sûr.

**✅ Point de contrôle** : au simulateur, pilote `%IW0.0` à la souris.
Vérifie : hystérésis (départ sous 40, arrêt à 60), alternance visible d'un
cycle au suivant (les heures P1/P2 s'équilibrent), niveau haut prioritaire.

## Erreurs fréquentes

| Symptôme | Cause | Remède |
|---|---|---|
| Pompes qui papillonnent | pas d'hystérésis (seuil unique) | bande morte 40/60 |
| Toujours la même pompe | choix non figé au front, ou pas de comptage | choisir au front montant |
| DEF_CAPTEUR permanent | armement sans condition « qqchose bouge » | armer seulement si pompe/vanne active |
| Niveau haut ignoré | sécurité pas en aval | section sorties en dernier |
| %MW10 aberrant | mise à l'échelle du module non faite | vérifier plage brute réelle |

## Travail à la maison (30 min)

Ajoute la gestion du **report sur défaut** : si la pompe choisie tombe en
défaut pendant le remplissage, basculer sur l'autre (si elle est saine). Et
l'alarme « aucune pompe disponible » si les deux sont en défaut. C'est
l'exercice 2 du TD 08 dans son intégralité.

➡️ Fiche suivante : **[Séance 2 — Table Modbus](seance-2.md)**
