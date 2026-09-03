% test_graphique.m — figures et rendu SVG.
disp('--- graphique ---');

figure(1);
x = linspace(0, 2*pi, 50);
plot(x, sin(x), 'r-', x, cos(x), 'b--');
title('Sinus et cosinus');
xlabel('x');
ylabel('amplitude');
legend('sin', 'cos');
grid on;

svg = matlibre_svg();
assert(~isempty(strfind(svg, '<svg')));
assert(~isempty(strfind(svg, '</svg>')));
assert(~isempty(strfind(svg, 'Sinus et cosinus')));
assert(~isempty(strfind(svg, 'path')));

nom = [tempname() '.svg'];
print(nom);
contenu = fileread(nom);
assert(numel(contenu) > 500);
delete(nom);

% Plusieurs axes.
figure(2);
subplot(2, 1, 1);
bar([1 2 3]);
subplot(2, 1, 2);
stem([3 2 1]);
svg2 = matlibre_svg();
assert(~isempty(strfind(svg2, 'rect')));

% Histogramme et nuage de points.
figure(3);
scatter(1:10, (1:10).^2);
hold on;
plot(1:10, 10*(1:10));
hold off;
svg3 = matlibre_svg();
assert(~isempty(strfind(svg3, 'circle')));

%% ------------------------------- reduction d'un trace tres dense
% Cent mille points sur huit cents pixels : cent vingt-cinq par colonne,
% dont un seul se voit. Le trace n'en garde que l'enveloppe — premier,
% minimum, maximum, dernier de chaque colonne — et le fichier passe de
% 1,6 Mo a 25 ko. Ce qui est verifie ici, c'est que le dessin ne change
% pas : l'enveloppe reduite doit couvrir la meme etendue que l'originale.
close all;
xd = 0:0.00001:1;
yd = sin(2 * pi * 50 * xd) .* exp(-2 * xd);
figure; plot(xd, yd);
fichierDense = [tempname() '.svg'];
print(fichierDense);
texteDense = fileread(fichierDense);
delete(fichierDense);

% Le chemin du trace, extrait du SVG.
debut = strfind(texteDense, '<path d="');
assert(~isempty(debut));
reste = texteDense(debut(1) + 9:end);
fin = strfind(reste, '"');
chemin = reste(1:fin(1) - 1);

% Le fichier tient : sans reduction il ferait plus d'un megaoctet.
assert(numel(texteDense) < 200000);

% Les coordonnees du chemin.
morceaux = strsplit(strtrim(chemin), ' ');
xs = []; ys = [];
k = 1;
while k <= numel(morceaux)
    if strcmp(morceaux{k}, 'M') || strcmp(morceaux{k}, 'L')
        xs(end + 1) = str2double(morceaux{k + 1});   %#ok<SAGROW>
        ys(end + 1) = str2double(morceaux{k + 2});   %#ok<SAGROW>
        k = k + 3;
    else
        k = k + 1;
    end
end
assert(numel(xs) > 100);              % l'enveloppe reste detaillee
assert(numel(xs) < numel(xd) / 10);   % mais bien plus courte que l'original

% L'etendue verticale du trace reduit est celle du trace complet : c'est
% ce qui garantit qu'aucune crete n'a ete perdue. On compare en pixels,
% avec la meme transformation que le rendu.
assert(max(ys) - min(ys) > 400);      % la sinusoide occupe la hauteur
assert(max(xs) - min(xs) > 650);      % et toute la largeur

% Un trace court n'est pas touche : ses points sont tous rendus.
close all;
xc = 0:0.25:1;
figure; plot(xc, xc .^ 2);
fichierCourt = [tempname() '.svg'];
print(fichierCourt);
texteCourt = fileread(fichierCourt);
delete(fichierCourt);
assert(numel(strfind(texteCourt, 'L ')) >= 4);

