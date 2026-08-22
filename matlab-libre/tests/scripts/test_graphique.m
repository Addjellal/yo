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

close all;
disp('graphique : toutes les verifications passent');
