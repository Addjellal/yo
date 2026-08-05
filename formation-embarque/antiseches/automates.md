# Antisèche — Automates (Siemens & Schneider)

## Le cycle automate

`lire les entrées (image figée) → exécuter le programme → écrire les sorties`
en boucle, 1-10 ms. **Conséquence n°1** : ton code est rejoué des centaines
de fois par seconde → sans **front**, un appui compte des centaines de fois.

## Adressage

| | Siemens (S7) | Schneider (Modicon) |
|---|---|---|
| Entrée bit | `%I0.0` | `%I0.0` |
| Sortie bit | `%Q0.0` | `%Q0.0` |
| Bit interne | `%M0.0` | `%M0` |
| Mot interne | `%MW20` | `%MW20` |
| Mot d'entrée ana. | `%IW64` | `%IW0.0` |
| Double mot / réel | `%MD20` / Real | `%MD20` / `%MF20` |
| Temporisation | FB `TON` + DB | `%TM0` |
| Compteur | FB `CTU` + DB | `%C0` |
| Système | — | `%S6` (1 Hz), `%SW` |

## LADDER — les symboles

```
──┤ ├──  contact NO (vrai si bit = 1)      ──( )──  bobine
──┤/├──  contact NF (vrai si bit = 0)      ──(S)──  set (mémorise 1)
──┤P├──  front montant (1 cycle)           ──(R)──  reset (mémorise 0)
──┤N├──  front descendant
```

### Marche/arrêt auto-maintenu (LE motif)

```
  marche      arret      defaut     moteur
 ──┤ ├────────┤/├────────┤/├────────( )──
  moteur │
 ──┤ ├───┘        ← contact de maintien en parallèle
```

### Verrouillage mutuel (2 sens, étoile/triangle…)

```
  cmd_av    ar     ...    av           cmd_ar    av    ...    ar
 ──┤ ├──────┤/├──────────( )──        ──┤ ├──────┤/├──────────( )──
```
Chaque sortie interdit l'autre — **et aussi en câblé** pour les risques de
court-circuit (le logiciel seul ne suffit jamais).

## Temporisations IEC

| Bloc | Comportement |
|---|---|
| `TON` | Q passe à 1 **après** PT de IN vrai (retard à l'enclenchement) |
| `TOF` | Q retombe **PT après** que IN devienne faux |
| `TP` | impulsion calibrée de durée PT |

`CTU` (comptage), `CTD` (décomptage), `CTUD` : `PV` = consigne, `Q` = atteint.

## SCL / ST (texte structuré)

```pascal
:=  affectation        =  <>  <  >  <=  >=  comparaisons
AND OR NOT XOR         MOD  ABS  SQRT

IF a > b THEN ... ELSIF ... ELSE ... END_IF;
FOR i := 0 TO 9 DO ... END_FOR;
WHILE cond DO ... END_WHILE;
CASE etape OF 0: ... 10: ... ELSE ... END_CASE;

#var        // variable locale du bloc (Siemens)
"DB".var    // variable globale/DB (Siemens)
T#2s500ms   // littéral de temps
INT_TO_REAL(x)  REAL_TO_INT(x)  DINT_TO_TIME(ms)   // conversions explicites
```

### Hystérésis (anti-battement) — à recopier

```pascal
IF mesure < consigne - bande THEN sortie := TRUE;
ELSIF mesure > consigne + bande THEN sortie := FALSE;
END_IF;   // entre les deux : on n'écrit RIEN, la sortie garde son état
```

### GRAFCET en CASE (quand pas d'éditeur SFC)

```pascal
CASE #etape OF
  0:  IF depart THEN #etape := 10; END_IF;
  10: sortie_A := TRUE;
      IF capteur THEN #etape := 20; END_IF;
  20: #tempo(IN := TRUE, PT := T#5s);
      IF #tempo.Q THEN #tempo(IN := FALSE); #etape := 0; END_IF;
END_CASE;
```

## Blocs Siemens

| | Rôle |
|---|---|
| `OB1` | cycle principal · `OB100` démarrage · `OB3x` cyclique |
| `FC` | fonction **sans mémoire** |
| `FB` + DB d'instance | fonction **avec mémoire** (≈ classe + objet) |
| `DB` | bloc de données global |

Schneider : `DFB` (Control Expert) ≈ FB ; sections dans la tâche `MAST`.

## Modbus

| Zone | Lecture | Écriture |
|---|---|---|
| Coils (bits R/W) | **01** | 05 (un), 15 (plusieurs) |
| Discrete inputs (bits R) | **02** | — |
| **Holding registers** (mots R/W) | **03** | 06 (un), 16 (plusieurs) |
| Input registers (mots R) | **04** | — |

- **RTU** : RS-485, 1 maître, esclaves 1-247, mêmes vitesse/parité partout,
  terminaisons aux extrémités.
- **TCP** : port **502**, adresse = numéro de mot (`%MW100` → registre 100).
- Pièges : décalage « 40001 » des vieilles docs · ordre des mots pour les
  32 bits (*word swap*) · **toujours borner** ce que le PC écrit.
- **Mot de vie** : compteur incrémenté par l'automate, surveillé par le PC —
  seule preuve que le programme tourne (une liaison TCP ouverte ne prouve rien).

## Les règles de sûreté (non négociables)

1. **Arrêt d'urgence en NF** (sécurité positive : fil coupé = déclenché).
2. **Réarmement volontaire** : disparition de la cause **ET** acquit opérateur.
3. **Une seule section écrit les sorties**, et la sécurité y est **en aval** :
   `KM1 := (auto OR manu) AND aucun_defaut;`
4. **Surveillance de mouvement** : pas de fin de course atteinte en N s → défaut.
5. **La sécurité ne vit jamais dans l'IHM** ni dans une séquence qui peut se
   bloquer.
6. Bouton HMI **à impulsion** ; le maintien appartient à l'automate.
7. L'état de repli se déduit du **risque du procédé** (couper le chauffage,
   mais ventiler à fond).