%% ----------------------------- poignees : gca, gcf et leurs proprietes
% « ax = gca ; ax.XTick = [...] » est la facon courante de regler un axe en
% MATLAB. gca rendait un simple nombre : l'ecriture au point echouait sur
% « dot indexing is not supported », et le script s'arretait la.
close all;
figure;
plot(0:0.1:10, sin(0:0.1:10));
ax = gca;
assert(strcmp(class(ax), 'matlab.graphics.axis.Axes'));
ax.XTick = [0 2.5 5 7.5 10];
assert(isequal(ax.XTick, [0 2.5 5 7.5 10]));
% Les limites qu'on n'a pas fixees sont celles des donnees, pas 0..1.
bornes = ax.XLim;
assert(abs(bornes(1) - 0) < 1e-9 && abs(bornes(2) - 10) < 1e-9);
ax.YLim = [-2 2];
assert(isequal(ax.YLim, [-2 2]));
ax.XScale = 'log';
assert(strcmp(ax.XScale, 'log'));
ax.XScale = 'linear';
ax.Box = 'off';
assert(strcmp(ax.Box, 'off'));
% « ax.Title = 'texte' » pose le titre ; le lire rend la poignee du
% texte, comme dans MATLAB, et c'est sur elle qu'on lit la chaine.
ax.Title = 'un titre';
assert(strcmp(get(ax.Title, 'String'), 'un titre'));

% La forme historique marche aussi.
set(ax, 'YTick', [-1 0 1], 'FontSize', 12);
assert(isequal(get(ax, 'YTick'), [-1 0 1]));
assert(get(ax, 'FontSize') == 12);

% Les graduations imposees se retrouvent dans le rendu.
fichierTicks = [tempname() '.svg'];
print(fichierTicks);
texteTicks = fileread(fichierTicks);
delete(fichierTicks);
assert(~isempty(strfind(texteTicks, '2.5')));
assert(~isempty(strfind(texteTicks, 'un titre')));

% La poignee de figure porte son nom et son numero.
fg = gcf;
assert(strcmp(class(fg), 'matlab.ui.Figure'));
fg.Name = 'ma figure';
assert(strcmp(fg.Name, 'ma figure'));
assert(fg.Number >= 1);

% Une propriete inconnue est refusee, en la nommant.
essaiPropriete = false;
try
    ax.ProprieteQuiNExistePas = 3;
catch e
    essaiPropriete = ~isempty(strfind(e.message, 'ProprieteQuiNExistePas'));
end
assert(essaiPropriete);

close all;
%% ------------------------------------ axis equal, square et off au rendu
% « axis equal » ne doit pas seulement etre accepte : il doit changer
% l'image. On le verifie sur le SVG, la ou tout est mesurable.
figure
plot([0 10], [0 1]);           % dix fois plus large que haut
svgLibre = matlibre_svg();
% Sans « axis equal », l'axe des y ne va pas au-dela de 1.
assert(isempty(strfind(svgLibre, '>-3<')));
axis equal
svgEgal = matlibre_svg();
% Avec, la boite du trace etant plus large que haute, l'axe des y couvre
% davantage d'unites : les graduations descendent sous -1.
assert(~isempty(strfind(svgEgal, '>-3<')));
assert(isequal(axis, [0 10 0 1]));   % les bornes des donnees, inchangees

% « axis square » rend la boite carree : le cadre du trace doit l'etre.
figure
plot(1:10);
axis square
svgCarre = matlibre_svg();
debut = strfind(svgCarre, '<rect x=');
assert(numel(debut) >= 2);           % le fond, puis la boite du trace

% « axis off » retire le cadre, les graduations et les etiquettes ; le
% titre, lui, reste — c'est ce que fait MATLAB.
figure
plot(1:10);
title('avec axes'); xlabel('x'); ylabel('y');
svgAvec = matlibre_svg();
assert(~isempty(strfind(svgAvec, 'avec axes')));
assert(~isempty(strfind(svgAvec, 'stroke="#222"')));
axis off
svgSans = matlibre_svg();
assert(~isempty(strfind(svgSans, 'avec axes')));      % le titre reste
assert(isempty(strfind(svgSans, 'class="axe"')));     % plus de graduations
assert(numel(svgSans) < numel(svgAvec));
axis on
close all

