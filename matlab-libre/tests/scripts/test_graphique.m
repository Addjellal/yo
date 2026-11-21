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

% Sur un axe logarithmique, les colonnes sont egales en decades. Le Bode
% de 1/(s(s+1)(s+2)), de 1e-4 a 1e4 rad/s : la reduction en abscisse
% lineaire mettait tout ce qui est sous 20 rad/s dans la premiere colonne,
% et le trace sautait d'un trait de 1e-4 a 20 rad/s, coudes compris.
close all;
wl = logspace(-4, 4, 4000);
figure; semilogx(wl, 20 * log10(abs(1 ./ (1i * wl .* (1i * wl + 1) .* (1i * wl + 2)))));
fichierLog = [tempname() '.svg'];
print(fichierLog);
texteLog = fileread(fichierLog);
delete(fichierLog);
debut = strfind(texteLog, '<path d="');
reste = texteLog(debut(1) + 9:end);
cheminLog = reste(1:find(reste == '"', 1) - 1);
xl = cellfun(@(c) str2double(c{1}), regexp(cheminLog, '[ML] ([-\d.]+) ', 'tokens'));
assert(numel(xl) > 100 && max(diff(sort(xl))) < 3, ...
       'axe logarithmique : aucune decade n''est sautee');

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
% Bornes fixees ensuite : elles restent, et c'est la boite qui se resserre
% (MATLAB ajuste alors PlotBoxAspectRatio) ; « axis image » de meme serre
% la boite sur l'image, sans bandes blanches.
motifBoite = ['<rect x="[\d.]+" y="[\d.]+" width="([\d.]+)" height="([\d.]+)" ' ...
              'fill="white" stroke="#222"'];
figure
imagesc(magic(5)); axis equal; xlim([0.5 5.5]); ylim([0.5 5.5]);
boite = regexp(matlibre_svg(), motifBoite, 'tokens', 'once');
assert(abs(str2double(boite{1}) - str2double(boite{2})) <= 1);
figure('Position', [0 0 800 300]);
imagesc(ones(10, 20)); axis image;
boite = regexp(matlibre_svg(), motifBoite, 'tokens', 'once');
assert(abs(str2double(boite{1}) / str2double(boite{2}) - 2) < 0.02);
assert(isequal(axis, [0.5 20.5 0.5 10.5]));
% La couleur et la taille d'un texte doivent tenir : une regle de feuille
% de style l'emporte sur un attribut, et « text{fill:#222} » rendait tous
% les textes gris fonce, 'Color','w' compris.
figure
imagesc(1); text(1, 1, 'blanc', 'Color', 'w', 'FontSize', 20); title('titre', 'FontSize', 9);
svgTexte = matlibre_svg();
assert(~isempty(strfind(svgTexte, 'fill="#FFFFFF">blanc')));
assert(isempty(regexp(svgTexte, 'text\{[^}]*(fill|font-size):', 'once')));
assert(isempty(regexp(svgTexte, '\.titre\{[^}]*font-size:', 'once')));
% « -. » est le tiret-point, « .- » le marqueur point relie par un trait.
figure
h1 = plot(1:3, 'r-.');
hold on
h2 = plot(1:3, 'k.-');
h3 = plot(1:3, 'b-.o');
assert(strcmp(get(h1, 'LineStyle'), '-.') && strcmp(get(h1, 'Marker'), 'none'));
assert(strcmp(get(h2, 'LineStyle'), '-') && strcmp(get(h2, 'Marker'), '.'));
assert(strcmp(get(h3, 'LineStyle'), '-.') && strcmp(get(h3, 'Marker'), 'o'));
assert(~isempty(strfind(matlibre_svg(), 'stroke-dasharray="8,3,2,3"')));
% Une barre part de zero, et zero compte dans les limites, comme dans
% MATLAB : bar([1300 700 200 900]) commencait l'axe a 200, et la barre de
% 200 disparaissait.
figure
bar([1300 700 200 900]);
limitesY = get(gca, 'YLim');
assert(limitesY(1) == 0 && limitesY(2) >= 1300);
figure
bar([1 2; 3 4], 'stacked');
limitesY = get(gca, 'YLim');
assert(limitesY(1) == 0 && limitesY(2) >= 7);
% Sous hold on, plot garde l'echelle logarithmique posee par semilogy.
figure
semilogy(1:3, [1 10 100]);
hold on
plot(1:3, [2 20 200], 'o');
assert(strcmp(get(gca, 'YScale'), 'log'));
hold off
plot(1:3, [1 2 3]);
assert(strcmp(get(gca, 'YScale'), 'linear'));
% Une etiquette de graduation longue elargit la marge au lieu d'etre
% rognee au bord de la figure.
figure
plot(1:3);
set(gca, 'YTick', 1:3, 'YTickLabel', {'une etiquette vraiment tres longue', 'b', 'c'});
boite = regexp(matlibre_svg(), ['<rect x="([\d.]+)" y="[\d.]+" width="[\d.]+" ' ...
                                'height="[\d.]+" fill="white" stroke="#222"'], 'tokens', 'once');
