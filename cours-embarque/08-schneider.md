# Module 08 — Suite Schneider Electric : EcoStruxure, Modicon et Modbus

> Schneider Electric est le grand concurrent français de Siemens — très
> présent en France (bâtiment, eau, énergie, machines). Bonne nouvelle :
> **90 % des concepts du module 07 se transposent tels quels** (cycle
> automate, IEC 61131-3, GRAFCET, HMI). Ce module se concentre sur ce qui
> change : les logiciels, le matériel Modicon, et **Modbus**, le protocole
> historique inventé par Modicon.

Prérequis : module 07 (les concepts d'automatisme n'y sont pas répétés).

---

## 1. La galaxie logicielle Schneider (s'y retrouver dans les noms)

Schneider a renommé toute son offre sous la marque **EcoStruxure** :

| Logiciel actuel | Ancien nom | Pour quels automates | Usage |
|---|---|---|---|
| **EcoStruxure Machine Expert** | SoMachine | M241, M251, M262, M258 | machines OEM |
| **EcoStruxure Machine Expert – Basic** | SoMachine Basic | **M221** | petites machines — **gratuit**, idéal débutant |
| **EcoStruxure Control Expert** | **Unity Pro** | M340, **M580**, Premium, Quantum | process, infrastructures |
| EcoStruxure Machine Expert HVAC / autres | — | M171/M172 | CVC |
| **Vijeo Designer** / EcoStruxure Operator Terminal Expert | — | écrans **Harmony** (ex-Magelis) | HMI |
| EcoStruxure Machine SCADA Expert / AVEVA | — | supervision | SCADA |

À noter : **Machine Expert est basé sur CODESYS**, la plateforme IEC 61131-3
utilisée par des dizaines de marques (Wago, Festo, Beckhoff-like…) — le
maîtriser te sert donc bien au-delà de Schneider.

**Par où commencer sans budget** :
- *Machine Expert Basic* : téléchargement gratuit, **simulateur intégré** —
  parfait pour débuter (cible M221).
- *Control Expert* : version d'essai ; son **simulateur PLC** remplace
  l'automate.
- *CODESYS* (codesys.com) : gratuit avec soft-PLC de démo — pour pratiquer
  l'IEC 61131-3 pur.

## 2. Le matériel Modicon

| Gamme | Positionnement | Équivalent Siemens approx. |
|---|---|---|
| **M221** | micro-automate machines simples | S7-1200 entrée de gamme / LOGO!+ |
| **M241 / M251 / M262** | machines, motion, IIoT (M262) | S7-1200/1500 |
| **M340** | process moyen | S7-300 / S7-1500 |
| **M580 (ePAC)** | process & infrastructures, redondance, cybersécurité | S7-1500 / 400H |
| Premium / Quantum | anciennes générations, encore en service | S7-400 |
| **ATV** (Altivar) | variateurs de vitesse | SINAMICS |
| **Harmony** (ex-Magelis) | écrans opérateurs | pupitres SIMATIC HMI |
| **Lexium** | servo/motion | SIMOTICS/SINAMICS S |
| Zelio Logic | relais programmable | LOGO! |

### Adressage mémoire (différent de Siemens — à connaître)

Notation IEC « % » avec localisation :

- `%I0.3` : entrée TOR 3 ; `%Q0.2` : sortie TOR 2 (M221 : `%I0.x`/`%Q0.x`).
- `%M10` : bit interne 10 ; `%MW100` : **mot interne** 100 (16 bits) ;
  `%MD100` : double mot ; `%MF100` : flottant.
- `%IW1.0` : mot d'entrée analogique.
- `%S`/`%SW` : bits/mots **système** (ex. `%S6` = clignotant 1 s sur M221).
- Sur Control Expert / Machine Expert on privilégie les **variables
  symboliques** (comme chez Siemens) ; les `%MW` restent centraux pour les
  échanges **Modbus** (voir §5).

## 3. Programmer : les 5 langages IEC 61131-3, version Schneider

Les langages sont les mêmes qu'au module 07 — seuls l'éditeur et quelques
blocs changent.

