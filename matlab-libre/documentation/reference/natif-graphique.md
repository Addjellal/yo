# Graphique

Fonctions natives du groupe `graphique`.

## `axes`

```
AXES  Créer un axe, ou en désigner un.
    AXES crée un axe neuf, qui occupe toute la figure et devient l'axe
    courant.

    AXES('Position',[G B L H]) le place où l'on veut : gauche, bas,
    largeur, hauteur, en fractions de la figure, l'origine en bas à
    gauche. Les axes que le nouveau recouvre disparaissent, comme dans
    MATLAB.

    AXES(H) rend courant l'axe de la poignée H : le tracé suivant ira
    dedans.

    Syntaxe
       axes
       h = axes('Position',[g b l h])
       axes(h)

    Exemples
       figure
       haut = axes('Position', [0.1 0.55 0.8 0.35]);
       plot(1:10);
       bas = axes('Position', [0.1 0.1 0.8 0.35]);
       plot(sin(1:10));
       axes(haut);            % on revient dans le premier
       title('celui du haut');
       close

    Voir aussi SUBPLOT, GCA, FIGURE, CLA, SET.
```

## `axis`

```
AXIS  Bornes et proportions des axes.
    AXIS([xmin xmax ymin ymax]) impose les bornes.
    AXIS AUTO revient au calcul automatique.
    AXIS EQUAL donne la même échelle aux deux axes : un cercle est rond.
    AXIS SQUARE rend la boîte des axes carrée.
    AXIS TIGHT serre les bornes sur les données.
    AXIS OFF / AXIS ON cache ou montre les axes.
    V = AXIS rend les bornes courantes.

    Syntaxe
       axis([xmin xmax ymin ymax])
       axis auto | equal | square | tight | off | on
       v = axis

    Exemples

       t = linspace(0, 2*pi);
       plot(cos(t), sin(t)); axis equal    % un vrai cercle
       axis([0 1 -1 1]);
       v = axis

    Voir aussi XLIM, YLIM, GRID, BOX, PLOT.
```

## `bar`

```
BAR  Diagramme en barres.
    BAR(Y) trace une barre par élément de Y.
    BAR(X,Y) place les barres aux abscisses X.
    BAR(...,LARGEUR) règle la largeur relative des barres (0.8 par défaut).

    Syntaxe
       bar(y)
       bar(x,y)
       bar(___,largeur)

    Exemples

       bar([3 7 2 9]);
       bar(2000:2004, [12 19 7 15 22]);
       x = 1:5;  y = rand(1,5);
       bar(x, y, 0.4);

    Voir aussi HISTOGRAM, STEM, STAIRS, PLOT.
```

## `box`

```
BOX  Cadre des axes.
    BOX ON entoure les axes d'un cadre complet, BOX OFF ne laisse que les
    deux axes de gauche et du bas.

    Syntaxe
       box on
       box off
       box

    Exemples
       plot(1:10); box off

    Voir aussi GRID, AXIS.
```

## `clf`

```
CLF  Efface la figure courante.
    CLF vide la figure courante de ses axes et de ses courbes, sans la
    fermer.

    Syntaxe
       clf

    Exemples
       plot(1:10);
       clf                        % la fenêtre reste, vide

    Voir aussi FIGURE, CLOSE, CLA, HOLD.
```

## `close`

```
CLOSE  Ferme une figure.
    CLOSE ferme la figure courante.
    CLOSE(N) ferme la figure numéro N.
    CLOSE ALL ferme toutes les figures.

    Syntaxe
       close
       close(n)
       close all

    Exemples
       figure; plot(1:10);
       close                      % ferme celle-là
       close all                  % ferme tout

    Voir aussi FIGURE, CLF, GCF.
```

## `colorbar`

```
COLORBAR  Barre de couleurs, avec son échelle.
    COLORBAR ajoute la barre à droite des axes courants.

    Syntaxe
       colorbar

    Exemples
       imagesc(peaks(30)); colorbar

    Voir aussi COLORMAP, IMAGESC, SURF, CONTOUR.
```

## `colormap`