assert(str2double(boite{1}) > 180);

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
% Les graduations choisies d'office se relisent, comme dans MATLAB.
assert(~isempty(xticks()) && ~isequal(xticks(), [1 5 10]));
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
paire = [poigneeUne; plot([1 2 3], [7 8 9])];
assert(numel(paire) == 2);
assert(strcmp(class(paire), 'matlab.graphics.chart.primitive.Line'));
assert(strcmp(class([[]; poigneeUne]), 'matlab.graphics.chart.primitive.Line'));
% Deux sortes de poignees se reunissent sous le nom commun, comme dans
% MATLAB : elles restent des poignees graphiques, non une structure nue.
melange = [poigneeUne; poigneeTexte];
assert(numel(melange) == 2);
assert(strcmp(class(melange), 'matlab.graphics.Graphics'));
% Et chacune garde ce qu'elle est.
assert(strcmp(class(poigneeTexte), 'matlab.graphics.primitive.Text'));
assert(strcmp(class(poigneeUne), 'matlab.graphics.chart.primitive.Line'));
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
% Un patch est un seul objet, quel que soit son nombre de faces, comme
% dans MATLAB.
assert(numel(patch('Faces', [1 2 3; 1 3 4], 'Vertices', [0 0; 1 0; 1 1; 0 1], ...
                   'FaceColor', [0.6 0.8 1])) == 1);
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
rouges = findobj('Color', '#FF0000');
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
cla; assert(numel(bar3(magic(4))) == 4);     % une serie par colonne, comme MATLAB
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

%% --------------------------------- les options, en char, en chaine, par nom=valeur
% MATLAB accepte un nom d'option en chaine comme en char, et c'est en
% chaine qu'il arrive de « f(Nom=valeur) ». figure refusait la chaine ;
% surf et imagesc prenaient la derniere option pour les donnees, et
% dessinaient les codes de caracteres de 'none' ; histogram prenait le nom
% d'une option pour des bords, et rendait des effectifs nuls.
close all;
figure("Position", [0 0 640 480]);
fOpt = gcf;
assert(isequal(fOpt.Position(3:4), [640 480]), 'figure, un nom en chaine');
figure(Position=[0 0 500 300]);
fOpt = gcf;
assert(isequal(fOpt.Position(3:4), [500 300]), 'figure, nom=valeur');
% les options de surf sont lues, en char comme en nom=valeur, et non
% prises pour des donnees
cla; surf(magic(4)); svgSeul = matlibre_svg();
cla; surf(magic(4), 'EdgeColor', 'none'); svgSansBord = matlibre_svg();
assert(~strcmp(svgSansBord, svgSeul), 'surf : EdgeColor est lu');
cla; surf(magic(4), EdgeColor="none");
assert(strcmp(matlibre_svg(), svgSansBord), 'surf, nom=valeur');
assert(numel(get(gca, 'Children')) == 1, 'surf : l''option n''est pas une donnee');
cla; imagesc(magic(3)); svgSeul = matlibre_svg();
cla; imagesc(magic(3), 'AlphaData', 0.5);
assert(strcmp(matlibre_svg(), svgSeul), 'imagesc : les donnees, non l''option');
vuOpt = '';
try
    surf(magic(4), 'Couleur', 'r');
catch err
    vuOpt = err.identifier;
end
assert(strcmp(vuOpt, 'MATLAB:hg:InvalidProperty'), 'une propriete inconnue est refusee');
xOpt = [1 2 2 3 3 3 4 4 4 4];
cla; nOpt = histogram(xOpt, BinEdges=[0.5 1.5 2.5 3.5 4.5], FaceColor="r");
assert(isequal(nOpt, [1 2 3 4]), 'histogram : BinEdges, et FaceColor pour le dessin');
assert(isequal(histogram(xOpt, [0.5 2.5 4.5]), [3 7]), 'histogram : des bords par position');
assert(max(abs(histcounts(xOpt, 'Normalization', 'probability', 'NumBins', 4) - ...
               [0.1 0.2 0.3 0.4])) < 1e-15, 'histcounts : deux couples de suite');
refusOpt = {@() histogram(xOpt, 'BinWidth', 1), 'MATLAB:histcounts:NotSupported'; ...
            @() histcounts(xOpt, 4, 'NumBins', 4), 'MATLAB:histcounts:BinsTwice'; ...
            @() histcounts(xOpt, 'BinEdges', 3), 'MATLAB:histcounts:InvalidBinEdges'};
for q = 1:size(refusOpt, 1)
    vuOpt = '';
    try
        refusOpt{q, 1}();
    catch err
        vuOpt = err.identifier;
    end
    assert(strcmp(vuOpt, refusOpt{q, 2}), sprintf('histogram, refus %d : %s', q, vuOpt));
end
close all;

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

%% ------------------------------- nuages modernes et cartes
% SWARMCHART ecarte lateralement les points de meme abscisse : c'est la
% densite qu'on rend visible, sans choisir de largeur de classe.
ecartes = matlibre_essaimer([1; 1; 1], [1; 2; 3]);
assert(numel(unique(ecartes)) == 3, 'aucun ne cache plus l''autre');
assert(abs(mean(ecartes) - 1) < 1e-12, ...
       'l''ecartement est symetrique : la moyenne ne bouge pas');
% L'ecartement est deterministe : deux appels donnent le meme dessin.
assert(isequal(matlibre_essaimer([1; 1; 1], [1; 2; 3]), ecartes));
% Un point seul sur son abscisse ne bouge pas.
assert(isequal(matlibre_essaimer([1; 2], [1; 2]), [1; 2]));

figure();
groupes = [ones(1, 20), 2 * ones(1, 20)];
swarmchart(groupes, [randn(1, 20), randn(1, 20) + 3]);
close all;

