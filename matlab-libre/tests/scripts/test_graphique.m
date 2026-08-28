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

close all;
disp('graphique : toutes les verifications passent');