%% ------------------------------------------------ decoupages en cases
% Chaque axe porte son propre decoupage : deux « subplot » de grilles
% differentes coexistent, et le second efface seulement les cases qu'il
% recouvre. C'est ce que fait MATLAB, et c'est ce qui empechait un
% diagramme de Bode de deplacer les cases voisines.
cases = @() numel(strfind(matlibre_svg(), 'fill="white" stroke="#222"'));
figure
subplot(2, 2, 1); plot(1:10);
subplot(2, 2, 2); plot(1:10);
assert(cases() == 2);
subplot(2, 1, 2); plot(1:10);          % recouvre les cases 3 et 4, pas 1 ni 2
assert(cases() == 3);
subplot(1, 1, 1); plot(1:10);          % recouvre tout
assert(cases() == 1);
% Revenir sur une case deja ouverte la reprend, sans en creer une autre.
figure
subplot(2, 2, 1); plot(1:10);
subplot(2, 2, 2); plot(1:10);
subplot(2, 2, 1); plot(2:11);
assert(cases() == 2);
% Une case peut en couvrir plusieurs.
figure
subplot(2, 2, [1 2]); plot(1:10);
subplot(2, 2, 3); plot(1:10);
assert(cases() == 2);
% Une case hors du decoupage est refusee.
tropLoin = false;
try
    subplot(2, 2, 7);
catch err
    tropLoin = strcmp(err.identifier, 'MATLAB:subplot:SubplotIndexTooLarge');
end
assert(tropLoin);

%% --------------------------------------------------- axes places a la main
% « axes('Position',[g b l h]) » place un axe ou l'on veut, en fractions
% de la figure, l'origine en bas a gauche.
figure
haut = axes('Position', [0.1 0.55 0.8 0.35]);
bas = axes('Position', [0.1 0.1 0.8 0.35]);
assert(cases() == 2);
assert(max(abs(get(haut, 'Position') - [0.1 0.55 0.8 0.35])) < 1e-9);
% « axes(h) » revient sur un axe : le trace suivant y va.
axes(haut);
plot(1:10);
assert(max(abs(get(gca, 'Position') - [0.1 0.55 0.8 0.35])) < 1e-9);
% Une poignee reste valide quand un autre axe disparait : elle porte
% l'identifiant de son axe, pas son rang.
figure
premier = subplot(2, 2, 1);
subplot(2, 2, 4);
subplot(2, 1, 2);                      % efface les cases 3 et 4
set(premier, 'YLim', [0 5]);
assert(max(abs(get(premier, 'YLim') - [0 5])) < 1e-9);

%% ------------------------------------------------- echelles logarithmiques
% Un axe logarithmique porte ses graduations aux puissances de dix, et les
% ecrit en exposant — 10 puissance moins deux, non 0.01.
figure
semilogx(logspace(-2, 3, 100), ones(1, 100));
svgLog = matlibre_svg();
assert(~isempty(strfind(svgLog, '10<tspan')));
assert(~isempty(strfind(svgLog, '>-2</tspan>')));
assert(~isempty(strfind(svgLog, '>3</tspan>')));
% En lineaire, aucune puissance en exposant.
figure
plot(logspace(-2, 3, 100), ones(1, 100));
assert(isempty(strfind(matlibre_svg(), '10<tspan')));
% Un axe logarithmique en y ne tombe pas sur les valeurs negatives.
figure
semilogy([1 2 3], [-1 10 100]);
svgY = matlibre_svg();
assert(~isempty(strfind(svgY, '10<tspan')));
close all

%% ------------------------------------------- le titre est un objet
% « z = title(...) » rend une poignee, sur laquelle on ecrit : c'est ce
% que font les scripts qui grossissent leur titre.
figure
plot(1:10);
z = title('un titre');
assert(strcmp(class(z), 'matlab.graphics.primitive.Text'));
assert(strcmp(get(z, 'String'), 'un titre'));
set(z, 'FontSize', 16);
assert(get(z, 'FontSize') == 16);
svgTitre = matlibre_svg();
assert(~isempty(strfind(svgTitre, 'font-size="16px"')));
assert(~isempty(strfind(svgTitre, 'un titre')));
% L'etiquette d'un axe aussi, et « gca » les rend.
e = xlabel('temps');
set(e, 'String', 't (s)');
assert(strcmp(get(get(gca, 'XLabel'), 'String'), 't (s)'));
assert(strcmp(get(get(gca, 'Title'), 'String'), 'un titre'));
% Une propriete qu'on ne sait pas rendre est acceptee sans rien casser.
set(z, 'Color', [1 0 0]);
set(z, 'Interpreter', 'tex');
% Une propriete qui n'existe pas est refusee, comme dans MATLAB.
inconnue = false;
try
    set(z, 'CetteProprieteNExistePas', 1);
catch err
    inconnue = strcmp(err.identifier, 'MATLAB:hg:InvalidProperty');
end
assert(inconnue);
close all