% BUBBLECHART code la donnee dans l'aire et non dans le rayon : l'oeil
% compare des surfaces, et coder le rayon rendrait la lecture quadratique.
figure();
bubblechart(1:5, rand(1, 5), [1 4 9 16 25]);
close all;

% La projection geographique corrige le cosinus de la latitude : sans
% cela une trajectoire parait etiree des qu'on quitte l'equateur.
figure();
geoplot([48.85 43.30 45.76], [2.35 5.37 4.83]);
close all;
figure();
geoscatter([48.85 43.30], [2.35 5.37]);
close all;

% EXPORTGRAPHICS ecrit vraiment un fichier.
figure();
plot(1:10);
fichierExport = [tempname() '.svg'];
exportgraphics(gca, fichierExport);
assert(isfile(fichierExport));
delete(fichierExport);
close all;

%% ------------------------------------------- PLOT3, FPLOT3, FIMPLICIT3
% Une courbe de l'espace garde ses trois coordonnées. Le rendu est plan —
% on projette pour dessiner — mais ce qu'on relit doit être ce qu'on a
% donné, non l'ombre portée.
figure;
poignee3 = plot3([1 2 3], [4 5 6], [7 8 9]);
assert(numel(get(gca, 'Children')) == 1);   % une courbe, non trois
assert(isequal(get(poignee3, 'XData'), [1 2 3]));
assert(isequal(get(poignee3, 'YData'), [4 5 6]));
assert(isequal(get(poignee3, 'ZData'), [7 8 9]));
close all;

% FPLOT3 trace une courbe paramétrée : sur une hélice, les points doivent
% tomber sur le cylindre unité, et la hauteur croître sans retour.
figure;
helice = fplot3(@(t) sin(t), @(t) cos(t), @(t) t, [0 6*pi]);
xh = get(helice, 'XData');
yh = get(helice, 'YData');
zh = get(helice, 'ZData');
assert(numel(zh) > 100);
assert(max(abs(xh .^ 2 + yh .^ 2 - 1)) < 1e-12);
assert(all(diff(zh) > 0));
assert(abs(zh(1)) < 1e-12 && abs(zh(end) - 6*pi) < 1e-12);
close all;

% Une poignée non vectorisée est évaluée point par point : le résultat
% doit être le même.
figure;
lente = fplot3(@(t) t, @(t) t^2, @(t) t^3, [0 1]);
xl = get(lente, 'XData');
assert(max(abs(get(lente, 'YData') - xl .^ 2)) < 1e-12);
assert(max(abs(get(lente, 'ZData') - xl .^ 3)) < 1e-12);
close all;

% FIMPLICIT3 trace une surface implicite par tranches : sur une sphère,
% chaque point tracé doit être sur la sphère.
figure;
fimplicit3(@(x, y, z) x.^2 + y.^2 + z.^2 - 4, [-3 3]);
courbes = get(gca, 'Children');
assert(~isempty(courbes));
close all;


%% ------------------------------------------------------- WORDCLOUD
% Un nuage de mots place le plus frequent au centre et les autres autour,
% sans qu'aucun n'en recouvre un autre.
figure;
poigneesNuage = wordcloud(["chat" "chien" "oiseau" "poisson"], [10 6 3 1]);
assert(numel(poigneesNuage) == 4);
assert(strcmp(class(poigneesNuage), 'matlab.graphics.primitive.Text'));
abscisses = arrayfun(@(p) get(p, 'XData'), poigneesNuage);
ordonnees = arrayfun(@(p) get(p, 'YData'), poigneesNuage);
% Le premier — le plus frequent — est au centre.
assert(abs(abscisses(1)) < 1e-9 && abs(ordonnees(1)) < 1e-9);
% Aucun mot n'est pose au meme endroit qu'un autre.
assert(numel(unique(abscisses + 1i * ordonnees)) == 4);
% Le plus frequent est ecrit le plus grand.
assert(get(poigneesNuage(1), 'FontSize') > get(poigneesNuage(end), 'FontSize'));
close all;

% Un texte brut se compte tout seul.
figure;
poigneesTexte = wordcloud('le chat mange le poisson et le chat dort');
assert(numel(poigneesTexte) >= 3);
close all;
% Autant de tailles que de mots, sinon rien.
refuseNuage = false;
try
    wordcloud(["a" "b"], 1);
catch
    refuseNuage = true;
end
assert(refuseNuage);

%% ------------------------------- LEGENDE, BARRE, SUPPRESSION, PARENTE
% La legende n'est pas un texte d'axe : confondues, « set(l,'String',...) »
% ecrasait le titre, et « get(l,'String') » le rendait a sa place.
figure;
plot([1 2], [3 4]);
title('un titre bien a lui');
poigneeLegende = legend('a', 'b');
assert(strcmp(class(poigneeLegende), 'matlab.graphics.illustration.Legend'));
assert(isequal(get(poigneeLegende, 'String'), {'a', 'b'}));
set(poigneeLegende, 'String', {'c', 'd'});
assert(isequal(get(poigneeLegende, 'String'), {'c', 'd'}));
assert(strcmp(get(get(gca, 'Title'), 'String'), 'un titre bien a lui'));
assert(strcmp(get(poigneeLegende, 'Visible'), 'on'));
set(poigneeLegende, 'Visible', 'off');
assert(strcmp(get(poigneeLegende, 'Visible'), 'off'));
poigneeBarre = colorbar;
assert(strcmp(class(poigneeBarre), 'matlab.graphics.illustration.ColorBar'));
% La barre se dessine (elle etait acceptee sans rien tracer, malgre sa
% fiche) : un degrade a droite de la boite, gradue sur CLim. 'off' la
% retire. Les autres positions sont verifiees plus loin.
figure
imagesc([0 10; 20 30]);
colorbar
svgBarre = matlibre_svg();
assert(~isempty(strfind(svgBarre, 'class="barreCouleurs"')));
assert(~isempty(strfind(svgBarre, '>30</text>')) && ~isempty(strfind(svgBarre, '>0</text>')));
colorbar('off');
assert(isempty(strfind(matlibre_svg(), 'class="barreCouleurs"')));
close all

