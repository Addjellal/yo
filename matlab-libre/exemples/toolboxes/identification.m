% identification.m — System Identification Toolbox, cas d'école.
%
%   matlibre exemples/toolboxes/identification.m
%
% Le cas : on dispose d'un procédé dont on ne connaît pas le modèle, mais
% qu'on peut exciter et mesurer. C'est la situation de l'identification —
% partir des données, non des équations.

fprintf('=== Identification : retrouver un modele depuis les mesures ===\n\n');

%% 1. L'expérience
% Le signal d'excitation décide de ce qu'on pourra identifier : il doit
% être « suffisamment riche », c'est-à-dire contenir assez de fréquences
% pour distinguer les paramètres. Une séquence binaire pseudo-aléatoire
% le garantit avec une amplitude constante, ce qui ménage l'actionneur.
Te = 1;
N = 1000;
u = idinput(N, 'prbs');
% Le procédé vrai, que l'identification ne connaît pas :
%   A(q) y(k) = B(q) u(k) + e(k)
% soit  y(k) = 1.5 y(k-1) - 0.7 y(k-2) + 0.9 u(k-1) + 0.5 u(k-2) + e(k)
%
% Noter par où le bruit entre : dans l'équation, donc filtré par 1/A tout
% comme l'entrée. C'est la structure ARX, et c'est elle que la section
% suivante suppose. Un bruit ajouté directement sur la sortie donnerait
% une autre famille — celle de l'erreur de sortie — et l'ARX y serait
% biaisé, ce que la section 5 montre.
Avrai = [1 -1.5 0.7];
Bvrai = [0 0.9 0.5];
rng(1);
e = 0.1 * randn(N, 1);
y = filter(Bvrai, Avrai, u) + filter(1, Avrai, e);
donnees = iddata(y, u, Te);
fprintf('Experience : %d points, periode %g s\n', N, Te);
fprintf('  entree binaire, ecart type de sortie %.3f\n', std(y));
assert(donnees.N == N);
assert(size(donnees.y, 1) == N && size(donnees.u, 1) == N);

% Ce qu'on regarde avant d'estimer : le retard apparent et l'ordre
% conseillé.
conseil = advice(donnees);
fprintf('  retard apparent : %d periode(s), ordre conseille %d\n', ...
        conseil.RetardApparent, conseil.OrdreConseille);
assert(conseil.Echantillons == N);
assert(conseil.RetardApparent >= 1, 'le procede a bien un retard');

%% 2. Le modèle le plus simple : ARX
% Les moindres carrés, en une passe et sans itération. C'est toujours par
% là qu'on commence, quitte à s'en contenter.
modeleArx = arx(donnees, [2 2 1]);
fprintf('\nARX [2 2 1] :\n');
fprintf('  A = %s (vrai %s)\n', mat2str(round(modeleArx.A, 3)), mat2str(Avrai));
fprintf('  B = %s (vrai %s)\n', mat2str(round(modeleArx.B, 3)), mat2str(Bvrai));
assert(max(abs(modeleArx.A - Avrai)) < 0.05);
assert(max(abs(modeleArx.B - Bvrai)) < 0.05);

%% 3. Comparer, vérifier
% Un modèle se juge sur ce qu'il prédit, non sur ses coefficients.
[~, ajustement] = compare(modeleArx, donnees);
fprintf('  ajustement : %.2f %%\n', ajustement);
assert(ajustement > 80);
% Les résidus d'un bon modèle ne portent plus d'information : leur
% autocorrélation doit rester dans le seuil de confiance.
[residus, auto, ~, seuil] = resid(modeleArx, donnees);
horsSeuil = sum(abs(auto) > seuil) - 1;
fprintf('  autocorrelations hors seuil : %d sur %d (%.0f %%)\n', ...
        horsSeuil, numel(auto) - 1, horsSeuil / (numel(auto) - 1) * 100);
assert(abs(auto(ceil(numel(auto) / 2)) - 1) < 1e-12, ...
       'l''autocorrelation vaut un a l''origine');
% Le seuil est celui de 95 pour cent : on attend quelques depassements
% par pur hasard, et l'estimation en ajoute un peu. Ce qu'on refuse,
% c'est une structure qui resterait dans les residus.
assert(horsSeuil <= (numel(auto) - 1) / 4, 'les residus doivent etre presque blancs');
assert(std(residus) < std(y) / 5, 'les residus doivent etre petits devant la sortie');

%% 4. Choisir l'ordre
% Trop peu de paramètres et le modèle ne colle pas ; trop et il colle au
% bruit. Les critères tranchent en pénalisant la richesse.
fprintf('\nChoix de l''ordre :\n');
for ordre = 1:4
    candidat = arx(donnees, [ordre ordre 1]);
    fprintf('  ordre %d : MSE %.5f, FPE %.5f, AIC %8.1f\n', ordre, ...
            candidat.Report.Fit.MSE, fpe(candidat), aic(candidat));