```
COLORMAP  Palette de couleurs.
    COLORMAP(NOM) choisit une palette : 'parula', 'jet', 'hot', 'cool',
    'gray', 'bone', 'copper', 'spring', 'summer', 'autumn', 'winter'.
    COLORMAP(M) impose une matrice N par 3 de valeurs entre 0 et 1.
    M = COLORMAP rend la palette courante.

    Syntaxe
       colormap(nom)
       colormap(M)
       M = colormap

    Exemples
       imagesc(peaks(40)); colormap('hot'); colorbar

    Voir aussi COLORBAR, IMAGESC, SURF, SHADING.
```

## `contour`

```
CONTOUR  Lignes de niveau.
    CONTOUR(Z) trace les lignes de niveau de Z.
    CONTOUR(X,Y,Z) les place aux coordonnées (X,Y).
    CONTOUR(...,N) demande N niveaux.

    Syntaxe
       contour(Z)
       contour(X,Y,Z)
       contour(___,n)

    Exemples
       [X, Y] = meshgrid(-3:0.1:3);
       contour(X, Y, X.^2 + Y.^2, 12);

    Voir aussi SURF, MESH, PCOLOR, COLORBAR.
```

## `drawnow`

```
DRAWNOW  Force le rafraîchissement des figures.
    DRAWNOW vide la file d'affichage : ce qui a été tracé apparaît tout de
    suite, sans attendre la fin du script. C'est ce qu'on met dans une
    boucle d'animation.

    Syntaxe
       drawnow

    Exemples
       for k = 1:100
           plot(sin((1:100)/10 + k/5)); ylim([-1 1]);
           drawnow
       end

    Voir aussi PLOT, FIGURE, PAUSE.
```

## `figure`

```
FIGURE  Crée une fenêtre de figure, ou en active une.
    FIGURE crée une nouvelle fenêtre et en fait la figure courante.
    FIGURE(N) fait de la figure numéro N la figure courante, et la crée
    si elle n'existe pas.
    F = FIGURE(...) rend la poignée de la figure.

    Syntaxe
       figure
       figure(n)
       f = figure

    Exemples
       figure                     % une fenêtre neuve
       plot(1:10);
       figure(2); plot(rand(1,10));
       figure(1);                 % revenir à la première

    Voir aussi CLF, CLOSE, GCF, SUBPLOT, HOLD.
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
GET  Lit une propriété d'un objet graphique.
    GET(H,'Nom') rend la valeur de la propriété.
    GET(H) rend toutes les propriétés en structure.

    Syntaxe
       v = get(h,'Nom')
       s = get(h)

    Exemples
       plot(1:10);
       ax = gca;
       get(ax, 'XLim')
       s = get(ax);
       isstruct(s)
       close all

    Voir aussi SET, GCA, GCF, FIGURE.
```

## `grid`

```
GRID  Quadrillage des axes.
    GRID ON dessine le quadrillage, GRID OFF l'efface.
    GRID sans argument bascule entre les deux.

    Syntaxe
       grid on
       grid off
       grid

    Exemples
       plot(1:10); grid on

    Voir aussi AXIS, BOX, XLIM, YLIM.
```

## `hist`

```
HIST  Histogramme, forme historique.
    HIST(X) trace l'histogramme de X en dix classes.
    [N,C] = HIST(X) rend les effectifs et les centres, sans tracer.
    HISTOGRAM lui est préférée dans du code neuf.

    Syntaxe
       hist(x)
       [n,c] = hist(x)
       [n,c] = hist(x,nbClasses)

    Exemples
       [n, c] = hist([1 2 2 3 3 3], 3);
       sum(n)                             % 6
       numel(c)                           % 3

    Voir aussi HISTOGRAM, HISTCOUNTS, HISTC, BAR.
```

## `histogram`

```
HISTOGRAM  Histogramme des données.
    HISTOGRAM(X) répartit X en classes choisies automatiquement.
    HISTOGRAM(X,N) demande N classes.
    HISTOGRAM(X,BORDS) impose les bords des classes.

    Syntaxe
       histogram(x)
       histogram(x,n)
       histogram(x,bords)

    Exemples
       histogram(randn(1,10000), 50);

    Voir aussi HISTCOUNTS, BAR, MEAN, STD.
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

       x = linspace(0, 2*pi);
       y1 = sin(x);  y2 = cos(x);
       plot(x, y1); hold on; plot(x, y2); hold off

    Voir aussi PLOT, FIGURE, CLA.
```