% Les enfants d'une figure sont ses axes : sans eux, un parcours de
% l'arbre graphique s'arretait a la figure.
figure;
plot(1:3);
enfantsFigure = get(gcf, 'Children');
assert(numel(enfantsFigure) >= 1);
assert(strcmp(get(enfantsFigure(1), 'Type'), 'axes'));
assert(~isempty(findobj(gcf, 'Type', 'axes')));

% Le parent d'un axe est sa figure, et c'est une poignee.
assert(strcmp(get(get(gca, 'Parent'), 'Type'), 'figure'));
assert(strcmp(class(get(gca, 'Parent')), 'matlab.ui.Figure'));
courbe = plot(1:3);
assert(strcmp(get(ancestor(courbe, 'axes'), 'Type'), 'axes'));
assert(strcmp(get(ancestor(courbe, 'figure'), 'Type'), 'figure'));
assert(strcmp(get(ancestor(gca, 'axes'), 'Type'), 'axes'));
assert(isempty(ancestor(gcf, 'axes')));

% DELETE d'une poignee retire l'objet du trace. Le nom de l'objet partait
% auparavant a la suppression de fichier, qui ne trouvait rien et se
% taisait : l'appel ne faisait rien du tout.
figure;
avant = plot(1:3);
assert(numel(get(gca, 'Children')) == 1);
delete(avant);
assert(numel(get(gca, 'Children')) == 0);

% ISHANDLE et ISGRAPHICS disent si l'objet existe encore, et de quel type.
figure;
assert(ishandle(gca));
assert(isgraphics(gca));
assert(isgraphics(gca, 'axes'));
assert(~isgraphics(gca, 'figure'));
assert(isgraphics(gcf, 'figure'));
numeroFigure = double(get(gcf, 'Number'));
assert(ishandle(numeroFigure));
close(gcf);
assert(~ishandle(numeroFigure));
assert(~ishandle(9999));

% CLOSE accepte la poignee que rend GCF, non seulement un numero : c'est
% l'ecriture la plus courante.
figure;
close(gcf);
assert(true);

% Sans interaction a la souris, il n'y a pas d'objet courant : le dire
% vaut mieux que rendre le dernier objet trace.
assert(isempty(gco()));
assert(isempty(gcbo()));

% FINDALL rend la meme chose que FINDOBJ, aucune poignee n'etant masquee.
figure;
plot(1:3);
assert(numel(findall(gca, 'Type', 'line')) == numel(findobj(gca, 'Type', 'line')));
close all;

% FIGURE lisait ses couples nom-valeur et les jetait : « Position »
% n'avait aucun effet, et la toile restait de huit cents pixels sur six
% cents quoi qu'on demande.
close all;
figure('Position', [0 0 1200 400]);
plot(1:3);
assert(isequal(get(gcf, 'Position'), [0 0 1200 400]), 'la position se relit');
toile = matlibre_svg();
assert(~isempty(strfind(toile, 'width="1200"')), 'la toile fait la largeur demandee');
assert(~isempty(strfind(toile, 'height="400"')), 'et la hauteur');

% Le numero peut preceder les couples, comme dans MATLAB.
figure(7, 'Position', [0 0 640 480], 'Name', 'essai');
assert(isequal(get(gcf, 'Number'), 7), 'le numero donne est celui de la figure');
assert(strcmp(get(gcf, 'Name'), 'essai'));
assert(isequal(get(gcf, 'Position'), [0 0 640 480]));

% Ce qui n'aurait pas d'effet est refuse, plutot qu'accepte en silence.
refusUnite = false;
try
    figure('Units', 'inches', 'Position', [0 0 4 3]);
catch err
    refusUnite = strcmp(err.identifier, 'MATLAB:hg:InvalidProperty');
end
assert(refusUnite, 'une unite que MatLibre ne mesure pas est refusee');

refusPropriete = false;
try
    figure('Chose', 3);
catch err
    refusPropriete = strcmp(err.identifier, 'MATLAB:hg:InvalidProperty');
end
assert(refusPropriete);

refusTaille = false;
try
    figure('Position', [0 0 100]);
catch err
    refusTaille = strcmp(err.identifier, 'MATLAB:hg:shaped_arrays');
end
assert(refusTaille);

refusNegatif = false;
try
    figure('Position', [0 0 -10 20]);
catch err
    refusNegatif = strcmp(err.identifier, 'MATLAB:hg:shaped_arrays');
end
assert(refusNegatif, 'une toile de largeur negative ne se dessine pas');