end
criteres = zeros(1, 4);
for ordre = 1:4
    criteres(ordre) = aic(arx(donnees, [ordre ordre 1]));
end
[~, meilleur] = min(criteres);
fprintf('  ordre retenu par le critere d''Akaike : %d (vrai 2)\n', meilleur);
assert(meilleur == 2, 'le critere doit designer le vrai ordre');

%% 5. Quand le bruit n'est pas blanc en sortie
% L'ARX suppose que le bruit entre par le même dénominateur que l'entrée.
% Si ce n'est pas le cas, il biaise. Les autres familles séparent les
% deux chemins.
% Ici le bruit passe par C/A au lieu de 1/A : c'est la structure ARMAX,
% et l'ARX, qui suppose C = 1, ne peut plus etre exact.
rng(2);
Cvrai = [1 0.6];
yColore = filter(Bvrai, Avrai, u) + filter(Cvrai, Avrai, 0.2 * randn(N, 1));
donneesColorees = iddata(yColore, u, Te);
biaisArx = max(abs(arx(donneesColorees, [2 2 1]).A - Avrai));
modeleArmax = armax(donneesColorees, [2 2 1 1]);
biaisArmax = max(abs(modeleArmax.A - Avrai));
fprintf('\nBruit colore en sortie :\n');
fprintf('  ecart sur A : ARX %.4f, ARMAX %.4f\n', biaisArx, biaisArmax);
fprintf('  C estime : %s (vrai %s)\n', mat2str(round(modeleArmax.C, 3)), mat2str(Cvrai));
assert(abs(modeleArmax.C(2) - Cvrai(2)) < 0.15);
assert(biaisArmax < biaisArx, 'ARMAX doit corriger le biais de l''ARX');
% Les variables instrumentales corrigent aussi, sans modeliser le bruit.
biaisIv = max(abs(iv4(donneesColorees, [2 2 1]).A - Avrai));
fprintf('  ecart sur A : IV4 %.4f\n', biaisIv);
assert(biaisIv < biaisArx);

%% 6. Modèle d'état, par sous-espaces
% Aucune itération, aucune valeur de départ : une factorisation, et les
% pôles tombent. C'est ce qui rend la méthode robuste quand on ne sait
% pas par où commencer.
modeleEtat = n4sid(donnees, 2);
polesTrouves = sort(eig(modeleEtat.A));
polesVrais = sort(roots(Avrai));
fprintf('\nSous-espaces (n4sid, ordre 2) :\n');
fprintf('  poles trouves : %s\n', mat2str(round(polesTrouves', 4)));
fprintf('  poles vrais   : %s\n', mat2str(round(polesVrais', 4)));
assert(max(abs(polesTrouves - polesVrais)) < 0.05);

%% 7. Fonction de transfert continue
% Un procédé de premier ordre avec retard, la forme la plus courante en
% régulation industrielle.
TeContinu = 0.1;
tContinu = (0:TeContinu:60)';
uEchelon = double(tContinu > 2);
K = 2; Tp = 4; Td = 1;
% Reponse d'un premier ordre a l'echelon retarde, calculee directement.
yProc = K * (1 - exp(-max(tContinu - 2 - Td, 0) / Tp)) .* (tContinu > 2 + Td);
donneesProc = iddata(yProc, uEchelon, TeContinu);
modeleProc = procest(donneesProc, 'P1D');
fprintf('\nModele de procede P1D :\n');
fprintf('  gain %.4f (vrai %g), constante %.4f (vraie %g), retard %.4f (vrai %g)\n', ...
        modeleProc.K, K, modeleProc.Tp1, Tp, modeleProc.Td, Td);
assert(abs(modeleProc.K - K) < 0.05);
assert(abs(modeleProc.Tp1 - Tp) < 0.2);
assert(abs(modeleProc.Td - Td) < 0.2);

%% 8. Réponse fréquentielle, sans modèle paramétrique
% L'analyse spectrale ne suppose aucune structure : elle rend la réponse
% telle que les données la montrent.
reponse = spa(donnees, 60);
w = 0.5;
attendu = polyval(Bvrai, exp(1i * w)) / polyval(Avrai, exp(1i * w)) * exp(-1i * w * 0);
attendu = polyval(fliplr(Bvrai), exp(-1i * w)) / polyval(fliplr(Avrai), exp(-1i * w));
mesure = interp1(reponse.Frequency, reponse.ResponseData(:), w);
fprintf('\nAnalyse spectrale a w = %.1f rad/s :\n', w);
fprintf('  module mesure %.4f, vrai %.4f\n', abs(mesure), abs(attendu));
assert(abs(abs(mesure) - abs(attendu)) / abs(attendu) < 0.15);

fprintf('\nToutes les verifications passent.\n');