## `image`

```
IMAGE  Affiche une matrice comme une image.
    IMAGE(C) affiche C, chaque élément étant un indice dans la palette.
    IMAGE(X,Y,C) place l'image dans le repère.

    Syntaxe
       image(C)
       image(x,y,C)

    Exemples
       image(magic(8)); colormap(gray); axis image

    Voir aussi IMAGESC, COLORMAP, COLORBAR, IMSHOW.
```

## `imagesc`

```
IMAGESC  Affiche une matrice en étalant ses valeurs sur toute la palette.
    IMAGESC(C) met le minimum de C au premier ton de la palette et son
    maximum au dernier : c'est la façon de regarder des données dont on
    ignore l'échelle.
    IMAGESC(C,[bas haut]) impose les bornes.

    Syntaxe
       imagesc(C)
       imagesc(C,[bas haut])
       imagesc(x,y,C)

    Exemples
       imagesc(randn(50)); colorbar

    Voir aussi IMAGE, COLORMAP, COLORBAR, AXIS.
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

       x = linspace(0, 1);
       y1 = x.^2;  y2 = sqrt(x);
       plot(x, y1, x, y2);
       legend('mesure', 'modèle');

    Voir aussi PLOT, TITLE, XLABEL, YLABEL.
```

## `loglog`

```
LOGLOG  Trace avec les deux axes en échelle logarithmique.
    LOGLOG(X,Y) est PLOT(X,Y) avec les deux axes logarithmiques : une loi
    de puissance y devient une droite.

    Syntaxe
       loglog(y)
       loglog(x,y)

    Exemples
       x = logspace(0, 3, 50);
       loglog(x, x.^-2); grid on

    Voir aussi SEMILOGX, SEMILOGY, PLOT.
```

## `matlibre_svg`

```
matlibre_svg  Rend la figure courante en SVG (texte).
```

## `mesh`

```
MESH  Surface en fil de fer.
    MESH(Z) trace Z sur une grille régulière.
    MESH(X,Y,Z) trace Z aux points (X,Y).

    Syntaxe
       mesh(Z)
       mesh(X,Y,Z)

    Exemples
       [X, Y] = meshgrid(-3:0.2:3);
       mesh(X, Y, peaks(X, Y));

    Voir aussi SURF, CONTOUR, MESHGRID, PLOT3.
```

## `pcolor`

```
PCOLOR  Damier coloré : une case par élément.
    PCOLOR(C) colore une grille selon C.
    PCOLOR(X,Y,C) la place aux coordonnées (X,Y).

    Syntaxe
       pcolor(C)
       pcolor(X,Y,C)

    Exemples
       pcolor(peaks(30)); shading interp

    Voir aussi IMAGESC, SURF, CONTOUR, SHADING.
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
PLOT3  Courbe en trois dimensions.
    PLOT3(X,Y,Z) trace la courbe passant par les points (X,Y,Z).
    PLOT3(X,Y,Z,STYLE) impose couleur, trait et marqueur.

    Syntaxe
       plot3(x,y,z)
       plot3(x,y,z,style)

    Exemples
       t = linspace(0, 10*pi, 500);
       plot3(cos(t), sin(t), t); grid on

    Voir aussi PLOT, MESH, SURF, ZLABEL.
```

## `print`

```
PRINT  Enregistre ou imprime une figure.
    PRINT(NOM,PILOTE) enregistre la figure courante ; le pilote est
    '-dpng', '-dsvg', '-dpdf'.

    Syntaxe
       print(nom,pilote)
       print -dpng nom

    Exemples
       plot(1:10);
       print('figure.png', '-dpng');

    Voir aussi SAVEAS, FIGURE.
```

## `saveas`

```
SAVEAS  Enregistre une figure dans un fichier.
    SAVEAS(F,NOM) enregistre la figure F sous le nom donné ; le format se
    déduit de l'extension.
    SAVEAS(F,NOM,FORMAT) impose le format : 'png', 'svg', 'pdf'.

    Syntaxe
       saveas(f,nom)
       saveas(f,nom,format)

    Exemples
       plot(1:10);
       saveas(gcf, 'courbe.png');
       saveas(gcf, 'courbe', 'svg');

    Voir aussi PRINT, FIGURE, GCF.
```