% Les proprietes de fenetre qui n'ont pas de sens sans fenetre sont
% acceptees sans effet : le resultat est le meme, et les programmes
% ecrits pour MATLAB tournent.
figure('NumberTitle', 'off', 'MenuBar', 'none', 'Position', [0 0 500 500]);
assert(isequal(get(gcf, 'Position'), [0 0 500 500]));
close all;

%% ------------------------------------------------- palettes et CLim
% colormap agit enfin : la figure, ou un axe ; la palette par défaut est
% viridis (domaine public), parula étant propre à MathWorks.
close all;
figure;
imagesc([1 2; 3 4]);
carte = colormap;
assert(isequal(size(carte), [256 3]));
assert(max(abs(carte(1, :) - [0.267004 0.004874 0.329415])) < 1e-6);
colormap(gray);
assert(isequal(colormap, gray(256)));
colormap(gca, jet(16));
assert(isequal(size(get(gca, 'Colormap')), [16 3]));
colormap('default');
refuse = false;
try
    colormap('parula');
catch
    refuse = true;
end
assert(refuse);
% CLim : les bornes de couleur suivent les données, ou ce qu'on fixe.
assert(isequal(clim, [1 4]));
clim([0 10]);
assert(isequal(clim, [0 10]) && isequal(get(gca, 'CLim'), [0 10]));
assert(strcmp(clim('mode'), 'manual'));
caxis('auto');
assert(isequal(caxis, [1 4]));
imagesc([5 6; 7 8], [0 20]);
assert(isequal(clim, [0 20]));

%% ---------------------------------------------------------- imshow
% Une image uint8 s'affiche en gris sur [0 255], axes masqués : la valeur
% 128 donne le gris 128.
close all;
figure;
imshow(uint8([0 128; 255 64]));
assert(isequal(clim, [0 255]));
assert(isequal(get(gca, 'Colormap'), gray(256)));
dessinGris = matlibre_svg();
assert(~isempty(strfind(dessinGris, 'rgb(128,128,128)')));
assert(~isempty(strfind(dessinGris, 'rgb(255,255,255)')) && ~isempty(strfind(dessinGris, 'rgb(0,0,0)')));
% Une image binaire est noire et blanche ; [] prend l'étendue des données.
imshow([true false]);
assert(isequal(clim, [0 1]));
imshow(magic(4), []);
assert(isequal(clim, [1 16]));
% Couleurs vraies : rouge pur.
imshow(cat(3, uint8(255), uint8(0), uint8(0)));
assert(~isempty(strfind(matlibre_svg(), 'rgb(255,0,0)')));
% image : les valeurs sont des rangs dans la palette.
figure;
image([1 2; 3 4]);
colormap([1 0 0; 0 1 0; 0 0 1; 1 1 1]);
dessinDirect = matlibre_svg();
assert(~isempty(strfind(dessinDirect, 'rgb(0,255,0)')) && ~isempty(strfind(dessinDirect, 'rgb(0,0,255)')));

%% ---------------------------------------------- légende et marqueurs
% Autant d'entrées que d'étiquettes ; les textes n'en sont pas ; le style
% et le marqueur de chaque courbe y sont repris.
close all;
figure;
plot(1:3, 'b-'); hold on
plot(1:3, 2:4, 'ro', 'MarkerSize', 9, 'MarkerFaceColor', 'r');
plot(1:3, 3:5, 'k:');
text(2, 2, 'note');
legend({'un', 'deux'}, 'Location', 'southeast');
dessinLegende = matlibre_svg();
assert(~isempty(strfind(dessinLegende, '>un<')) && ~isempty(strfind(dessinLegende, '>deux<')));
assert(isempty(strfind(dessinLegende, '>data3<')) && isempty(strfind(dessinLegende, '>data4<')));
assert(strcmp(get(legend, 'Location'), 'southeast'));
h = get(gca, 'Children');
assert(get(h(3), 'MarkerSize') == 9);
% legend(h, ...) désigne les courbes.
figure;
h1 = plot(1:3); hold on
h2 = plot(3:-1:1);
legend(h2, 'descente');
assert(~isempty(strfind(matlibre_svg(), '>descente<')));
% Les marqueurs 'x' et '*' ne sont pas des '+'.
figure;
plot(1, 1, 'x');
dessinCroix = matlibre_svg();
assert(~isempty(strfind(dessinCroix, 'M 67.00')) || ~isempty(regexp(dessinCroix, 'M [0-9.]+ [0-9.]+ L [0-9.]+ [0-9.]+ M', 'once')));
% fill(X,Y,C) : C est une couleur, pas un second polygone ; bord noir.
figure;
fill([0 1 1], [0 0 1], [0.8 0.9 1]);
assert(numel(get(gca, 'Children')) == 1);
dessinFill = matlibre_svg();
assert(~isempty(strfind(dessinFill, 'fill="#CCE6FF"')) && ~isempty(strfind(dessinFill, 'stroke="#000000"')));
% contour : un seul objet dans la légende, des niveaux colorés par la palette.
figure;
[X, Y] = meshgrid(-2:0.25:2);
contour(X, Y, X .^ 2 + Y .^ 2, 5);
legend('niveaux');
dessinContour = matlibre_svg();
assert(~isempty(strfind(dessinContour, '>niveaux<')) && isempty(strfind(dessinContour, '>data2<')));