### 3.1 LADDER (LD)

Le marche/arrêt auto-maintenu s'écrit à l'identique. Blocs standard :

- Temporisateurs : `TON`, `TOF`, `TP` (IEC) — sur M221 : blocs `%TMi` en
  mode TON/TOF/TP avec préréglage `%TMi.P`.
- Compteurs : `CTU/CTD/CTUD` — sur M221 : `%Ci`.
- Fronts : contacts `P` et `N` directement dans le barreau.
- Comparaison/opération : blocs de comparaison `[%MW10 > 100]` et
  d'opération `[%MW20 := %MW10 * 2]` insérables dans les barreaux (très
  pratique, typiquement Schneider).

### 3.2 Texte structuré (ST)

Identique au SCL de Siemens (c'est la même norme) :

```pascal
(* Régulation de niveau, version Schneider ST *)
IF niveau < consigne - hysteresis THEN
    pompe := TRUE;
ELSIF niveau > consigne + hysteresis THEN
    pompe := FALSE;
END_IF;

(* Accès direct possible aux mots mémoire *)
%MW200 := REAL_TO_INT(debit * 10.0);

FOR i := 0 TO 9 DO
    somme := somme + mesures[i];
END_FOR;
```

### 3.3 FBD, IL, et **SFC/GRAFCET**

- **FBD** : identique dans l'esprit.
- **SFC** : Control Expert dispose d'un **véritable éditeur GRAFCET**
  (héritage Telemecanique — c'est historiquement l'automate « français ») :
  étapes, transitions, divergences ET/OU, actions qualifiées (N, S, R, L, D).
  Sur M221 (Machine Expert Basic), pas d'éditeur SFC : on code le GRAFCET
  en LADDER (un bit par étape) ou avec les bits d'étape `%Xi` selon gamme.
- **DFB** (Derived Function Block, Control Expert) = le FB Siemens : bloc
  utilisateur avec variables internes, instanciable — même logique
  « classe/objet ».

### 3.4 Structure d'un projet

- **Machine Expert (Basic)** : tâche maître cyclique (`MAST`), sections/POU
  organisées ; configuration matérielle par onglets (modules, E/S, réseau).
- **Control Expert** : tâches `MAST` (cyclique ou périodique), `FAST`
  (rapide), événementielles ; sections par langage ; variables globales
  typées ; DFB ; écrans d'exploitation intégrés (mini-HMI de mise au point).
- Tables d'animation = watch tables Siemens (visualiser/forcer).

## 4. HMI Harmony et Vijeo Designer

Même démarche que WinCC :
1. Choisir le pupitre (Harmony ST6, GTU…), créer les **panneaux** (écrans).
2. Variables liées à l'automate (Modbus TCP en général — souvent adressées
   directement en `%MW`).
3. Objets : boutons, voyants, bargraphes, courbes, tableaux d'alarmes,
   recettes, multi-langue, niveaux d'utilisateurs.
4. Simulation sur PC, puis transfert par Ethernet/USB.

Pour les gros systèmes : AVEVA (ex-Wonderware, partenaire de Schneider) —
InTouch/System Platform — côté SCADA.

## 5. Modbus : LE protocole à maîtriser (né chez Modicon en 1979)

Simple, ouvert, omniprésent — des variateurs aux compteurs d'énergie. Deux
transports :

- **Modbus RTU** : trame binaire sur **RS-485** (2 fils, multipoint, jusqu'à
  ~1200 m). Maître unique qui interroge des esclaves (adresse 1–247).
- **Modbus TCP** : la même chose encapsulée dans TCP/IP port **502**.

### 5.1 Le modèle de données

| Zone | Type | Fonctions usuelles |
|---|---|---|
| Coils | bits lecture/écriture | 01 (lire), 05/15 (écrire) |
| Discrete inputs | bits lecture seule | 02 |
| **Holding registers** | mots 16 bits R/W | **03 (lire), 06/16 (écrire)** |
| Input registers | mots 16 bits lecture | 04 |

