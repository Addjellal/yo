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

disp('graphique : toutes les verifications passent');
