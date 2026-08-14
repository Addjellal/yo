# Cent propositions d'interface, soumises à la critique

Corpus soumis aux agents `critique-interface`. Cinq domaines de vingt, parce
que l'interface ne se réduit pas au dessin : ce qu'on tape, comment on se
déplace, ce que fait chaque bouton de la souris et ce que le logiciel répond
comptent autant que la mise en page.

Chaque proposition indique le logiciel dont elle s'inspire. Ce n'est pas un
programme de travail — c'est une matière à trier.

---

## A — Disposition, lisibilité, apparence (1-20)

1. **Panneau latéral unique à onglets** — composants, propriétés, hiérarchie dans une seule colonne repliable au lieu de trois zones fixes. *(KiCad 8, Altium)*
2. **Barre d'état permanente** — coordonnées du curseur, pas de grille, nœud sous le curseur, unité courante. *(KiCad, LTspice)*
3. **Grille adaptative** — le pas affiché s'éclaircit au dézoom pour ne pas noircir l'écran. *(Figma, Fusion)*
4. **Thème sombre complet**, y compris la feuille de schéma. *(KiCad 7+, VS Code)*
5. **Mode « présentation »** — masque tous les panneaux, ne laisse que le schéma, pour projeter en cours. *(PowerPoint, Inkscape en plein écran)*
6. **Survol qui met le net en surbrillance** — tous les fils du même nœud s'allument ensemble. *(Altium, KiCad)*
7. **Étiquettes de nœud affichées en permanence** sur option, pas seulement pendant la simulation. *(LTspice)*
8. **Composants hors circuit grisés** — ce qui n'est relié à rien se voit au premier coup d'œil. *(Proteus)*
9. **Épaisseur de fil selon le courant** pendant la simulation. *(Multisim, Falstad)*
10. **Miniature de navigation** en coin, avec le rectangle de la vue courante. *(Photoshop, Fusion)*
11. **Règles graduées** sur les bords, en millimètres pour le PCB. *(Inkscape, KiCad PCB)*
12. **Marqueur d'erreur ERC sur le schéma** — un rond rouge à l'endroit fautif, pas seulement une ligne de journal. *(KiCad, Altium)*
13. **Séparateur déplaçable** entre schéma et journal, avec mémoire de la position. *(VS Code)*
14. **Zone morte autour du schéma** pour attraper un composant en bord de feuille sans lutter contre le bord de fenêtre. *(Figma)*
15. **Icônes de composant dans la palette** plutôt qu'une liste de noms. *(Proteus, Fritzing)*
16. **Recherche instantanée dans la palette** avec filtrage à la frappe. *(VS Code, KiCad)*
17. **Aperçu du symbole au survol** dans la palette, avant de le poser. *(KiCad)*
18. **Regroupement visuel des instruments** — voltmètres, oscilloscope, analyseur dans une famille distincte. *(Multisim)*
19. **Indication de l'état de simulation dans le titre de la fenêtre** — arrêtée, en marche, en pause. *(navigateurs, VS Code)*
20. **Cartouche de schéma** — titre, auteur, date, version, imprimé avec la feuille. *(KiCad, Altium, norme)*

## B — Raccourcis clavier (21-40)