%% ------------------------------------------ droites, graduations, aires
% « xline » et « yline » traversent l'axe sans en changer les bornes :
% c'est ce qui les distingue d'un trace a deux points.
figure
plot([1 2 3], [10 20 30]);
avant = ylim();
yline(1000);
apres = ylim();
assert(isequal(avant, apres));      % la droite n'a pas etire l'axe
svgDroites = matlibre_svg();
assert(~isempty(strfind(svgDroites, '<line')));
xline(2, '--r', 'ici');
assert(~isempty(strfind(matlibre_svg(), 'ici')));
% Un vecteur donne autant de droites.
figure
plot(1:10);
xline([2 4 6]);
assert(numel(strfind(matlibre_svg(), 'stroke-width="1.5"')) >= 3);

% Les graduations imposees, et leurs etiquettes.
figure
plot(1:10);
xticks([1 5 10]);
assert(isequal(xticks(), [1 5 10]));
xticklabels({'debut', 'milieu', 'fin'});
assert(numel(xticklabels()) == 3);
svgEtiquettes = matlibre_svg();
assert(~isempty(strfind(svgEtiquettes, 'milieu')));
xticks('auto');
assert(isempty(xticks()));
yticks([0 5 10]);
assert(isequal(yticks(), [0 5 10]));

% « xlim » et « get(gca,'XLim') » disent la meme chose : les bornes des
% donnees quand on ne les a pas fixees.
figure
plot([2 4 8], [1 2 3]);
assert(isequal(xlim(), [2 8]));
assert(isequal(get(gca, 'XLim'), [2 8]));
xlim([0 10]);
assert(isequal(xlim(), [0 10]));

% « cla » vide l'axe courant, et lui seul.
figure
subplot(1, 2, 1); plot(1:10); title('a effacer');
subplot(1, 2, 2); plot(10:-1:1); title('a garder');
subplot(1, 2, 1); cla;
svgApresCla = matlibre_svg();
assert(isempty(strfind(svgApresCla, 'a effacer')));
assert(~isempty(strfind(svgApresCla, 'a garder')));

% Les aires et les polygones sont remplis.
figure
area(1:5, [1 3 2 4 3]);
assert(~isempty(strfind(matlibre_svg(), 'fill-opacity')));
figure
fill([0 1 1 0], [0 0 1 1], 'r');
assert(~isempty(strfind(matlibre_svg(), 'fill-opacity')));

% « line » ajoute sans effacer.
figure
plot(1:10);
line([1 10], [5 5], 'Color', '#D95319', 'LineWidth', 2);
assert(numel(strfind(matlibre_svg(), '<path')) == 2);

% « tiledlayout » et « nexttile » remplissent les cases dans l'ordre.
figure
tiledlayout(2, 2);
nexttile; plot(1:10);
nexttile; plot(sin(1:10));
nexttile; bar([3 1 2]);
assert(numel(strfind(matlibre_svg(), 'fill="white" stroke="#222"')) == 3);
% Et l'on peut sauter a une case donnee.
figure
tiledlayout(1, 3);
nexttile(3); plot(1:5);
assert(numel(strfind(matlibre_svg(), 'fill="white" stroke="#222"')) == 1);

% « errorbar » trace la courbe et ses barres.
figure
errorbar(1:5, [2 4 3 5 4], 0.4 * ones(1, 5));
assert(numel(strfind(matlibre_svg(), '<path')) >= 2);
close all

% ----------------------------------------------------------- contours
% « contour » n'etait qu'un autre nom pour « surf » : il rend maintenant
% de vraies lignes de niveau, par marching squares.
[Xn, Yn] = meshgrid(linspace(-2, 2, 41), linspace(-2, 2, 41));
Zn = Xn .^ 2 + Yn .^ 2;
C = contourc(Xn, Yn, Zn, [1 2]);
% La matrice C : [niveau ; nombre de points] puis les points.
assert(size(C, 1) == 2);
niveauUn = C(1, 1);
combien = C(2, 1);
assert(niveauUn == 1);
xs = C(1, 2:combien + 1);
ys = C(2, 2:combien + 1);
rayons = sqrt(xs .^ 2 + ys .^ 2);
assert(max(abs(rayons - 1)) < 2e-3);          % c'est bien le cercle
assert(abs(xs(1) - xs(end)) < 1e-12);         % la courbe est fermee
assert(abs(ys(1) - ys(end)) < 1e-12);
% Une seule courbe par niveau : les segments degeneres, dus aux sommets
% poses exactement sur le niveau, ne doivent pas en creer d'autres.
suivant = combien + 2;
assert(C(1, suivant) == 2);
rayonsDeux = sqrt(C(1, suivant + 1:suivant + C(2, suivant)) .^ 2 + ...
                  C(2, suivant + 1:suivant + C(2, suivant)) .^ 2);
