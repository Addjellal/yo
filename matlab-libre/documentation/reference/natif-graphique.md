# Graphique

Fonctions natives du groupe `graphique`.

## `axis`

```
axis  Regle les limites des axes.
```

## `bar`

```
bar  Diagramme en barres.
```

## `box`

```
box  Cadre autour des axes.
```

## `clf`

```
clf  Vide la figure courante.
```

## `close`

```
close  Ferme une figure.
```

## `colorbar`

```
colorbar  Barre de couleurs.
```

## `colormap`

```
colormap  Palette de couleurs.
```

## `contour`

```
contour  Lignes de niveau.
```

## `drawnow`

```
drawnow  Rafraichit l'affichage.
```

## `figure`

```
figure  Cree ou choisit une figure.
```

## `gca`

```
GCA  Poignée des axes courants.
    AX = GCA rend une poignée vers les axes courants. On règle l'axe en
    écrivant ses propriétés au point.

    Propriétés réglables : XTick, YTick, XTickLabel, YTickLabel, XLim,
    YLim, XScale, YScale, XGrid, YGrid, Box, FontSize, Title, XLabel,
    YLabel.

    Une poignée n'est pas une copie : deux poignées du même axe le
    modifient toutes deux.

    Syntaxe
       ax = gca

    Exemples
       ax = gca;
       ax.XTick = [15 40 60 85];
       ax.YLim = [-1 1];
       ax.XScale = 'log';
       set(ax, 'Box', 'off');     % la forme historique marche aussi

    Voir aussi GCF, SET, GET, AXIS, SUBPLOT.
```

## `gcf`

```
GCF  Poignée de la figure courante.
    F = GCF rend une poignée vers la figure courante. Propriétés :
    Name, Number, Position, Type.

    Syntaxe
       f = gcf

    Exemples
       f = gcf;
       f.Name = 'Réponse fréquentielle';
       numero = f.Number;

    Voir aussi GCA, FIGURE, SET, GET.
```

## `get`

```
get  Lit une propriete d'une poignee graphique.
```

## `grid`

```
grid  Affiche la grille.
```

## `hist`

```
hist  Histogramme (ancienne forme).
```

## `histogram`

```
histogram  Histogramme.
```

## `hold`

```
HOLD  Conserve ou efface le tracé précédent.
    HOLD ON conserve le tracé courant : les tracés suivants s'y ajoutent.
    HOLD OFF efface avant chaque nouveau tracé — c'est l'état par défaut.
    HOLD bascule d'un état à l'autre.

    Syntaxe
       hold on
       hold off
       hold

    Exemples
       plot(x, y1); hold on; plot(x, y2); hold off

    Voir aussi PLOT, FIGURE, CLA.
```

## `image`

```
image  Affiche une matrice comme image.
```

## `imagesc`

```
imagesc  Image en fausses couleurs.
```

## `legend`

```
LEGEND  Légende des courbes.
    LEGEND(ETIQ1,ETIQ2,...) nomme les courbes dans l'ordre où elles ont
    été tracées.
    LEGEND({ETIQ1,ETIQ2,...}) accepte une cellule.
    LEGEND('off') retire la légende.

    Syntaxe
       legend(etiq1,...,etiqN)
       legend(cellule)
       legend('off')

    Exemples
       plot(x, y1, x, y2);
       legend('mesure', 'modèle');

    Voir aussi PLOT, TITLE, XLABEL, YLABEL.
```

## `loglog`

```
loglog  Deux axes logarithmiques.
```

## `matlibre_svg`

```
matlibre_svg  Rend la figure courante en SVG (texte).
```

## `mesh`

```
mesh  Maillage (rendu en carte de couleurs).
```

## `pcolor`

```
pcolor  Damier colore.
```

## `plot`

```
PLOT  Trace des courbes en deux dimensions.
    PLOT(Y) trace Y en fonction de son indice.
    PLOT(X,Y) trace Y en fonction de X.
    PLOT(X,Y,STYLE) impose la couleur, le style de trait et le marqueur.
    PLOT(X1,Y1,X2,Y2,...) trace plusieurs courbes.
    PLOT(...,'Nom',Valeur) règle 'LineWidth', 'Color', 'DisplayName'.

    Le style est une chaîne : une couleur (b r g c m y k w), un style de
    trait (- -- : -.) et un marqueur (o + * . x s d), dans n'importe quel
    ordre. « 'r--o' » donne un trait rouge tireté à marqueurs ronds.

    Syntaxe
       plot(Y)
       plot(X,Y)
       plot(X,Y,style)
       plot(X1,Y1,...,Xn,Yn)
       plot(___,'Nom',Valeur)

    Exemples
       x = 0:0.01:2*pi;
       plot(x, sin(x));
       plot(x, sin(x), 'r--', x, cos(x), 'b');
       plot(x, sin(x), 'LineWidth', 2);

       hold on                    % superposer sans effacer
       plot(x, cos(x));
       hold off

    Voir aussi HOLD, XLABEL, YLABEL, TITLE, LEGEND, GRID, SUBPLOT, AXIS.
```

## `plot3`

```
plot3  Trace une courbe 3-D (projetee).
```

## `print`

```
print  Ecrit la figure dans un fichier SVG.
```

## `saveas`

```
saveas  Enregistre la figure.
```

## `scatter`

```
scatter  Nuage de points.
```

## `semilogx`

```
semilogx  Axe des x logarithmique.
```

## `semilogy`

```
semilogy  Axe des y logarithmique.
```

## `set`

```
set  Ecrit une propriete d'une poignee graphique.
```

## `shading`

```
shading  Mode d'ombrage.
```

## `stairs`

```
stairs  Trace en escalier.
```

## `stem`

```
stem  Trace en tiges.
```

## `subplot`

```
SUBPLOT  Découpe la figure en une grille d'axes.
    SUBPLOT(M,N,P) découpe la figure en M lignes et N colonnes, et rend
    courant l'axe de rang P — numéroté ligne par ligne, de gauche à
    droite puis de haut en bas.
    SUBPLOT(M,N,P) sur un rang déjà occupé le rend simplement courant.

    Syntaxe
       subplot(m,n,p)
       subplot(mnp)

    Exemples
       subplot(2,1,1); plot(f, abs(Y));  title('Amplitude');
       subplot(2,1,2); plot(f, angle(Y)); title('Phase');

       for k = 1:4
           subplot(2,2,k); plot(donnees(:,k));
       end

    Voir aussi PLOT, FIGURE, HOLD, GCA.
```

## `surf`

```
surf  Surface (rendue en carte de couleurs).
```

## `text`

```
text  Texte dans les axes.
```

## `title`

```
title  Titre des axes.
```

## `xlabel`

```
xlabel  Etiquette de l'axe des x.
```

## `xlim`

```
xlim  Limites en x.
```

## `ylabel`

```
ylabel  Etiquette de l'axe des y.
```

## `ylim`

```
ylim  Limites en y.
```

## `zlabel`

```
zlabel  Etiquette de l'axe des z.
```

