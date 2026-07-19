# Évaluation pratique — Siemens TIA Portal (3 h, sur PLCSIM)

> Épreuve **sans automate** : TIA Portal + PLCSIM. Documents autorisés.
> Rendu : l'archive projet TIA + la **recette de test remplie et datée** +
> captures des tables de visualisation aux moments clés.
> Spécificité automate : la **démarche** (E/S → GRAFCET → blocs → recette)
> est notée autant que le fonctionnement — un programme qui marche sans
> dossier d'analyse plafonne à 10/20.

## Sujet — Portail coulissant automatique

Un portail motorisé : ouverture/fermeture par moteur 2 sens (`%Q0.0`
ouvre, `%Q0.1` ferme), fins de course ouvert/fermé (`%I0.2`, `%I0.3`),
cellule de sécurité (`%I0.4`, **NF** : 1 = passage libre), badge (`%I0.0`),
arrêt d'urgence (`%I0.1`, NF).

Comportement : badge → ouverture complète → tempo 10 s → fermeture auto.
Pendant la fermeture, cellule coupée → **réouverture immédiate**. Défaut
« moteur » si un mouvement dure > 15 s sans atteindre sa fin de course
(surveillance de mouvement). AU et réarmement selon les règles du TD 07.

## Travail demandé et barème

| # | Livrable | Points |
|---|---|---|
| 1 | **Avant tout code** : liste d'E/S (avec NO/NF justifiés) + GRAFCET papier/photo | /4 |
| 2 | Structure : `FB_Sequence` (SCL, CASE fidèle au GRAFCET), `FB_Defauts`, `FC_Sorties` **seul écrivain des %Q**, verrouillage croisé ouvre/ferme | /5 |
| 3 | Surveillance de mouvement 15 s (TON) + position de repli argumentée en commentaire (le portail s'arrête ? rouvre ?) | /3 |
| 4 | **Recette écrite PUIS déroulée** sous PLCSIM : ≥ 8 scénarios dont AU en mouvement, cellule en fermeture, badge pendant fermeture, défaut moteur | /5 |
| 5 | Réarmement conforme : disparition cause **ET** acquit — testé (scénario dédié) | /2 |
| 6 | Table de visualisation propre (étape, E/S, tempos) — capture | /1 |

**Seuil : 14/20.** Éliminatoires : les deux sorties moteur actives ensemble
(à n'importe quel instant de n'importe quel scénario), ou une sécurité
implémentée dans la séquence au lieu d'en aval.

## Question orale (ajuste ±2)

« La cellule tombe en panne débranchée (fil coupé). Que fait ton
portail ? » — la réponse doit découler du choix NF de la liste d'E/S,
pas d'une réflexion improvisée.