21. **`R` = rotation** du composant sélectionné ou en cours de pose. *(KiCad, Altium, Proteus)*
22. **`X` / `Y` = miroir** horizontal et vertical. *(KiCad)*
23. **`Suppr` = effacer la sélection**, `Retour arrière` idem. *(universel)*
24. **`Échap` = annuler le geste en cours** sans quitter l'outil. *(universel)*
25. **`Ctrl+Z` / `Ctrl+Maj+Z` = annuler / refaire**, avec pile illimitée. *(universel)*
26. **`Espace` = retourner la posture** du coude pendant qu'on tire un fil. *(Altium, KiCad)*
27. **`F5` = compiler**, `F9` = lancer, `F6` = pause, `F8` = arrêter. *(Visual Studio, Arduino IDE)*
28. **`Ctrl+D` = dupliquer** le composant sélectionné à côté. *(Inkscape, Figma)*
29. **`Ctrl+G` / `Ctrl+Maj+G` = grouper / dégrouper** un sous-ensemble du schéma. *(Inkscape, Figma)*
30. **`Ctrl+F` = chercher un composant par référence** et centrer la vue dessus. *(KiCad, VS Code)*
31. **`Tab` = passer au champ suivant** dans le panneau de propriétés, sans souris. *(universel)*
32. **`Ctrl+molette` = zoom**, `Maj+molette` = défilement horizontal. *(VS Code, navigateurs)*
33. **`Début` = recadrer sur tout le schéma**. *(KiCad : `Origine`)*
34. **`Ctrl+0` = zoom 100 %**, `Ctrl++` / `Ctrl+-`. *(navigateurs)*
35. **Touches `1`-`9` = poser directement le composant favori** de ce rang. *(Proteus, jeux)*
36. **`A` = ajouter un composant** (ouvre la palette avec le champ de recherche actif). *(KiCad : `A`)*
37. **`W` = commencer un fil** au curseur, pour ceux qui préfèrent le clavier. *(KiCad : `W`)*
38. **`Ctrl+E` = éditer les propriétés** du composant sélectionné. *(KiCad : `E`)*
39. **`M` = déplacer** au clavier, avec les flèches, pas de grille par pas. *(KiCad, Altium)*
40. **`?` ou `F1` = pense-bête des raccourcis** en superposition. *(Gmail, Figma, Slack)*

## C — Navigation, mobilité, sélection (41-60)

41. **Molette = défilement vertical**, `Ctrl+molette` = zoom. *(déjà fait ; à confirmer)*
42. **Bouton du milieu maintenu = déplacement de la vue**, partout et en toute circonstance. *(KiCad, Fusion, Blender)*
43. **Barre d'espace maintenue = déplacement temporaire** de la vue, comme la main. *(Photoshop, Figma)*
44. **Zoom centré sur le curseur**, jamais sur le centre de la fenêtre. *(Figma, Google Maps)*
45. **Zoom sur la sélection** par une touche dédiée. *(Inkscape : `3`)*
46. **Rectangle de sélection de gauche à droite = englobant**, de droite à gauche = touchant. *(AutoCAD, Altium)*
47. **`Ctrl+A` = tout sélectionner**, `Ctrl+Maj+A` = désélectionner. *(universel)*
48. **`Ctrl+clic` = ajouter à la sélection**, `Maj+clic` = étendre. *(universel)*
49. **`Alt+clic` = sélectionner l'objet en dessous** quand plusieurs se superposent. *(Illustrator, Figma)*
50. **Clic répété au même endroit = parcourir les objets superposés**. *(Blender, AutoCAD)*
51. **Navigation au clavier entre composants** par `Tab`, avec surbrillance. *(accessibilité)*
52. **Défilement automatique quand on tire un fil au bord** de la fenêtre. *(Figma, Simulink)*
53. **Limites de déplacement souples** — on peut sortir de la feuille, mais un retour au cadre est proposé. *(Figma)*
54. **Signets de vue** — mémoriser deux ou trois cadrages et y revenir par une touche. *(Fusion, jeux de stratégie)*
55. **Vue scindée** — le même schéma dans deux volets, pour relier deux zones éloignées. *(VS Code, Excel)*
56. **Suivi du net** — sélectionner un nœud et sauter d'une de ses bornes à la suivante. *(Altium)*
57. **Retour en arrière de navigation** — `Alt+Gauche` revient au cadrage précédent. *(navigateurs, VS Code)*
58. **Aimantation à la grille désactivable temporairement** par une touche maintenue. *(Inkscape, Figma)*
59. **Alignement automatique sur les bornes voisines** avec lignes-guides pendant le déplacement. *(Figma, Simulink)*
60. **Un geste à deux doigts sur pavé tactile = déplacement**, pincement = zoom. *(macOS, portables)*

## D — Souris, clics, menus contextuels (61-80)

