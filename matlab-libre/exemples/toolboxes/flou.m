% flou.m — Fuzzy Logic Toolbox sur un cas d'école.
%
%   matlibre exemples/toolboxes/flou.m
%
% Le cas : le pourboire au restaurant. C'est l'exemple d'école de la
% logique floue — deux notes, la nourriture et le service, et une règle
% de bon sens qui n'a pas de forme mathématique évidente.
%
% Ce que la logique floue apporte : on écrit les règles en français, et
% le système en tire une surface de décision continue.

fprintf('=== Logique floue : des regles en francais, une surface lisse ===\n\n');

%% 1. Les fonctions d'appartenance
% Un ensemble flou n'a pas de frontière nette : un service noté 4 sur 10
% est « médiocre » à 60 % et « moyen » à 40 %. La fonction d'appartenance
% dit à quel degré.
x = linspace(0, 10, 101);
triangle = trimf(x, [0 5 10]);
trapeze = trapmf(x, [0 2 8 10]);
gaussienne = gaussmf(x, [2 5]);
cloche = gbellmf(x, [2 4 5]);
sigmoide = sigmf(x, [2 5]);
fprintf('Fonctions d''appartenance :\n');
fprintf('  triangulaire : sommet en x = %.1f, valeur %.4f\n', ...
        x(triangle == max(triangle)), max(triangle));
assert(abs(max(triangle) - 1) < 1e-12, 'elle culmine a un');
assert(all(triangle >= 0), 'un degre d''appartenance est positif');
assert(abs(trimf(5, [0 5 10]) - 1) < 1e-12);
assert(trimf(0, [0 5 10]) == 0 && trimf(10, [0 5 10]) == 0);
% La gaussienne ne s'annule jamais : son support est infini, ce qui la
% distingue du triangle et du trapeze.
assert(all(gaussienne > 0));
fprintf('  gaussienne a x = 0 : %.6f (jamais nulle)\n', gaussmf(0, [2 5]));
% La sigmoide est monotone : elle sert aux notions du type « grand ».
assert(all(diff(sigmoide) >= -1e-12), 'la sigmoide est croissante');
fprintf('  sigmoide : de %.4f a %.4f\n', sigmoide(1), sigmoide(end));

%% 2. Bâtir le système
% Deux entrées, une sortie, et trois règles. C'est tout.
%
% MatLibre range les variables sous les champs « entrees » et « sorties »
% de la structure, là où MATLAB les nomme Inputs et Outputs ; GETFIS
% donne un accès nommé qui vaut dans les deux cas.
systeme = mamfis('Name', 'pourboire');
systeme = addInput(systeme, [0 10], 'Name', 'service');
systeme = addMF(systeme, 'service', 'gaussmf', [1.5 0], 'Name', 'mediocre');
systeme = addMF(systeme, 'service', 'gaussmf', [1.5 5], 'Name', 'bon');
systeme = addMF(systeme, 'service', 'gaussmf', [1.5 10], 'Name', 'excellent');
systeme = addInput(systeme, [0 10], 'Name', 'nourriture');
systeme = addMF(systeme, 'nourriture', 'trapmf', [0 0 1 3], 'Name', 'infecte');
systeme = addMF(systeme, 'nourriture', 'trapmf', [7 9 10 10], 'Name', 'delicieuse');
systeme = addOutput(systeme, [0 30], 'Name', 'pourboire');
systeme = addMF(systeme, 'pourboire', 'trimf', [0 5 10], 'Name', 'faible');
systeme = addMF(systeme, 'pourboire', 'trimf', [10 15 20], 'Name', 'moyen');
systeme = addMF(systeme, 'pourboire', 'trimf', [20 25 30], 'Name', 'genereux');
fprintf('\nSysteme : %d entrees, %d sortie(s)\n', ...
        numel(systeme.entrees), numel(systeme.sorties));
assert(numel(systeme.entrees) == 2);
assert(numel(systeme.entrees{1}.mf) == 3);
assert(numel(systeme.sorties{1}.mf) == 3);
assert(strcmp(systeme.entrees{1}.mf{2}.nom, 'bon'));

% Les règles, en clair. Chaque ligne donne : la modalité de chaque
% entrée, celle de la sortie, le poids, et l'opérateur — 1 pour ET,
% 2 pour OU. Un zéro veut dire « peu importe ».
%   si service est mediocre OU nourriture est infecte   -> pourboire faible
%   si service est bon                                  -> pourboire moyen
%   si service est excellent OU nourriture delicieuse   -> pourboire genereux
regles = [1 1 1 1 2;
          2 0 2 1 1;
          3 2 3 1 2];
systeme = addRule(systeme, regles);
% Les regles sont rangees dans une matrice, une ligne par regle.
fprintf('  %d regles\n', size(systeme.regles, 1));
assert(size(systeme.regles, 1) == 3);
% Elles s'ecrivent aussi en clair, ce qui est le propre de cette approche.
enClair = showrule(systeme);
assert(numel(enClair) == 3);
for k = 1:3
    fprintf('  %s\n', enClair{k});
