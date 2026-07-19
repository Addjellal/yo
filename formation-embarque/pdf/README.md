# PDF de la formation

Versions PDF illustrées de toute la formation, générées depuis les fichiers
Markdown (couverture, code colorisé, tableaux, schémas SVG). Pour régénérer
après une modification des sources : `python3 _build/build_pdf.py`.

## Organisation — un dossier par type de document

| Dossier | Contenu | Par où commencer |
|---|---|---|
| [`0-recueils/`](0-recueils/) | Les 4 volumes fusionnés : **cours complet**, **TD corrigés**, **TP complets**, **évaluations** | ⭐ ici, pour lire d'une traite |
| [`1-cours/`](1-cours/) | Les 11 modules de cours (`00-fondamentaux.pdf` … `10-stm32.pdf`) | module 00 |
| [`2-td/`](2-td/) | Les 10 travaux dirigés corrigés (`td-00-…` à `td-10-…`) | après chaque cours |
| [`3-mini-tp/`](3-mini-tp/) | Les mini-TP **sur simulateur** (programmes à trous, 15-30 min) + la fiche des **liens des simulateurs** | entre le cours et le TD |
| [`4-tp/`](4-tp/) | Les 5 TP (`tp1-…` à `tp5-…`) et leurs fiches de séance (`tp1-seance-1.pdf`, …) | TP 1 après le module 03 |
| [`5-evaluations/`](5-evaluations/) | `qcm.pdf`, les **épreuves pratiques par plateforme** (`eval-*.pdf`) et `projets-notes.pdf` (sujets /100) | QCM après chaque module |
| [`6-guides/`](6-guides/) | Guide de la formation (syllabus), guide du formateur, guide du code | selon ton rôle |

Le préfixe numérique des dossiers reflète l'ordre de lecture naturel.

## Schémas inclus

Les cours et le QCM sont illustrés de schémas vectoriels (sources dans
[`../figures/`](../figures/)) : poids des bits, blocs d'un microcontrôleur,
trames UART/I2C/SPI, PWM, chaîne de compilation, pointeurs, opérations de
bits, machine à états, combinatoire/séquentiel VHDL, cycle automate, GRAFCET,
LADDER, arbre d'horloges STM32, modes DMA, sur-échantillonnage UART, chaîne
Modbus. Ces SVG s'affichent aussi directement dans les `.md` sur GitHub.

> Note : les PDF sont un **export**. La source reste le Markdown — corrige le
> `.md` puis relance le build pour régénérer le PDF correspondant.
