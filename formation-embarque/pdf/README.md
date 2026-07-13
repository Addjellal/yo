# PDF de la formation

Versions PDF illustrées de toute la formation, générées depuis les fichiers
Markdown avec mise en page soignée (couverture, code colorisé, tableaux,
schémas SVG). Pour régénérer : `python3 _build/build_pdf.py`.

## Recueils (à lire en priorité)

| Fichier | Contenu |
|---|---|
| **RECUEIL-cours-complet.pdf** | Les 11 modules de cours (00 à 10) en un seul document |
| **RECUEIL-TD-corriges.pdf** | Les 10 travaux dirigés corrigés |
| **RECUEIL-TP-complets.pdf** | Les 5 TP + leurs 18 fiches de séance minutées |

## Documents individuels

Chaque fichier `.md` de la formation a aussi son PDF individuel (nom aplati :
`td__td-01-langage-c.pdf`, `tp__tp1-fiches__seance-1.pdf`, etc.).

- **Cours** : `00-fondamentaux.pdf` … `10-stm32.pdf`
- **TD** : `td__td-NN-*.pdf`
- **TP** : `tp__tpN-*.pdf` et fiches `tp__tpN-fiches__seance-*.pdf`
- **Évaluations** : `evaluations__qcm.pdf`, `evaluations__projets-notes.pdf`
- **Méta** : `README.pdf` (guide), `guide-formateur.pdf`

## Schémas inclus

Les cours et le QCM sont illustrés de schémas vectoriels (dossier
[`../figures/`](../figures/)) : poids des bits, blocs d'un microcontrôleur,
trames UART/I2C/SPI, PWM, chaîne de compilation, pointeurs, opérations de
bits, machine à états, combinatoire/séquentiel VHDL, cycle automate, GRAFCET,
LADDER, arbre d'horloges STM32, modes DMA, sur-échantillonnage UART, chaîne
Modbus. Ces SVG s'affichent aussi directement dans les `.md` sur GitHub.

> Note : les PDF sont un export. La **source** reste le Markdown — corrige le
> `.md`, puis relance le build pour régénérer le PDF correspondant.
