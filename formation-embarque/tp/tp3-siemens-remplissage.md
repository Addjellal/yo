# TP 3 — Station de remplissage sous TIA Portal + PLCSIM (≈ 10 h, en 4 séances)

> **Objectif pédagogique** : mener un mini-projet d'automatisme **dans les
> règles de l'art** : analyse fonctionnelle → liste d'E/S → GRAFCET → blocs
> structurés → HMI → recette de test. C'est la démarche qu'on te demandera
> en bureau d'études, pas seulement « faire marcher ».
>
> 📋 **Fiches minutées séance par séance** :
> [Séance 1 — Analyse](tp3-fiches/seance-1.md) ·
> [Séance 2 — Programme](tp3-fiches/seance-2.md) ·
> [Séance 3 — PLCSIM](tp3-fiches/seance-3.md) ·
> [Séance 4 — HMI](tp3-fiches/seance-4.md).

## Outils

TIA Portal (essai 21 jours ou licence école) avec **PLCSIM** et **WinCC
Basic**. CPU projet : S7-1214C DC/DC/DC (ou n'importe quelle 1200/1500 —
PLCSIM simule tout).

## Cahier des charges (le client dit :)

Une ligne remplit des bouteilles :

1. Un **convoyeur** amène les bouteilles. Une **cellule** détecte la
   bouteille sous le bec.