## `scatter`

```
SCATTER  Nuage de points.
    SCATTER(X,Y) place un marqueur à chaque couple (X,Y).
    SCATTER(X,Y,TAILLE) règle la surface des marqueurs.
    SCATTER(X,Y,TAILLE,COULEUR) donne leur couleur.

    Syntaxe
       scatter(x,y)
       scatter(x,y,taille)
       scatter(x,y,taille,couleur)

    Exemples

       scatter(randn(1,200), randn(1,200));
       x = rand(1,50);  y = rand(1,50);
       scatter(x, y, 36, 'r');

    Voir aussi PLOT, PLOT3, BAR.
```

## `semilogx`

```
SEMILOGX  Trace avec l'axe des abscisses en échelle logarithmique.
    SEMILOGX(X,Y) est PLOT(X,Y) avec l'axe des x logarithmique.

    Syntaxe
       semilogx(y)
       semilogx(x,y)
       semilogx(x,y,style)

    Exemples

       f = logspace(0, 4, 200);
       h = 1 ./ (1 + 1i*f/100);
       semilogx(f, 20*log10(abs(h))); grid on

    Voir aussi SEMILOGY, LOGLOG, PLOT, LOGSPACE.
```

## `semilogy`

```
SEMILOGY  Trace avec l'axe des ordonnées en échelle logarithmique.
    SEMILOGY(X,Y) est PLOT(X,Y) avec l'axe des y logarithmique.

    Syntaxe
       semilogy(y)
       semilogy(x,y)

    Exemples
       semilogy(0:20, exp(-(0:20)/3));

    Voir aussi SEMILOGX, LOGLOG, PLOT.
```

## `set`

```
SET  Écrit une propriété d'un objet graphique.
    SET(H,'Nom',VALEUR) pose la propriété.
    SET(H,'N1',V1,'N2',V2) en pose plusieurs.

    Syntaxe
       set(h,'Nom',valeur)
       set(h,'N1',v1,'N2',v2)

    Exemples
       plot(1:10);
       ax = gca;
       set(ax, 'XLim', [2 8]);
       get(ax, 'XLim')
       set(ax, 'XTick', [2 5 8], 'YGrid', 'on');
       close all

    Voir aussi GET, GCA, GCF, AXIS.
```

## `shading`

```
SHADING  Rendu des facettes d'une surface.
    SHADING FLAT donne une couleur unie à chaque facette.
    SHADING INTERP interpole la couleur à l'intérieur des facettes.
    SHADING FACETED garde les arêtes noires (défaut).

    Syntaxe
       shading flat | interp | faceted

    Exemples
       surf(peaks(40)); shading interp

    Voir aussi SURF, MESH, COLORMAP.
```

## `stairs`

```
STAIRS  Trace en escalier.
    STAIRS(Y) relie les points par des paliers horizontaux.
    STAIRS(X,Y) place les paliers aux abscisses X.

    C'est le tracé d'un signal bloqué entre deux échantillons — la sortie
    d'un bloqueur d'ordre zéro, par exemple.

    Syntaxe
       stairs(y)
       stairs(x,y)

    Exemples
       stairs(0:10, rand(1,11));

    Voir aussi STEM, PLOT, BAR.
```

## `stem`

```
STEM  Trace un signal discret : une tige et un cercle par échantillon.
    STEM(Y) trace Y en fonction de son indice.
    STEM(X,Y) trace Y en fonction de X.

    C'est le tracé naturel d'une suite : on voit les échantillons, pas une
    courbe continue qui n'existe pas entre eux.

    Syntaxe
       stem(y)
       stem(x,y)
       stem(___,style)

    Exemples
       n = 0:20;
       stem(n, 0.9.^n);

    Voir aussi PLOT, STAIRS, BAR.
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

       f = (0:63) / 64;
       Y = fft(sin(2*pi*8*(0:63)/64));
       subplot(2,1,1); plot(f, abs(Y));   title('Amplitude');
       subplot(2,1,2); plot(f, angle(Y)); title('Phase');

       donnees = randn(50,4);
       figure
       for k = 1:4
           subplot(2,2,k); plot(donnees(:,k));
       end

    Voir aussi PLOT, FIGURE, HOLD, GCA.
```