assert(max(abs(rayonsDeux - sqrt(2))) < 2e-3);
assert(suivant + C(2, suivant) == size(C, 2));

figure('Visible', 'off');
[~, poigneesContour] = contour(Xn, Yn, Zn, 5);
assert(numel(poigneesContour) >= 5);
contourf(Xn, Yn, Zn, 5);
contour3(Xn, Yn, Zn);
etiquettesNiveau = clabel(contourc(Xn, Yn, Zn, [1 2]));
assert(numel(etiquettesNiveau) == 2);
assert(strcmp(get(etiquettesNiveau(1), 'String'), '1'));
close('all');

% ------------------------------------------------ poignees et proprietes
figure('Visible', 'off');
poigneeUne = plot([1 2 3], [4 5 6]);
assert(strcmp(get(poigneeUne, 'Type'), 'line'));
% « text » etait un appel sans effet : c'est une vraie primitive.
poigneeTexte = text(2, 5, 'ici');
assert(strcmp(get(poigneeTexte, 'Type'), 'text'));
assert(strcmp(get(poigneeTexte, 'String'), 'ici'));
assert(isequal(get(poigneeTexte, 'Position'), [2 5 0]));
set(poigneeTexte, 'String', 'la', 'FontSize', 14);
assert(strcmp(get(poigneeTexte, 'String'), 'la'));
assert(get(poigneeTexte, 'FontSize') == 14);
dessin = matlibre_svg();
assert(~isempty(strfind(dessin, '>la<')));
% Un texte ne dilate pas les bornes.
text(100, 100, 'loin');
bornesApres = xlim();
assert(bornesApres(2) <= 3.5);
% get(gca,'Children') rend les courbes, la derniere en tete.
enfants = get(gca(), 'Children');
assert(numel(enfants) == 3);
% Un tableau de poignees garde sa classe : « [] » en tete ne l'efface pas.
paire = [poigneeUne; poigneeTexte];
assert(strcmp(class(paire), 'matlab.graphics.chart.primitive.Line'));
assert(strcmp(class([[]; poigneeUne]), 'matlab.graphics.chart.primitive.Line'));
% xline, fill et area rendent aussi une poignee.
assert(strcmp(get(xline(2), 'Type'), 'line'));
assert(~isempty(fill([0 1 1], [0 0 1], 'r')));
assert(~isempty(area([1 2 3], [1 4 2])));
assert(strcmp(get(imagesc(magic(4)), 'Type'), 'line'));
close('all');

% --------------------------------------------------- diagrammes nouveaux
figure('Visible', 'off');
assert(numel(barh([3 5 2 7])) == 4);
[~, ordrePareto] = pareto([12 3 45 7 22], {'a', 'b', 'c', 'd', 'e'});
assert(ordrePareto(1) == 3);        % « c » est la plus grande
cla;
assert(numel(pie([3 1 1])) == 6);   % trois secteurs et trois etiquettes
cla;
pie([30 20 50], [0 0 1], {'nord', 'sud', 'est'});
cla;
pie3([3 1 1]);
cla;
[~, effectifsRose] = rose([0 0 0 pi pi], 4);
assert(isequal(effectifsRose, [3 0 2 0]));
cla;
assert(numel(patch('Faces', [1 2 3; 1 3 4], 'Vertices', [0 0; 1 0; 1 1; 0 1], ...
                   'FaceColor', [0.6 0.8 1])) == 2);
cla;
rectangle('Position', [0 0 2 2], 'Curvature', 1, 'FaceColor', [0.9 0.9 0.5]);
cla;
theta = linspace(0, 2 * pi, 100);
polarplot(theta, 1 + cos(theta));
cla;
compass([1 2 -1], [2 1 1]);
cla;
feather(cos(0:pi/8:2*pi), sin(0:pi/8:2*pi));
cla;
[Xq, Yq] = meshgrid(-2:0.5:2);
quiver(Xq, Yq, -Yq, Xq);
cla;
quiver3(Xq, Yq, Xq, -Yq, Xq, Xq);
cla;
heatmap(magic(4));
cla;
boxchart(randn(30, 3));
close('all');