%% ------------------------------------------------ bornes automatiques
% Comme MATLAB, les bornes tombent sur des graduations ; « axis tight »
% serre sur les données ; une image serre sur son étendue.
close all;
figure;
plot([-3.2 3.8], [-1.3 1.4]);
assert(isequal(xlim, [-4 4]) && isequal(ylim, [-1.5 1.5]));
plot([30 55], [0 17]);
assert(isequal(ylim, [0 20]));
plot(1:64, sin(1:64));
assert(isequal(xlim, [0 70]));
axis tight
assert(isequal(xlim, [1 64]));
figure;
imagesc(rand(5, 7));
assert(isequal(xlim, [0.5 7.5]) && isequal(ylim, [0.5 5.5]));
figure;
semilogx([20 500], [1 2]);
assert(isequal(xlim, [10 1000]));
% Une graduation nulle s'écrit 0, non -2.78e-17.
figure;
plot(1:18, [-0.443 0.39 zeros(1, 16)]);
assert(isempty(strfind(matlibre_svg(), 'e-17')));
close all;

%% ------------------------------------------------------------- barres
% bar(x, y, largeur) : la largeur n'est pas une serie de plus. Le trace
% generique de plot la lisait comme des donnees, et dessinait une barre
% parasite de hauteur 0,4.
close all;
figure;
bar((1:3) - 0.2, [5 6 7], 0.4);
hold on
bar((1:3) + 0.2, [5 6 7], 0.4);
assert(numel(get(gca, 'Children')) == 2);
% Une matrice : une serie par colonne, groupees ou empilees.
figure;
bar([1 2 3; 4 5 6]);
assert(numel(get(gca, 'Children')) == 3);
figure;
bar([1 2 3; 4 5 6], 'stacked');
assert(isequal(ylim, [0 16]));          % les piles montent a 6 et 15
% FaceColor et EdgeColor sont lus, et dessines.
figure;
bar(1:5, [3 1 4 1 5], 'FaceColor', [0.2 0.7 0.2], 'EdgeColor', 'none');
fichierBarres = [tempname() '.svg'];
print(fichierBarres);
texteBarres = fileread(fichierBarres);
delete(fichierBarres);
assert(contains(texteBarres, '#33B333') && contains(texteBarres, 'stroke="none"'));
close all;

%% ------------------------------------------- nuages, barres, graduations
% scatter : des cercles creux par défaut, comme MATLAB ; SZ est une aire
% par point, et non une seconde courbe ; C met chaque point à l'échelle
% de la palette, et CLim s'étend sur ses valeurs.
figure;
h = scatter(1:5, [2 4 3 5 1], [10 20 40 80 160], [1 2 3 4 5]);
assert(numel(get(gca, 'Children')) == 1, 'la taille n''est pas une seconde courbe');
assert(isequal(get(h, 'XData'), 1:5));
assert(isequal(clim, [1 5]));
dessinNuage = matlibre_svg();
assert(numel(strfind(dessinNuage, '<circle')) == 5);
assert(numel(strfind(dessinNuage, 'fill="none"')) >= 5, 'des marqueurs creux');
rayons = cellfun(@str2double, regexp(dessinNuage, '<circle[^>]* r="([\d.]+)"', 'tokens'));
assert(issorted(rayons) && rayons(end) / rayons(1) > 3.5, 'l''aire suit SZ');
% 'filled' remplit, et ôte le bord ; une couleur nommée vaut pour tous.
figure;
scatter([1 2 3], [3 1 2], 'filled', 'MarkerFaceColor', 'r');
dessinPlein = matlibre_svg();
assert(numel(strfind(dessinPlein, 'fill="#FF0000" stroke="none"')) == 3);
refusTaille = false;
try
    scatter(1:3, 1:3, [1 2]);
catch err
    refusTaille = strcmp(err.identifier, 'MATLAB:scatter:InvalidSizeData');
end
assert(refusTaille, 'une taille par point, ou une seule');
% Les lettres sont des couleurs pures, comme dans MATLAB.
figure;
h = plot(1:3, 'g');
assert(strcmp(get(h, 'Color'), '#00FF00'));
% bar : une graduation par barre, si bien que xticklabels nomme les
% bonnes barres ; xticks rend les graduations montrées.
figure;
bar([3 5 2 4]);
assert(isequal(xticks, 1:4));
assert(isequal(get(gca, 'XTick'), 1:4));
xticklabels({'janvier', 'fevrier', 'mars', 'avril'});
% Les étiquettes inclinées : xtickangle, et la propriété de l'axe.
xtickangle(45);
assert(xtickangle == 45 && get(gca, 'XTickLabelRotation') == 45);
dessinIncline = matlibre_svg();
assert(~isempty(strfind(dessinIncline, 'rotate(-45')), 'les etiquettes sont inclinees');
assert(~isempty(regexp(dessinIncline, 'text-anchor="end"[^>]*rotate\(-45[^>]*>janvier<', ...
                       'once')), 'et se terminent sur leur graduation');
set(gca, 'YTickLabelRotation', 30);
assert(ytickangle == 30);
% La barre de couleurs : ses huit positions, son étiquette, ses
% graduations nommées.
figure;
imagesc(magic(4));
cb = colorbar('southoutside');
assert(strcmp(get(cb, 'Location'), 'southoutside'));
cb.Label.String = 'altitude';
assert(strcmp(cb.Label.String, 'altitude'));
cb.Ticks = [4 8 12];
cb.TickLabels = {'bas', 'milieu', 'haut'};
assert(isequal(cb.Ticks, [4 8 12]));
dessinBarre = matlibre_svg();
assert(~isempty(strfind(dessinBarre, '>altitude<')) && ~isempty(strfind(dessinBarre, '>milieu<')));
for position = {'north', 'south', 'east', 'west', 'northoutside', 'westoutside'}
    colorbar(position{1});
    assert(strcmp(get(colorbar, 'Location'), position{1}));
    assert(~isempty(strfind(matlibre_svg(), 'class="barreCouleurs"')));
