%% Antennes : diagrammes, directivité, bilans de liaison
% Une antenne ne crée pas de puissance : elle la répartit. La directivité
% mesure exactement cela — combien de fois plus de puissance part dans la
% meilleure direction que si tout était rayonné uniformément.
%
% Voir aussi DIPOLEPATTERN, ARRAYFACTOR, DIRECTIVITY, BEAMWIDTH, FRIIS.

fprintf('=== Antennes ===\n');

%% 1. Le dipôle demi-onde
% Le diagramme du dipôle est nul dans l'axe du fil et maximal
% perpendiculairement. C'est une conséquence directe du rayonnement d'un
% élément de courant : rien ne part dans la direction où l'on regarde le
% fil par le bout.
theta = linspace(1e-6, pi - 1e-6, 20001);
E = dipolePattern(theta, 0.5);
E = E / max(E);
fprintf('\nDipole demi-onde :\n');
fprintf('  champ dans l''axe (theta=0) : %.2e\n', dipolePattern(0, 0.5));
fprintf('  champ perpendiculaire (theta=pi/2) : %.4f\n', ...
        dipolePattern(pi/2, 0.5));
assert(dipolePattern(0, 0.5) < 1e-9, 'rien ne part dans l''axe du fil');
[~, imax] = max(E);
fprintf('  maximum a %.2f degres\n', rad2deg(theta(imax)));
assert(abs(theta(imax) - pi/2) < 1e-3, 'le maximum est perpendiculaire au fil');
% Symétrie : le dipôle rayonne pareil de part et d'autre de son plan.
assert(max(abs(E - fliplr(E))) < 1e-12, 'le diagramme est symetrique');

% L'ouverture à mi-puissance du demi-onde vaut 78 degrés : c'est un
% nombre du cours, et il sort ici du seul diagramme.
ouverture = beamwidth(theta, E);
fprintf('  ouverture a -3 dB : %.2f degres\n', rad2deg(ouverture));
assert(abs(rad2deg(ouverture) - 78) < 0.5, ...
       'le demi-onde ouvre a 78 degres');

% Et sa directivité vaut 1.64, soit 2.15 dBi : l'autre nombre du cours.
D = directivity(theta, E);
fprintf('  directivite %.4f, soit %.3f dBi\n', D, 10 * log10(D));
assert(abs(D - 1.641) < 0.01, 'la directivite du demi-onde vaut 1.64');
assert(abs(10 * log10(D) - 2.15) < 0.03, 'soit 2.15 dBi');

% L'antenne isotrope, elle, a une directivité de un par définition. C'est
% la référence à laquelle le « i » de dBi renvoie.
isotrope = ones(size(theta));
fprintf('  antenne isotrope : directivite %.6f\n', ...
        directivity(theta, isotrope));
assert(abs(directivity(theta, isotrope) - 1) < 1e-6, ...
       'l''isotrope a une directivite de un, par definition');

% Un dipôle plus long rayonne plus fort dans son plan — jusqu'à ce que
% des lobes secondaires apparaissent et lui reprennent de la puissance.
fprintf('  directivite selon la longueur :\n');
precedente = 0;
for L = [0.1 0.5 1.0]
    Ed = dipolePattern(theta, L);
    Ed = Ed / max(Ed);
    fprintf('    L = %.1f lambda : D = %.3f (%.2f dBi), ouverture %.1f deg\n', ...
            L, directivity(theta, Ed), 10*log10(directivity(theta, Ed)), ...
            rad2deg(beamwidth(theta, Ed)));
    assert(directivity(theta, Ed) > precedente, ...
           'allonger le dipole augmente la directivite jusqu''a une onde');
    precedente = directivity(theta, Ed);
end
% Le dipôle très court tend vers le dipôle élémentaire, de directivité 1.5.
assert(abs(directivity(theta, dipolePattern(theta, 0.01)) - 1.5) < 0.01, ...
       'le dipole court a la directivite 1.5 du doublet elementaire');