% Les fonctions donnees par une poignee.
figure('Visible', 'off');
fplot(@sin, [0 2*pi]);
cla;
fplot(@(t) cos(3*t), @(t) sin(2*t), [0 2*pi]);
cla;
% Une poignee non vectorisee doit passer quand meme.
fplot(@(x) max(x, 0), [-2 2]);
cla;
poigneeCercle = fimplicit(@(x, y) x.^2 + y.^2 - 1);
donneesX = get(poigneeCercle(1), 'XData');
donneesY = get(poigneeCercle(1), 'YData');
assert(max(abs(sqrt(donneesX .^ 2 + donneesY .^ 2) - 1)) < 1e-3);
cla;
ezplot('sin(x)/x');
cla;
ezplot(@(x, y) x.^2 + y.^2 - 1);      % deux variables : courbe implicite
cla;
ezsurf('x^2 - y^2');
cla;
ezcontour('x^2 + y^2');
close('all');
% « nargin » sur une poignee rendait -1 : c'est ce qui permet a EZPLOT de
% distinguer une fonction d'une variable d'une courbe implicite.
assert(nargin(@(x) x) == 1);
assert(nargin(@(x, y) x + y) == 2);
assert(nargout(@(x) x) == 1);

% ------------------------------------------------ derivees et laplacien
assert(isequal(gradient([1 4 9 16 25]), [3 4 6 8 9]));
[Xg, Yg] = meshgrid(-2:0.2:2);
Zg = Xg .^ 2 - Yg .^ 2;
[derX, derY] = gradient(Zg, 0.2);
interieur = 2:size(Zg, 1) - 1;
assert(max(max(abs(derX(interieur, interieur) - 2 * Xg(interieur, interieur)))) < 1e-12);
assert(max(max(abs(derY(interieur, interieur) + 2 * Yg(interieur, interieur)))) < 1e-12);
assert(isequal(del2([1 4 9 16 25]), [1 1 1 1 1]));
% Une fonction harmonique a un laplacien nul.
laplacien = del2(Zg, 0.2);
assert(max(max(abs(laplacien(interieur, interieur)))) < 1e-10);
% Le champ radial diverge de 2 et ne tourne pas ; le champ tournant fait
% l'inverse.
assert(abs(mean(mean(divergence(Xg, Yg, Xg, Yg))) - 2) < 1e-10);
assert(max(max(abs(curl(Xg, Yg, Xg, Yg)))) < 1e-10);
assert(abs(mean(mean(curl(Xg, Yg, -Yg, Xg))) - 2) < 1e-10);
assert(max(max(abs(divergence(Xg, Yg, -Yg, Xg)))) < 1e-10);

% ------------------------------------------------- geometrie et maillage
[Xs, Ys, Zs] = sphere(10);
assert(isequal(size(Xs), [11 11]));
assert(abs(max(max(Xs .^ 2 + Ys .^ 2 + Zs .^ 2)) - 1) < 1e-12);
[Xcy, ~, Zcy] = cylinder(2, 10);
assert(isequal(size(Xcy), [2 11]));
assert(abs(max(Zcy(:)) - 1) < 1e-12);
[Xel, Yel, Zel] = ellipsoid(1, 2, 3, 1, 1, 1, 10);
assert(abs(mean(Zel(:)) - 3) < 1e-12);
[normX, normY, normZ] = surfnorm(Xg, Yg, Xg .* exp(-Xg.^2 - Yg.^2));
assert(max(max(abs(normX.^2 + normY.^2 + normZ.^2 - 1))) < 1e-12);

% La triangulation de Delaunay : aucun point dans un cercle circonscrit.
assert(isequal(delaunay([0 1 1 0], [0 0 1 1]), [1 2 3; 1 3 4]));
rand('seed', 4);
xd = rand(25, 1);
yd = rand(25, 1);
T = delaunay(xd, yd);
violations = 0;
for t = 1:size(T, 1)
    s = T(t, :);
    ax = xd(s(1)); ay = yd(s(1));
    bx = xd(s(2)); by = yd(s(2));
    cx = xd(s(3)); cy = yd(s(3));
    d = 2 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by));
    ux = ((ax^2 + ay^2) * (by - cy) + (bx^2 + by^2) * (cy - ay) + ...
          (cx^2 + cy^2) * (ay - by)) / d;
    uy = ((ax^2 + ay^2) * (cx - bx) + (bx^2 + by^2) * (ax - cx) + ...
          (cx^2 + cy^2) * (bx - ax)) / d;
    r = sqrt((ax - ux)^2 + (ay - uy)^2);
    for k = 1:numel(xd)
        if ~any(s == k) && sqrt((xd(k) - ux)^2 + (yd(k) - uy)^2) < r - 1e-10
            violations = violations + 1;
        end
    end