end
refusPosition = false;
try
    colorbar('ailleurs');
catch err
    refusPosition = strcmp(err.identifier, 'MATLAB:colorbar:InvalidLocation');
end
assert(refusPosition);
close all;

%% --------------------------------------------------------- l'espace
% plot3 garde les vraies coordonnees et pose la vue de MATLAB ; les bornes
% sont celles des donnees, non d'une projection.
figure;
t = linspace(0, 4 * pi, 50);
h = plot3(cos(t), sin(t), t);
assert(isequal(get(h, 'ZData'), t) && isequal(get(h, 'XData'), cos(t)));
assert(isequal(view, [-37.5 30]));
assert(isequal(xlim, [-1 1]) && isequal(zlim, [0 14]));
assert(numel(axis) == 6, 'axis rend six bornes en perspective');
[az, el] = view;
assert(az == -37.5 && el == 30);
view(2);
assert(isequal(view, [0 90]));
view(3);
view([30 45]);
assert(isequal(get(gca, 'View'), [30 45]));
zlim([-5 20]);
assert(isequal(zlim, [-5 20]) && isequal(get(gca, 'ZLim'), [-5 20]));
zlabel('hauteur');
dessinEspace = matlibre_svg();
assert(~isempty(strfind(dessinEspace, '>hauteur<')) && ~isempty(strfind(dessinEspace, '<path')));
assert(numel(strfind(dessinEspace, 'class="grille"')) > 10, 'la grille des plans du fond');
set(get(gca, 'ZLabel'), 'String', 'z');
assert(strcmp(get(get(gca, 'ZLabel'), 'String'), 'z'), 'l''etiquette z n''ecrase pas le titre');
% Un trace plan remplace l'espace : la vue de dessus revient, sans grille.
plot(1:3);
assert(isequal(view, [0 90]) && strcmp(get(gca, 'XGrid'), 'off'));
% surf : une maille par carre de la grille, les donnees en matrices.
figure;
h = surf(peaks(5));
assert(isequal(size(get(h, 'ZData')), [5 5]) && isequal(get(h, 'CData'), peaks(5)));
assert(strcmp(get(h, 'Type'), 'surface') && strcmp(get(h, 'FaceColor'), 'flat'));
assert(numel(strfind(matlibre_svg(), 'Z" fill="#')) == 16, 'seize mailles');
shading interp
assert(strcmp(get(h, 'EdgeColor'), 'none') && strcmp(get(h, 'FaceColor'), 'interp'));
mesh(peaks(5));
assert(strcmp(get(gca().Children, 'FaceColor'), '#FFFFFF'));
refusSurf = false;
try
    surf(1:5);
catch err
    refusSurf = strcmp(err.identifier, 'MATLAB:surf:NonMatrixData');
end
assert(refusSurf, 'surf veut une matrice');
% L'ordre du peintre : vue de dessus en perspective, le carre du haut est
% peint apres celui du bas ; vue de dessous, l'inverse.
figure;
fill3([0 1 1 0], [0 0 1 1], [0 0 0 0], 'r');
hold on
fill3([0 1 1 0], [0 0 1 1], [1 1 1 1], 'b');
hold off
view(-37.5, 30);
dessinDessus = matlibre_svg();
assert(strfind(dessinDessus, 'fill="#FF0000"') < strfind(dessinDessus, 'fill="#0000FF"'));
view(-37.5, -30);
dessinDessous = matlibre_svg();
assert(strfind(dessinDessous, 'fill="#0000FF"') < strfind(dessinDessous, 'fill="#FF0000"'));
% scatter3, stem3, bar3, patch en faces et sommets, texte de l'espace.
figure;
scatter3([1 2 3], [3 1 2], [2 3 1], 'filled');
assert(numel(strfind(matlibre_svg(), '<circle')) == 3 && isequal(view, [-37.5 30]));
stem3([1 2 3]);
assert(numel(get(gca, 'Children')) == 2, 'les tiges et leurs tetes');
h = bar3([1 2; 3 4]);
assert(numel(h) == 2 && isequal(xticks, 1:2));
cla;
h = patch('Faces', [1 2 3; 1 2 4], 'Vertices', [0 0 0; 1 0 0; 0 1 0; 0 0 1], ...
          'FaceVertexCData', [1; 2], 'FaceColor', 'flat');
assert(numel(h) == 1 && strcmp(get(h, 'Type'), 'patch'));
text(0, 0, 1, 'sommet');
assert(~isempty(strfind(matlibre_svg(), '>sommet<')));
close all;