%% 2. Le réseau linéaire uniforme
% N éléments alignés, tous alimentés pareil. Le facteur de réseau vaut N
% quand tout s'additionne en phase, et s'annule N-1 fois par période.
n = 8;
d = 0.5;
angles = linspace(1e-6, pi - 1e-6, 40001);
AF = arrayFactor(n, d, angles);
fprintf('\nReseau lineaire de %d elements espaces de %g lambda :\n', n, d);
fprintf('  maximum du facteur de reseau : %.4f (nombre d''elements : %d)\n', ...
        max(AF), n);
assert(abs(max(AF) - n) < 1e-6, ...
       'au maximum, les N elements s''additionnent en phase');
% Le maximum est perpendiculaire au réseau : sans déphasage, c'est là que
% tous les trajets sont égaux.
[~, imax] = max(AF);
fprintf('  pointe a %.2f degres (broadside)\n', rad2deg(angles(imax)));
assert(abs(angles(imax) - pi/2) < 1e-3, ...
       'sans dephasage, le reseau pointe perpendiculairement');

% Le facteur de réseau est un rapport de sinus : il s'annule là où le
% numérateur s'annule sans le dénominateur, soit N-1 fois par période de
% psi. Avec psi = 2 pi d cos(theta), on sait donc dire à l'avance dans
% quelles directions le réseau ne rayonne rien.
psiNuls = mod(2 * pi * (1:n-1) / n + pi, 2 * pi) - pi;
thetaNuls = acos(psiNuls / (2 * pi * d));
fprintf('  %d zeros predits, aux directions :', n - 1);
fprintf(' %.1f', sort(rad2deg(thetaNuls)));
fprintf(' degres\n');
assert(max(arrayFactor(n, d, thetaNuls)) < 1e-9, ...
       'le reseau ne rayonne rien dans les N-1 directions predites');

% Entre deux zéros consécutifs il y a un lobe : N-1 en tout, un principal
% et N-2 secondaires.
bornes = [-inf, AF, -inf];
lobes = sum(bornes(2:end-1) > bornes(1:end-2) & bornes(2:end-1) >= bornes(3:end));
fprintf('  %d lobes comptes : un principal et %d secondaires\n', ...
        lobes, lobes - 1);
assert(lobes == n - 1, 'N-1 lobes pour N elements');

% Le premier lobe secondaire d'un réseau uniforme tend vers -13.26 dB du
% principal quand le nombre d'éléments croît, et ne descend jamais plus
% bas : c'est le prix d'une alimentation uniforme, et la raison pour
% laquelle on pondère les amplitudes quand on veut mieux.
%
% On regarde en variable psi — le déphasage entre éléments voisins — où
% l'énoncé ne dépend plus ni de l'espacement ni de la direction.
psi = linspace(-pi, pi, 100001);
thetaDePsi = acos(psi / (2 * pi * d));
precedent = 0;
for nn = [8 16 32 128]
    A = arrayFactor(nn, d, thetaDePsi);
    horsPrincipal = A(abs(psi) > 2.0001 * pi / nn);
    niveau = 20 * log10(max(horsPrincipal) / nn);
    fprintf('    %3d elements : premier lobe secondaire a %.2f dB\n', nn, niveau);
    assert(niveau < -12.7 && niveau > -13.27, ...
           'le premier lobe secondaire vit entre -12.7 et -13.26 dB');
    assert(niveau < precedent, 'et descend vers -13.26 dB sans l''atteindre');
    precedent = niveau;
end
% La limite est celle du premier lobe secondaire de sin(u)/u, atteint en
% u = 4.4934 : 20 log10 |sin(u)/u| = -13.26 dB.
u = fzero(@(v) cos(v) * v - sin(v), 4.5);
fprintf('    limite : sin(u)/u en u = %.4f, soit %.2f dB\n', ...
        u, 20 * log10(abs(sin(u) / u)));
assert(abs(precedent - 20 * log10(abs(sin(u) / u))) < 0.02, ...
       'a 128 elements on rejoint la limite du sinus cardinal');

% Serrer le réseau l'élargit, l'étirer l'affine : l'ouverture varie comme
% l'inverse de la longueur totale, non du nombre d'éléments.
fprintf('  ouverture selon la taille :\n');
for nn = [4 8 16]
    A = arrayFactor(nn, 0.5, angles);
    A = A / max(A);
    fprintf('    %2d elements (%.1f lambda) : %.2f degres\n', ...
            nn, (nn - 1) * 0.5, rad2deg(beamwidth(angles, A)));
