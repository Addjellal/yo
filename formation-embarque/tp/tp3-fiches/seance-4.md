# TP 3 — Fiche de séance 4 : interface opérateur WinCC (3 h)

## En-tête pédagogique

| | |
|---|---|
| **Objectifs** | Créer des vues HMI ; lier des objets aux variables API ; boutons à impulsion ; champs bornés par niveau utilisateur ; alarmes |
| **Prérequis** | Séance 3 : les 7 scénarios verts |
| **Outils** | TIA Portal + WinCC Basic + PLCSIM |
| **Livrable** | 3 vues, scénarios 2/3/6 rejoués depuis l'écran |

## Déroulé minuté

### 0:00-0:20 — Ajouter le pupitre

« Ajouter un appareil » → pupitre KTP700 Basic. La liaison PROFINET avec la
CPU se crée dans la vue réseau (relie les deux ports). Les variables HMI se
lieront directement aux tags API du projet.

### 0:20-1:10 — Vue « Conduite »

Objets à poser (bibliothèque WinCC) :
- **Boutons Marche/Arrêt** : événement « Appuyer » → mise à 1, « Relâcher »
  → mise à 0 sur `DB_IHM.marche_demandee`. ⚠️ **Bouton à impulsion, jamais
  bistable.** Rappel du TD 07 : si la liaison HMI tombe pendant qu'un bouton
  « reste à 1 », l'ordre reste bloqué. La logique de maintien vit dans
  l'automate (l'auto-maintien de `FC_Modes`), pas dans l'écran.
- **Synoptique** : un rectangle « convoyeur » qui change de couleur selon
  `KM1`, une « bouteille » sous le « bec », le bec animé par `YV1`.
- **Texte d'état dynamique** : afficher « Remplissage 3/12 » via un champ
  qui concatène `compteur` et `taille_lot`. Le mieux : un champ texte dont
  la visibilité dépend de `etape` (un texte par état).
- **Voyant mode** : AUTO/MANU selon S5.

**Point de conception** : le voyant convoyeur doit refléter le **retour
réel** (idéalement un contact auxiliaire du contacteur), pas la recopie de
la commande. Un voyant qui montre « ce qu'on a demandé » masque les pannes
(contacteur collé/décollé). Dans ce TP simplifié on a KM1 = commande, mais
énonce la limite.

### 1:10-1:50 — Vue « Réglages »

- Champ d'E/S numérique pour `temps_remplissage_ms` : **limites 2000-10000
  déclarées** dans les propriétés du champ (l'automate revalide de son côté
  — défense en profondeur, cf. scénario 7 de la séance 3).
- Champ pour `taille_lot` : limites 1-99.
- **Protection par niveau utilisateur** : crée un utilisateur « Régleur »
  avec mot de passe ; la vue Réglages exige ce niveau. Un opérateur ne
  modifie pas les recettes — c'est de la conception, pas du luxe.

### 1:50-2:30 — Vue « Alarmes »

1. Créer les **alarmes TOR** : dans « Alarmes IHM », une ligne par défaut
   (AU, bourrage) déclenchée sur le bit correspondant, classe « Errors »,
   texte explicite (« Défaut bourrage — dégager la cellule S4 »).
2. Le lot terminé : classe « Warnings » (info, pas erreur).
3. Poser une **fenêtre des alarmes** sur la vue + un **bouton
   d'acquittement**.
4. Texte utile : « Arrêt d'urgence actif — déverrouiller puis acquitter »
   vaut mieux que « Défaut 3 ».

### 2:30-2:55 — Test intégré HMI + PLCSIM

Lance la **simulation du pupitre** (WinCC) en parallèle de PLCSIM. Rejoue
**depuis l'écran** (plus depuis la table de forçage) :
- Scénario 2 : régler lot=3 dans Réglages, lancer, voir « x/3 » évoluer,
  H2 et l'alarme « lot terminé » à la fin.
- Scénario 3 : déclencher l'AU (force S3=0 dans PLCSIM), voir l'alarme
  monter, acquitter après réarmement.
- Scénario 6 : provoquer le bourrage, vérifier alarme + voyant.

**✅ Point de contrôle** : les 3 scénarios se pilotent et s'observent
entièrement depuis l'IHM, alarmes acquittables.

### 2:55-3:00 — Livrables et barème final

Remplis la grille /20 du TP principal
([tp3-siemens-remplissage.md](../tp3-siemens-remplissage.md)) avec preuves
(captures des 3 vues, du déroulé de recette). Commit/archive du projet.

## Erreurs fréquentes

| Symptôme | Cause | Remède |
|---|---|---|
| Bouton marche « collant » (reste actif) | bouton bistable au lieu d'impulsion | événements Appuyer/Relâcher |
| Consigne acceptée hors borne | limites déclarées seulement côté HMI | borner AUSSI dans l'automate |
| Alarme jamais affichée | bit de déclenchement mal lié, ou classe muette | vérifier le tag et la fenêtre d'alarmes |
| Réglages modifiables par tous | pas de niveau utilisateur | protéger la vue par « Régleur » |
| Synoptique figé | variable HMI non actualisée (cycle d'acquisition) | vérifier la liaison et le cycle |

## Bilan du TP 3

Tu as mené un mini-projet d'automatisme complet : analyse → E/S → GRAFCET →
programme structuré → recette de test → IHM. **Cette méthode est
indépendante de la marque** : le TP 4 (Schneider) applique la même démarche
sur EcoStruxure. Ce que tu retiens ici (sorties centralisées, sécurité en
aval, boutons à impulsion, recette écrite) est valable partout.

➡️ Retour : **[TP 3 (vue d'ensemble)](../tp3-siemens-remplissage.md)** ·
**[Module 08 — Schneider](../../cours/08-schneider.md)**