## `surf`

```
SURF  Surface pleine, colorée par la hauteur.
    SURF(Z) trace Z sur une grille régulière.
    SURF(X,Y,Z) trace Z aux points (X,Y).

    Syntaxe
       surf(Z)
       surf(X,Y,Z)

    Exemples
       [X, Y] = meshgrid(-2:0.1:2);
       surf(X, Y, X.^2 - Y.^2); shading interp

    Voir aussi MESH, CONTOUR, SHADING, COLORMAP, COLORBAR.
```

## `text`

```
TEXT  Écrit du texte dans les axes.
    TEXT(X,Y,TEXTE) place le texte au point (X,Y).
    TEXT(...,'Nom',Valeur) règle 'FontSize', 'Color', 'HorizontalAlignment'.

    Syntaxe
       text(x,y,texte)
       text(x,y,texte,'Nom',Valeur)

    Exemples
       plot(1:10);
       text(5, 5, 'ici', 'FontSize', 14, 'Color', 'r');

    Voir aussi TITLE, XLABEL, LEGEND.
```

## `title`

```
TITLE  Titre des axes.
    TITLE(TEXTE) écrit un titre au-dessus des axes courants.
    TITLE(TEXTE,'Nom',Valeur) règle 'FontSize', 'Color', 'FontWeight'.

    Syntaxe
       title(texte)
       title(texte,'Nom',Valeur)

    Exemples
       plot(1:10); title('Ma courbe');
       title(sprintf('n = %d', 10));
       title('Grand', 'FontSize', 16);

    Voir aussi XLABEL, YLABEL, ZLABEL, LEGEND, TEXT.
```

## `xlabel`

```
XLABEL  Étiquette de l'axe des abscisses.
    XLABEL(TEXTE) nomme l'axe des x des axes courants.

    Syntaxe
       xlabel(texte)
       xlabel(texte,'Nom',Valeur)

    Exemples

       t = 0:0.01:1;
       y = sin(2*pi*5*t);
       plot(t, y); xlabel('temps (s)'); ylabel('amplitude');

    Voir aussi YLABEL, ZLABEL, TITLE, LEGEND.
```

## `xlim`

```
XLIM  Bornes de l'axe des abscisses.
    XLIM([min max]) impose les bornes.
    L = XLIM rend les bornes courantes.
    XLIM AUTO revient au calcul automatique.

    Syntaxe
       xlim([min max])
       l = xlim
       xlim auto

    Exemples
       plot(0:100); xlim([20 60]);
       l = xlim

    Voir aussi YLIM, AXIS, GRID.
```

## `ylabel`

```
YLABEL  Étiquette de l'axe des ordonnées.
    YLABEL(TEXTE) nomme l'axe des y des axes courants.

    Syntaxe
       ylabel(texte)
       ylabel(texte,'Nom',Valeur)

    Exemples

       f = logspace(0, 3, 100);
       module = 1 ./ sqrt(1 + (f/100).^2);
       plot(f, module); ylabel('|H(f)|');

    Voir aussi XLABEL, ZLABEL, TITLE.
```

## `ylim`

```
YLIM  Bornes de l'axe des ordonnées.
    YLIM([min max]) impose les bornes.
    L = YLIM rend les bornes courantes.
    YLIM AUTO revient au calcul automatique.

    Syntaxe
       ylim([min max])
       l = ylim
       ylim auto

    Exemples
       plot(randn(1,100)); ylim([-3 3]);

    Voir aussi XLIM, AXIS, GRID.
```

## `zlabel`

```
ZLABEL  Étiquette de l'axe des cotes.
    ZLABEL(TEXTE) nomme l'axe des z des axes courants.

    Syntaxe
       zlabel(texte)

    Exemples

       t = linspace(0, 10*pi, 300);
       x = cos(t);  y = sin(t);  z = t;
       plot3(x, y, z); zlabel('hauteur');

    Voir aussi XLABEL, YLABEL, PLOT3, SURF, MESH.
```