end
assert(contains(enClair{1}, 'service est mediocre'));
assert(contains(enClair{1}, ' ou '), 'la premiere regle est une disjonction');
% La deuxieme n'a qu'une premisse : aucun connecteur n'apparait.
assert(~contains(enClair{2}, ' et ') && ~contains(enClair{2}, ' ou '));
assert(contains(enClair{2}, 'service est bon'));
assert(~contains(enClair{2}, 'nourriture'), 'le zero veut dire « peu importe »');
assert(contains(enClair{3}, 'pourboire est genereux'));

%% 3. Évaluer
% Le système ne choisit pas une règle : il les applique toutes, chacune à
% son degré, puis agrège. C'est ce qui rend la sortie continue là où une
% cascade de « si » donnerait des sauts.
cas = [1 2; 5 5; 9 9; 3 9; 9 2];
fprintf('\nEvaluation :\n');
sorties = zeros(size(cas, 1), 1);
for k = 1:size(cas, 1)
    sorties(k) = evalfis(cas(k, :), systeme);
    fprintf('  service %d, nourriture %2d -> pourboire %5.2f %%\n', ...
            cas(k, 1), cas(k, 2), sorties(k));
end
% Un mauvais repas donne moins qu'un bon : c'est la moindre des choses.
assert(sorties(1) < sorties(3), 'mieux servi, mieux paye');
assert(sorties(1) < 15 && sorties(3) > 15);
% Toutes les sorties restent dans la plage declaree.
assert(all(sorties >= 0 & sorties <= 30));

%% 4. La surface de décision
% C'est ce qui distingue la logique floue d'une table de décision : la
% sortie varie continûment, sans marche d'escalier.
grille = 0:0.5:10;
surface = zeros(numel(grille), numel(grille));
for i = 1:numel(grille)
    for j = 1:numel(grille)
        surface(i, j) = evalfis([grille(i) grille(j)], systeme);
    end
end
sautMaximal = max(max(abs(diff(surface, 1, 1))));
etendue = max(surface(:)) - min(surface(:));
fprintf('\nSurface de decision %dx%d :\n', numel(grille), numel(grille));
fprintf('  de %.2f a %.2f, etendue %.2f\n', min(surface(:)), max(surface(:)), etendue);
fprintf('  plus grand saut entre cases voisines : %.4f (%.0f %% de l''etendue)\n', ...
        sautMaximal, sautMaximal / etendue * 100);
% Une table de decision nette sauterait d'une conclusion a l'autre : ici
% dix points, la moitie de l'etendue. La surface floue reste bien en
% dessous, et c'est tout ce qu'on lui demande.
assert(sautMaximal < etendue / 5, 'la surface doit etre continue, sans marche');
% Elle est croissante en service, a nourriture fixee : le bon sens des
% regles se retrouve dans la surface.
milieu = surface(:, round(numel(grille) / 2));
assert(milieu(end) > milieu(1), 'plus de service, plus de pourboire');

%% 5. La défuzzification
% Passer d'un ensemble flou à un nombre. Le centre de gravité est la
% méthode usuelle : il tient compte de toute la forme, non du seul
% sommet.
abscisses = linspace(0, 30, 301);
ensemble = max(trimf(abscisses, [0 5 10]) * 0.3, trimf(abscisses, [20 25 30]) * 0.8);
fprintf('\nDefuzzification d''un ensemble a deux bosses :\n');
for methode = {'centroid', 'bisector', 'mom', 'som', 'lom'}
    valeur = defuzz(abscisses, ensemble, methode{1});
    fprintf('  %-9s : %.4f\n', methode{1}, valeur);
end
centre = defuzz(abscisses, ensemble, 'centroid');
maximum = defuzz(abscisses, ensemble, 'mom');
% Le centre de gravite est tire vers la bosse la plus haute, sans
% l'atteindre : la petite bosse compte encore.
assert(centre < maximum, 'la petite bosse tire le centre vers le bas');
assert(centre > 10, 'mais la grande bosse l''emporte');
% Le maximum le plus petit et le plus grand encadrent la moyenne des
% maximums.
assert(defuzz(abscisses, ensemble, 'som') <= maximum + 1e-9);
assert(defuzz(abscisses, ensemble, 'lom') >= maximum - 1e-9);

%% 6. Apprendre les règles depuis des données
% Quand on n'a pas de règles mais des exemples, le regroupement flou en
% trouve la structure.
rng(2);
donnees = [randn(60, 2) * 0.5; randn(60, 2) * 0.5 + 4];
[centres, appartenances] = fcm(donnees, 2);
fprintf('\nRegroupement flou en 2 groupes :\n');
fprintf('  centres : %s et %s\n', mat2str(round(centres(1, :), 3)), ...
        mat2str(round(centres(2, :), 3)));
assert(isequal(size(centres), [2 2]));
% Chaque point appartient aux deux groupes, a des degres qui somment a un :
% c'est ce qui distingue le regroupement flou du regroupement net.
assert(max(abs(sum(appartenances, 1) - 1)) < 1e-9, ...
       'les degres d''appartenance somment a un');
assert(all(appartenances(:) > 0), 'aucun degre n''est exactement nul');
% Les centres retrouves sont les vrais, a l'ordre pres.
distances = [min(norm(centres(1, :)), norm(centres(1, :) - 4)), ...
             min(norm(centres(2, :)), norm(centres(2, :) - 4))];
fprintf('  ecart aux vrais centres : %s\n', mat2str(round(distances, 3)));
assert(max(distances) < 0.6);

fprintf('\nToutes les verifications passent.\n');