61. **Clic droit sur un composant = menu de ce composant**, pas le menu général. *(universel)*
62. **Clic droit sur un fil = couper ici / supprimer le net / changer de couleur**. *(Altium)*
63. **Clic droit dans le vide = coller, recadrer, réglages de grille**. *(KiCad)*
64. **Double-clic sur un composant = ouvrir ses propriétés**. *(universel)*
65. **Double-clic sur une valeur affichée = la modifier sur place**, sans dialogue. *(Excel, Figma)*
66. **Glisser-déposer depuis la palette vers le schéma**. *(Fritzing, Proteus)*
67. **Glisser un composant sur un fil = l'insérer en série**, le fil se coupe autour. *(Altium : *drop on wire*)*
68. **Glisser avec `Ctrl` = copier** au lieu de déplacer. *(universel)*
69. **Clic milieu sur un composant = le supprimer** (raccourci d'expert, optionnel). *(certains éditeurs)*
70. **Survol prolongé = infobulle** avec référence, valeur, nœuds et courant mesuré. *(Multisim)*
71. **Menu contextuel qui montre les raccourcis** en regard de chaque entrée. *(bonne pratique)*
72. **Clic sur une broche de carte = afficher son rôle** (numéro, PWM, ADC, interruption). *(Fritzing, Arduino)*
73. **Poignées de redimensionnement** sur les objets qui en admettent (cadres, texte). *(Figma)*
74. **Menu radial au clic droit maintenu** pour les gestes fréquents. *(Blender, Maya)*
75. **Clic droit sur le journal = copier / vider / filtrer**. *(consoles)*
76. **Poser plusieurs fois le même composant** tant qu'on n'a pas appuyé sur Échap. *(KiCad, Proteus)*
77. **Annuler un geste en cours par clic droit** pendant qu'on tire un fil. *(Proteus)*
78. **Poignée de déplacement distincte du corps** pour les composants dont le corps sert au câblage. *(Simulink)*
79. **Clic sur une mesure affichée = ouvrir l'instrument correspondant**. *(Multisim)*
80. **Glisser un fichier `.elf` sur la fenêtre = le charger** sur la carte sélectionnée. *(universel)*

## E — Retour d'information, erreurs, apprentissage (81-100)

81. **Journal filtrable** par gravité — tout, avertissements, erreurs seulement. *(VS Code)*
82. **Repli des lignes répétées** avec compteur. *(déjà fait ; à confirmer)*
83. **Erreur cliquable** — cliquer la ligne du journal sélectionne et centre le composant fautif. *(VS Code, KiCad)*
84. **Panneau ERC dédié**, séparé du journal, avec liste navigable. *(KiCad, Altium)*
85. **Bandeau non bloquant** pour les avertissements, au lieu d'une boîte de dialogue. *(VS Code, navigateurs)*
86. **Compteur d'anomalies dans la barre d'état**, cliquable. *(VS Code)*
87. **Marquage visuel des composants grillés** — déjà fait, à étendre aux ERC.
88. **Explication en une phrase de chaque erreur**, avec ce qu'il faut faire. *(Rust, Elm)*
89. **Contrôle continu en tâche de fond** plutôt qu'au seul lancement. *(VS Code, Altium)*
90. **Différence avant/après compilation** dans le journal, pour voir ce qui a changé.
91. **Progression visible** pendant la compilation et le routage. *(universel)*
92. **Annulation possible d'un routage long**. *(KiCad)*
93. **Exemples accessibles depuis un menu dédié**, classés par carte. *(Arduino IDE)*
94. **Premier lancement guidé** — un schéma d'exemple et trois flèches. *(Fritzing, Arduino)*
95. **Info-bulle d'aide contextuelle** sur les réglages obscurs (isolation, pas de grille). *(KiCad)*
96. **Bouton « pourquoi ? » sur une mesure** qui explique d'où vient la valeur.
97. **Historique des états de simulation** — pouvoir revenir à une image précédente. *(débogueurs)*
98. **Comparaison de deux relevés** superposés dans l'oscilloscope. *(Multisim, oscilloscopes réels)*
99. **Export du journal** avec le schéma, pour un compte rendu de TP. *(usage enseignant)*
100. **Mode « correction »** qui met en évidence les écarts avec un schéma de référence. *(usage enseignant)*