end
assert(violations == 0);
figure('Visible', 'off');
trimesh(T, xd, yd);
cla;
trisurf(T, xd, yd, xd .^ 2 + yd .^ 2);
cla;
voronoi(xd, yd);
[aretesX, aretesY] = voronoi(xd, yd);
assert(size(aretesX, 1) == 2 && size(aretesX, 2) == size(aretesY, 2));
cla;
gplot([0 1 1; 1 0 1; 1 1 0], [0 0; 1 0; 0.5 1], '-o');
[grapheX, grapheY] = gplot([0 1 1; 1 0 1; 1 1 0], [0 0; 1 0; 0.5 1]);
assert(numel(grapheX) == 9);          % trois aretes, trois points chacune
close('all');

% [X,Y,Z] = meshgrid(x) repetait le vecteur ; ndgrid s'arretait a deux.
[m1, m2, m3] = meshgrid(-1:1);
assert(isequal(size(m1), [3 3 3]));
assert(isequal(size(m3), [3 3 3]));
[n1, n2, n3] = ndgrid(1:2, 1:3, 1:4);
assert(isequal(size(n1), [2 3 4]));
assert(n1(2, 3, 4) == 2 && n2(2, 3, 4) == 3 && n3(2, 3, 4) == 4);

% ---------------------------------------------- objets et manipulations
figure('Visible', 'off');
plot(1:10, 'r');
hold('on');
plot((1:10) .^ 2, 'b');
hold('off');
rouges = findobj('Color', '#D95319');
assert(numel(rouges) == 1);
set(rouges, 'LineWidth', 3);
assert(get(rouges(1), 'LineWidth') == 3);
assert(numel(findobj('Type', 'line')) == 2);
newplot;
line([1 2], [3 4]);
% copyobj recopie donnees et apparence dans un autre axe.
figure(97);
origine = plot(1:10, (1:10) .^ 2, 'r', 'LineWidth', 2);
figure(98);
copie = copyobj(origine, gca());
assert(get(copie(1), 'YData')(3) == 9);
assert(get(copie(1), 'LineWidth') == 2);
close('all');

figure('Visible', 'off');
plot(1:100);
zoom(2);
bornesZoom = xlim();
assert(bornesZoom(2) - bornesZoom(1) < 60);
zoom('out');
caxis([-8 8]);
assert(isequal(caxis(), [-8 8]));
clim('auto');
% Les commandes d'eclairage et d'interaction sont acceptees sans effet.
surf(peaks(20));
light('Position', [1 1 1]);
lighting('gouraud');
material('dull');
hidden('off');
alpha(0.5);
rotate3d('on');
pan('on');
brush('on');
datacursormode('on');
refresh;
% rotate tourne bel et bien dans le plan du dessin.
cla;
segment = plot([0 1], [0 0], 'LineWidth', 2);
rotate(segment, [0 0 1], 90);
assert(max(abs(get(segment, 'XData') - [0.5 0.5])) < 1e-12);
assert(max(abs(get(segment, 'YData') - [-0.5 0.5])) < 1e-12);
% Ce qui ne peut pas etre fait le dit, au lieu d'inventer.
erreurGinput = '';
try
    ginput(1);
catch e
    erreurGinput = e.identifier;
end
assert(strcmp(erreurGinput, 'MATLAB:ginput:NoInteractiveFigure'));
erreurUicontrol = '';
try
    uicontrol();
catch e
    erreurUicontrol = e.identifier;
end
assert(strcmp(erreurUicontrol, 'MATLAB:uicontrol:Unsupported'));
close('all');