2. Bouteille en place → convoyeur stoppé, **électrovanne** ouverte pendant
   le **temps de remplissage réglable** (2 à 10 s, réglé depuis l'écran).
3. Vanne fermée → 1 s de stabilisation → le convoyeur repart.
4. Un **compteur de lot** : l'opérateur règle la taille du lot (ex. 12) ;
   lot atteint → la ligne s'arrête, message « lot terminé », repart après
   acquittement.
5. Modes **AUTO / MANU** (en MANU : commandes directes convoyeur et vanne,
   avec les sécurités actives).
6. Défauts : **bourrage** (cellule occupée > 15 s hors remplissage),
   **arrêt d'urgence** (NF câblé). Tout défaut → arrêts sûrs + voyant +
   alarme HMI + acquittement obligatoire.

---

## Séance 1 (2 h) — Analyse (aucune ligne de code)

### Livrable 1 : liste d'E/S

À produire en tableau — en voici le début, complète-le :

| Repère | Description | Type | Adresse | Actif |
|---|---|---|---|---|
| S1 | BP Marche | DI | %I0.0 | NO |
| S2 | BP Arrêt | DI | %I0.1 | NO |
| S3 | Arrêt d'urgence | DI | %I0.2 | **NF** |
| S4 | Cellule bouteille présente | DI | %I0.3 | NO |
| S5 | Sélecteur AUTO/MANU | DI | %I0.4 | — |
| S6 | BP Acquit défauts | DI | %I0.5 | NO |
| KM1 | Convoyeur | DO | %Q0.0 | — |
| YV1 | Électrovanne remplissage | DO | %Q0.1 | — |
| H1 | Voyant défaut | DO | %Q0.2 | — |

### Livrable 2 : GRAFCET de production (papier/dessin)

Trace le GRAFCET point de vue partie commande. Attendu :

```
 0 Attente     (convoyeur arrêté)
   ┼ marche ET auto ET aucun_defaut
10 Convoyage   N: KM1
   ┼ S4 (bouteille détectée)
20 Remplissage N: YV1 ; tempo T_remplissage (réglable)
   ┼ tempo écoulée
30 Stabilisation ; tempo 1 s ; P1: compteur := compteur + 1
   ┼ tempo écoulée ET compteur <  taille_lot  → retour 10
   ┼ tempo écoulée ET compteur >= taille_lot  → 40
40 Lot terminé (tout arrêté, message)
   ┼ acquit → remise compteur à 0 → 0
```

### Livrable 3 : analyse des défauts

Pour **chaque** défaut, un tableau : détection, action immédiate, condition
de réarmement. (Bourrage : `S4 ET NOT étape 20/30` maintenu 15 s ; action :
KM1 et YV1 coupés ; réarmement : disparition cause + S6.)

**✅ Point de contrôle 1** : fais relire ton GRAFCET à quelqu'un (ou
relis-le à 24 h d'écart) : chaque transition doit être une condition
*observable par un capteur* — « la bouteille est pleine » n'est pas un
capteur, « la tempo est écoulée » oui.

---

## Séance 2 (3 h) — Programme structuré

Crée le projet, la CPU, la table de variables (celle du livrable 1 +
`%M`/DB). Structure **imposée** des blocs :

| Bloc | Type | Rôle |
|---|---|---|
| `Main [OB1]` | OB | appelle les FC/FB dans l'ordre, RIEN d'autre |
| `FC_Modes` | FC | calcule `auto_actif`, `manu_actif`, demande marche/arrêt (auto-maintien) |
| `FB_Defauts` | FB | AU, bourrage (TON 15 s), mémorisation, acquit → `aucun_defaut` |
| `FB_Sequence` | FB | le GRAFCET en SCL (`CASE #etape OF`) |
| `FC_Sorties` | FC | **seul bloc qui écrit %Q** : combine séquence + MANU + défauts |
| `DB_IHM` | DB global | tout ce que voit/écrit l'écran : consignes, états, compteur |

Points imposés (et pourquoi) :

1. **Un seul bloc écrit les sorties** (`FC_Sorties`). Quand un technicien
   cherchera « pourquoi KM1 ne tourne pas », il ouvrira UN réseau. Sorties
   éparpillées = projet inmaintenable (et double affectation = bug sournois :
   dernière écriture gagne).
2. La coupure de sécurité est **en dernier**, dans `FC_Sorties` :
   `KM1 := (cmd_auto OR cmd_manu) AND aucun_defaut AND NOT au_declenche` —
   quelle que soit la fantaisie de la séquence, un défaut coupe.
3. La séquence en SCL suit le GRAFCET **étape pour étape**, avec les
   numéros du dessin en commentaire. Le dessin est le document de
   référence ; le code n'est que sa traduction.

Extrait attendu de `FB_Sequence` (à compléter) :

```pascal
CASE #etape OF
    0: // Attente
        IF "DB_IHM".marche_demandee AND #auto AND #aucun_defaut THEN
            #etape := 10;
        END_IF;
    10: // Convoyage
        IF "S4_bouteille" THEN #etape := 20; END_IF;
    20: // Remplissage
        #t_rempli(IN := TRUE,
                  PT := DINT_TO_TIME("DB_IHM".temps_remplissage_ms));
        IF #t_rempli.Q THEN
            #t_rempli(IN := FALSE);
            #etape := 30;
        END_IF;
    // ... 30 et 40 : à toi ...
END_CASE;
```

**✅ Point de contrôle 2** : compilation sans erreur ni avertissement, et
une **table de visualisation** `Visu_Cycle` préparée avec : étape, %I, %Q,
compteur, tempo.

---

## Séance 3 (2 h) — Mise au point sous PLCSIM

Recette de test **écrite avant de tester** (livrable 4) — modèle :

| # | Scénario | Actions (forçages) | Résultat attendu | OK ? |
|---|---|---|---|---|
| 1 | Cycle nominal | marche, puis S4 pulsé | 10→20→30→10, compteur +1 | |
| 2 | Lot de 3 | taille_lot=3, 3 passages | étape 40, message | |
| 3 | AU en plein remplissage | S3→0 pendant étape 20 | YV1 ET KM1 retombent < 1 cycle, défaut mémorisé | |
| 4 | Réarmement sans acquit | S3→1 seul | rien ne repart | |
| 5 | Bourrage | S4 maintenu 16 s hors remplissage | défaut bourrage | |
| 6 | MANU | sélecteur MANU, cmd vanne | vanne suit la commande, sécurités actives | |
| 7 | Consigne hors bornes | temps=99 s depuis la table | borné à 10 s (le programme borne !) | |

Déroule-la dans PLCSIM en forçant les entrées depuis la table de
visualisation. **Chaque écart = correction + re-déroulé complet** de la
recette (une correction peut casser un scénario qui passait).

**✅ Point de contrôle 3** : les 7 scénarios verts, colonne OK datée.

---

## Séance 4 (3 h) — HMI WinCC

Ajoute un pupitre KTP700 Basic. Trois vues :

1. **Conduite** : synoptique (convoyeur, bec, bouteille), boutons
   Marche/Arrêt (à impulsion ! cf. TD 07 ex. 4), état en clair
   (« Remplissage 3/12 »), compteur de lot, voyant mode.
2. **Réglages** : temps de remplissage (champ borné 2-10 s) et taille de
   lot (1-99) — protégés par le niveau utilisateur « Régleur » (mot de
   passe), car un opérateur ne modifie pas les recettes.
3. **Alarmes** : fenêtre des alarmes TOR (AU, bourrage, lot terminé en
   classe « avertissement »), bouton d'acquittement.

Simule pupitre + PLCSIM ensemble et rejoue les scénarios 2, 3 et 5 **depuis
l'écran**.

---

## Livrables et barème

| Livrable | Points |
|---|---|
| Liste d'E/S + GRAFCET + analyse des défauts (séance 1) | /4 |
| Structure de blocs conforme, sorties centralisées, sécurité en aval | /5 |
| Séquence SCL fidèle au GRAFCET, tempos et compteur corrects | /4 |
| Recette de test écrite ET déroulée (7 scénarios) | /4 |
| HMI 3 vues, boutons à impulsion, consignes bornées, alarmes | /3 |
| **Total** | **/20** |

**Transfert de compétence** : cette démarche (analyse → E/S → GRAFCET →
structure → recette) est exactement celle du TP 4 côté Schneider — tu
constateras que 80 % du travail est indépendant de la marque.