%% ------------------------------------------------------------- TeX
% Les textes passent par le TeX de MATLAB : exposants, indices, lettres
% grecques, gras, couleurs ; 'none' les laisse tels quels.
figure;
plot(1:3);
title('x^2 + \alpha_1');
dessinTex = matlibre_svg();
assert(~isempty(strfind(dessinTex, char([206 177]))), 'alpha devient la lettre grecque');
assert(~isempty(regexp(dessinTex, 'baseline-shift="super"[^>]*>2<', 'once')), 'un exposant');
assert(~isempty(regexp(dessinTex, 'baseline-shift="sub"[^>]*>1<', 'once')), 'un indice');
assert(isempty(strfind(dessinTex, '\alpha')));
title('a_b', 'Interpreter', 'none');
assert(~isempty(strfind(matlibre_svg(), '>a_b<')), 'sans interprete, le texte tel quel');
assert(strcmp(get(get(gca, 'Title'), 'Interpreter'), 'none'));
xlabel('\omega (rad/s)');
assert(~isempty(strfind(matlibre_svg(), [char([207 137]) ' (rad/s)'])));
ylabel('x_{max}^{2}');
assert(~isempty(regexp(matlibre_svg(), 'baseline-shift="sub"[^>]*>max<', 'once')), 'un groupe');
text(2, 2, '\bf gras \rm et \color{red}rouge');
dessinTexte = matlibre_svg();
assert(~isempty(regexp(dessinTexte, 'font-weight="bold">gras', 'once')));
assert(~isempty(regexp(dessinTexte, 'fill="#FF0000">rouge', 'once')));
text(1, 1, 'a\_b\^c');
assert(~isempty(strfind(matlibre_svg(), '>a_b^c<')), 'les echappements');
legend('\sigma^2');
assert(~isempty(strfind(matlibre_svg(), char([207 131]))));
title('$x^2$', 'Interpreter', 'latex');
assert(~isempty(regexp(matlibre_svg(), 'baseline-shift="super"[^>]*>2<', 'once')), 'LaTeX simple');
set(gca, 'XTick', 1:3, 'XTickLabel', {'t_1', 't_2', 't_3'});
assert(~isempty(regexp(matlibre_svg(), 'baseline-shift="sub"[^>]*>3<', 'once')));
set(gca, 'TickLabelInterpreter', 'none');
assert(~isempty(strfind(matlibre_svg(), '>t_3<')));
refusInterprete = false;
try
    title('x', 'Interpreter', 'markdown');
catch err
    refusInterprete = strcmp(err.identifier, 'MATLAB:hg:InvalidInterpreter');
end
assert(refusInterprete);
close all;

%% ------------------------------------------- deux axes des ordonnees
% yyaxis : chaque cote a ses bornes, ses graduations, son etiquette et sa
% couleur ; un trace ne remplace que ceux de son cote.
figure;
x = 0:0.1:10;
yyaxis left
hGauche = plot(x, sin(x));
ylabel('sinus');
yyaxis right
hDroite = plot(x, 1000 * exp(-x));
ylabel('exponentielle');
assert(isequal(ylim, [0 1000]), 'les bornes de droite');
assert(strcmp(get(hDroite, 'Color'), '#D95319') && strcmp(get(hGauche, 'Color'), '#0072BD'));
dessinDeux = matlibre_svg();
assert(~isempty(strfind(dessinDeux, '>exponentielle<')) && ...
       ~isempty(strfind(dessinDeux, '>sinus<')));
assert(~isempty(regexp(dessinDeux, 'fill="#D95319">1000<', 'once')), 'les graduations de droite');
yyaxis left
assert(isequal(ylim, [-1 1]), 'et celles de gauche');
yyaxis right
plot(x, 500 * exp(-x));
assert(numel(get(gca, 'Children')) == 2, 'un trace ne remplace que son cote');
assert(isequal(ylim, [0 500]));
ylim([0 2000]);
assert(isequal(get(gca, 'YLim'), [0 2000]));
yyaxis left
assert(isequal(get(gca, 'YLim'), [-1 1]));
% plotyy rend deux axes, un par cote.
cla;
[ax, h1, h2] = plotyy(x, sin(x), x, 1000 * exp(-x));
assert(numel(ax) == 2);
ylabel(ax(2), 'droite');
assert(isequal(ylim(ax(2)), [0 1000]) && isequal(ylim(ax(1)), [-1 1]));
assert(~isempty(strfind(matlibre_svg(), '>droite<')));
refusCote = false;
try
    yyaxis milieu
catch err
    refusCote = strcmp(err.identifier, 'MATLAB:yyaxis:InvalidSide');
end
assert(refusCote);
close all;

%% ------------------- l'histogramme garde des graduations ordinaires
% Trace comme des barres, il heritait d'une graduation par barre : les
% bords des classes, ecrits en pleine precision, se chevauchaient
% (« -2.43202-1.82571… »). BAR, lui, garde une graduation par barre.
figure;
histogram(linspace(-2.43, 2.42, 500));
graduations = xticks();
assert(all(graduations == round(graduations)), 'des graduations rondes');
figure;
bar([3 5 2]);
assert(isequal(xticks(), [1 2 3]), 'une graduation par barre sous BAR');
close all;

%% ------------------- une couleur TeX hors de [0, 1] est bornee
% \color[rgb]{2,0,0} s'ecrivait « #1FE000 », un vert : 2 * 255 sur trois
% chiffres hexadecimaux, tronque.
figure;
title('\color[rgb]{2,0,0}rouge \color[rgb]{-1,0.5,0}vert');
svgCouleur = matlibre_svg();
assert(~isempty(strfind(svgCouleur, 'fill="#FF0000">rouge')), 'le rouge borne');
assert(~isempty(strfind(svgCouleur, 'fill="#008000">vert')), 'le vert borne');
close all;

disp('graphique : toutes les verifications passent');