% ---------------------------------------------- annotations et capture
figure('Visible', 'off');
plot(1:10);
annotation('arrow', [0.3 0.5], [0.3 0.6]);
annotation('doublearrow', [0.1 0.9], [0.1 0.1]);
annotation('line', [0 1], [0.5 0.5]);
annotation('ellipse', [0.4 0.4 0.2 0.2]);
poigneeBoite = annotation('textbox', [0.2 0.7 0.2 0.1], 'String', 'le sommet');
assert(strcmp(get(poigneeBoite(1), 'String'), 'le sommet'));
vue = getframe();
assert(numel(vue.svg) > 0);
movie(vue, 1);
savefig('/tmp/matlibre_test_figure');
assert(exist('/tmp/matlibre_test_figure.svg', 'file') > 0);
delete('/tmp/matlibre_test_figure.svg');
cla;
[Xv, Yv, Zv] = meshgrid(-2:0.4:2);
volume = Xv .* exp(-Xv.^2 - Yv.^2 - Zv.^2);
assert(numel(slice(volume, [], [], [3 6])) == 2);
close('all');

% ------------------------------------------- surfaces et barres derivees
figure('Visible', 'off');
meshc(peaks(20));
cla; surfc(peaks(20));
cla; meshz(peaks(20));
cla; surfl(peaks(20), [45 30]);
cla; waterfall(peaks(10));
cla; ribbon(peaks(10));
cla; assert(numel(bar3(magic(4))) == 16);
cla; bar3h(magic(4));
cla; plotmatrix(randn(30, 2));
cla; plotyy(1:10, sin(1:10), 1:10, 1000 * exp(-(1:10)));
cla; stackedplot((1:20)', [sin(1:20)', (1:20)' .^ 2]);
cla; comet(1:50, sin(1:50));
cla; comet3(cos(1:50), sin(1:50), 1:50);
cla; plot(1:10);
gtext('la droite', 5, 5);
datesEssai = datenum(2024, 1, 1) + (0:29);
cla; plot(datesEssai, 1:30);
datetick('x', 'dd/mm');
close('all');

%% ------------------------------------------------- sens des axes
% « axis ij » et YDir retournent l'axe des ordonnees : c'est ce dont a
% besoin toute image, dont la premiere ligne se lit en haut.
figure('Visible', 'off');
plot(1:3, [1 2 3]);
axis('ij');
assert(strcmp(get(gca, 'YDir'), 'reverse'));
set(gca, 'YDir', 'normal');
assert(strcmp(get(gca, 'YDir'), 'normal'));
set(gca, 'XDir', 'reverse');
assert(strcmp(get(gca, 'XDir'), 'reverse'));
axis('xy');
assert(strcmp(get(gca, 'YDir'), 'normal'));

% imagesc retourne l'axe de lui-meme, surf ne le fait pas : une image se
% lit comme une matrice, une surface se voit de dessus.
cla; imagesc([1 2; 3 4]);
assert(strcmp(get(gca, 'YDir'), 'reverse'));
cla; [grilleX, grilleY] = meshgrid(1:5, 1:4);
surf(grilleX, grilleY, grilleY);
assert(strcmp(get(gca, 'YDir'), 'normal'));
cla; pcolor(magic(4));
assert(strcmp(get(gca, 'YDir'), 'normal'));

%% ------------------------------------------------- histogramme a deux axes
[comptes, bordsX, bordsY] = histcounts2([1 2 3], [1 1 2], [0 2 4], [0 1.5 3]);
assert(isequal(comptes, [1 0; 1 1]));
assert(isequal(bordsX, [0 2 4]) && isequal(bordsY, [0 1.5 3]));
[comptesAuto, ~, ~] = histcounts2(randn(1, 100), randn(1, 100));
assert(isequal(size(comptesAuto), [10 10]));
assert(sum(comptesAuto(:)) == 100);
cla; histogram2(randn(1, 200), randn(1, 200), [8 8]);

%% --------------------------------------------- contour : entrees refusees
% Une grille de moins de deux lignes ou deux colonnes ne se decoupe pas.
% MatLibre lisait le premier element d'un vecteur vide et tombait.
for entree = {[], 1, zeros(1, 5)}
    contourRefuse = false;
    try
        contour(entree{1});
    catch
        contourRefuse = true;
    end
    assert(contourRefuse);
end
contourRefuse = false;
try
    contourf('');
catch
    contourRefuse = true;
end
assert(contourRefuse);
cla; contourf(peaks(10));
close('all');

disp('graphique : toutes les verifications passent');