end
o8 = beamwidth(angles, arrayFactor(8, 0.5, angles) / 8);
o16 = beamwidth(angles, arrayFactor(16, 0.5, angles) / 16);
assert(abs(o8 / o16 - 2) < 0.15, ...
       'doubler la longueur du reseau divise l''ouverture par deux');

% Le déphasage progressif dépointe le faisceau sans rien bouger : c'est
% tout le principe du balayage électronique.
fprintf('  balayage electronique par dephasage :\n');
for viseeDeg = [90 60 45]
    visee = deg2rad(viseeDeg);
    phase = -2 * pi * d * cos(visee);
    A = arrayFactor(n, d, angles, phase);
    [~, ip] = max(A);
    fprintf('    phase %+7.2f rad -> pointage a %.2f degres (voulu %g)\n', ...
            phase, rad2deg(angles(ip)), viseeDeg);
    assert(abs(rad2deg(angles(ip)) - viseeDeg) < 0.5, ...
           'le dephasage pointe le faisceau ou on veut');
    assert(abs(max(A) - n) < 1e-6, 'sans rien perdre au maximum');
end

% Espacer de plus d'une demi-longueur d'onde fait apparaître des lobes de
% réseau : un second maximum aussi fort que le principal, dans une
% direction parasite. C'est la limite qui fixe le pas d'un réseau.
compterMaxima = @(A) sum(A(2:end-1) > A(1:end-2) & A(2:end-1) >= A(3:end) & ...
                         A(2:end-1) > 0.9 * n);
Alarge = [-inf, arrayFactor(n, 1.0, angles), -inf];
fprintf('  espacement lambda/2 : %d maximum principal\n', ...
        compterMaxima([-inf, AF, -inf]));
fprintf('  espacement lambda   : %d maxima aussi forts (lobes de reseau)\n', ...
        compterMaxima(Alarge));
assert(compterMaxima([-inf, AF, -inf]) == 1, 'a lambda/2, un seul maximum');
assert(compterMaxima(Alarge) >= 2, ...
       'a lambda d''espacement, des lobes de reseau apparaissent');

%% 3. La formule de Friis
% La puissance reçue décroît comme le carré de la distance. Ce n'est pas
% une perte dans le milieu — le vide n'absorbe rien — mais l'étalement de
% la puissance sur une sphère de plus en plus grande.
Pt = 1;
Gt = 10;
Gr = 10;
lambda = 0.125;
fprintf('\nFormule de Friis (Pt = %g W, G = %g et %g, lambda = %g m) :\n', ...
        Pt, Gt, Gr, lambda);
for dist = [100 200 1000]
    Pr = friis(Pt, Gt, Gr, lambda, dist);
    fprintf('  a %5g m : %.4e W, soit %.2f dBm\n', dist, Pr, w2dbm(Pr));
end
assert(abs(friis(Pt, Gt, Gr, lambda, 200) / friis(Pt, Gt, Gr, lambda, 100) - 0.25) < 1e-12, ...
       'doubler la distance divise la puissance par quatre');
% La réciprocité : échanger émetteur et récepteur ne change rien.
assert(abs(friis(Pt, Gt, Gr, lambda, 100) - friis(Pt, Gr, Gt, lambda, 100)) < 1e-18, ...
       'la liaison est reciproque');
% Et le gain se paie deux fois si les deux bouts en profitent.
assert(abs(friis(Pt, 2*Gt, 2*Gr, lambda, 100) / friis(Pt, Gt, Gr, lambda, 100) - 4) < 1e-12, ...
       'doubler les deux gains quadruple le recu');

% Le dipôle demi-onde dans un vrai bilan : sa directivité de 1.64 sort du
% diagramme calculé plus haut, non d'une constante recopiée.
Pr = friis(1, D, D, lambda, 1000);
fprintf('  deux dipoles demi-onde a 1 km : %.3f dBm\n', w2dbm(Pr));
assert(w2dbm(Pr) < 0, 'a un kilometre il ne reste pas grand-chose');

fprintf('\nToutes les verifications passent.\n');