Sur un Modicon, les holding registers correspondent naturellement aux
`%MW` : « lire 10 registres à l'adresse 100 » = lire `%MW100..%MW109`.
C'est pour ça que les échanges HMI/SCADA/supervision Java (module 05 §7.1)
se câblent si vite sur du Schneider.

### 5.2 Pièges classiques

- Décalage d'adresse « +1 » (adresse protocole 0 = registre « 40001 » des
  vieilles documentations).
- Ordre des mots pour les 32 bits (deux registres : lequel en premier ?
  dépend de l'équipement — « word swap »).
- RS-485 : polarisation et résistances de terminaison, vitesse/parité
  identiques partout.
- Un seul maître en RTU ; en TCP, attention au nombre de connexions.

### 5.3 À côté de Modbus

- **CANopen** : historique machines Schneider (M241/M251 en maître).
- **EtherNet/IP** et **OPC UA** : M262/M580 vers l'IT et l'IIoT.
- **IO-Link** : capteurs intelligents.

## 6. Siemens vs Schneider : synthèse pour ta culture (et tes entretiens)

| | Siemens | Schneider |
|---|---|---|
| IDE | TIA Portal | Machine Expert / Control Expert |
| CPU phare | S7-1200 / S7-1500 | M221-M262 / M580 |
| Réseau maison | PROFINET / PROFIBUS | Modbus TCP / Ethernet-IP / CANopen |
| HMI | WinCC | Vijeo / Harmony |
| ST s'appelle | SCL | ST |
| FB + données | FB + DB d'instance | DFB (Control Expert) / FB CODESYS |
| GRAFCET | S7-GRAPH (option) | SFC natif Control Expert |
| Simulateur | PLCSIM | simulateur intégré / soft-PLC CODESYS |
| Forces terrain | industrie manufacturière, Allemagne/monde | bâtiment, eau, énergie, France |

Sur le marché de l'emploi français en automatisme, exiger « TIA Portal
**ou** Unity/Control Expert » est la norme — qui a compris l'un apprend
l'autre en quelques semaines. Ce qui compte : IEC 61131-3, GRAFCET, Modbus,
lecture de schémas électriques, méthode de mise en service.

## 7. Parcours d'apprentissage Schneider

1. Installe **Machine Expert Basic** (gratuit) → cible M221 simulée.
2. Refais tous les exercices LADDER du module 07 (auto-maintien,
   télérupteur, chenillard `%TM`, comptage `%C`).
3. Ajoute la dimension Modbus : depuis un PC, lis/écris les `%MW` du
   simulateur avec un client Modbus gratuit (QModMaster, mbpoll) — puis
   depuis un script Python (`pymodbus`) ou ton programme Java (module 05).
4. Essaie **Control Expert** (essai) : reprends le feu tricolore en **SFC
   natif**, crée un **DFB** de moyenne glissante, joue avec les tables
   d'animation.
5. Mini-projet : gestion de cuve (remplissage/vidange, 2 pompes alternées
   pour user les deux également, sécurité niveau très haut câblée, alarmes,
   écran Harmony simulé, supervision des `%MW` en Modbus TCP).
6. Ressources : documentation Schneider (excellente, souvent en français),
   chaînes YouTube d'automatisme francophones, forums (Automation Sense,
   PLCtalk).

## Exercices

1. M221 simulé : démarrage étoile/triangle d'un moteur (2 contacteurs,
   temporisation 5 s, verrouillage mutuel impératif).
2. ST : bloc `Alternance_Pompes` — à chaque demande, démarre la pompe la
   moins utilisée (compteurs d'heures en `%MD`), avec report si défaut.
3. Modbus : table d'échange documentée (10 mots : états, mesures,
   commandes, mot de vie) + lecture depuis `mbpoll` ou `pymodbus`.
4. GRAFCET SFC : cycle de lavage (prélavage 2 min → lavage 5 min → rinçage
   ×2 → essorage), pause/reprise, abandon avec vidange sécurisée.

➡️ Termine par **[Module 09 — Parcours & ressources](09-parcours-et-ressources.md)**.
