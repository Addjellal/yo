%% Calcul parallèle : distribuer un calcul indépendant
% Ce qui se parallélise est ce qui ne communique pas : chaque élément
% traité seul, sans savoir ce que les autres deviennent. C'est la
% condition, et elle est plus restrictive qu'il n'y paraît.
%
% Voir aussi PARARRAYFUN, PARCELLFUN, DISTRIBUTED, GATHER.

fprintf('=== Calcul parallele ===\n');

%% 1. PARARRAYFUN, l'équivalent parallèle d'ARRAYFUN
% Le contrat est le même : une fonction, un tableau, un résultat par
% élément. Ce qui change est seulement l'ordre d'exécution — et il ne
% doit rien changer au résultat.
v = pararrayfun(@(x) x ^ 2, 1:8);
fprintf('\nCarres de 1 a 8 : %s\n', mat2str(v));
assert(isequal(v, (1:8) .^ 2), 'chaque element est traite');
% Le résultat est identique à celui d'ARRAYFUN : c'est la seule garantie
% qui compte, et elle interdit toute dépendance à l'ordre.
assert(isequal(pararrayfun(@(x) x^2, 1:50), arrayfun(@(x) x^2, 1:50)), ...
       'pararrayfun rend exactement ce que rend arrayfun');
fprintf('  identique a arrayfun sur cinquante elements\n');

% Plusieurs tableaux en entrée, élément par élément.
somme = pararrayfun(@(a, b) a + b, 1:5, 10:10:50);
fprintf('  deux tableaux : %s\n', mat2str(somme));
assert(isequal(somme, (1:5) + (10:10:50)), 'les tableaux s''apparient element par element');

% Sortie non uniforme : chaque résultat dans sa case.
c = pararrayfun(@(n) ones(1, n), 1:4, 'UniformOutput', false);
fprintf('  sortie non uniforme : %s\n', ...
        mat2str(cellfun(@numel, c)));
assert(iscell(c) && numel(c) == 4, 'quatre cases');
assert(isequal(cellfun(@numel, c), 1:4), 'de tailles croissantes');

% Plusieurs sorties : autant que la fonction en donne.
[q, r] = pararrayfun(@(x) deal(floor(x / 3), mod(x, 3)), 1:9);
fprintf('  division par 3 : quotients %s, restes %s\n', mat2str(q), mat2str(r));
assert(isequal(q .* 3 + r, 1:9), 'quotient et reste se recomposent');

% Le type du résultat suit celui que la fonction rend : un prédicat rend
% un tableau logique, non un tableau de zéros et de uns.
grands = pararrayfun(@(x) x > 3, 1:6);
fprintf('  predicat : %s, de classe %s\n', mat2str(grands), class(grands));
assert(islogical(grands), 'un predicat rend un tableau logique');
assert(isequal(grands, (1:6) > 3), 'et le bon');

% Un gestionnaire d'erreur reprend la main quand la fonction échoue,
% plutôt que de laisser tomber tout le calcul pour un élément.
secours = pararrayfun(@(x) 1 / (x - 3) + erreurSi(x == 3), 1:5, ...
                      'ErrorHandler', @(description, x) NaN);
fprintf('  avec gestionnaire d''erreur : %s\n', mat2str(round(secours, 4)));
assert(isnan(secours(3)), 'l''element fautif rend ce que dit le gestionnaire');
assert(sum(~isnan(secours)) == 4, 'et les autres passent normalement');

%% 2. PARCELLFUN, sur des cellules
noms = {'a', 'bb', 'ccc', 'dddd'};
tailles = parcellfun(@numel, noms);
fprintf('\nLongueurs de %s : %s\n', strjoin(noms, ', '), mat2str(tailles));
assert(isequal(tailles, [1 2 3 4]), 'une longueur par case');
assert(isequal(parcellfun(@numel, noms), cellfun(@numel, noms)), ...
       'parcellfun rend ce que rend cellfun');
majuscules = parcellfun(@upper, noms, 'UniformOutput', false);
fprintf('  en majuscules : %s\n', strjoin(majuscules, ', '));
assert(isequal(majuscules, {'A', 'BB', 'CCC', 'DDDD'}), 'chaque case transformee');

%% 3. Ce qui se parallélise, et ce qui ne se parallélise pas
% Un calcul dont chaque terme dépend du précédent ne se distribue pas :
% c'est une dépendance de données, et aucun ordonnanceur ne la contourne.
% Le montrer vaut mieux que de l'affirmer.
%
% La somme des inverses des carrés se parallélise : chaque terme est
% indépendant, et la somme se fait après. Elle converge vers pi^2/6.
n = 2000;
termes = pararrayfun(@(k) 1 / k^2, 1:n);
approche = sum(termes);
fprintf('\nSomme des inverses des carres, %d termes :\n', n);
fprintf('  %.10f, contre pi^2/6 = %.10f\n', approche, pi^2/6);
assert(abs(approche - pi^2/6) < 1e-3, 'la serie converge vers pi carre sur six');
% Chaque terme ne dépend que de son indice : voilà pourquoi cela marche.
assert(abs(termes(100) - 1/100^2) < 1e-15, 'chaque terme se calcule seul');

% La suite de Fibonacci, elle, ne se parallélise pas de cette façon :
% chaque terme demande les deux précédents. On peut la calculer terme à
% terme par sa forme fermée — mais c'est alors un autre calcul, où la
% dépendance a été éliminée par les mathématiques, non par la machine.
phi = (1 + sqrt(5)) / 2;
fibonacci = pararrayfun(@(k) round((phi^k - (-phi)^(-k)) / sqrt(5)), 1:20);
fprintf('  Fibonacci par forme fermee : %s...\n', mat2str(fibonacci(1:8)));
suite = zeros(1, 20);
suite(1) = 1; suite(2) = 1;
for k = 3:20
    suite(k) = suite(k-1) + suite(k-2);
end
assert(isequal(fibonacci, suite), ...
       'la forme fermee retrouve la recurrence, terme a terme');
fprintf('  identique a la recurrence sequentielle : la dependance a ete levee\n');
fprintf('  par les mathematiques, non par la machine\n');

%% 4. Le déterminisme
% Un calcul parallèle correct rend toujours le même résultat. Le vérifier
% n'est pas superflu : c'est là que les erreurs de parallélisation se
% voient, quand elles se voient.
rng(1);
donnees = randn(1, 100);
premier = pararrayfun(@(x) tanh(x) + x^3, donnees);
for essai = 1:3
    assert(isequal(pararrayfun(@(x) tanh(x) + x^3, donnees), premier), ...
           'le resultat ne depend pas de l''ordre d''execution');
end
fprintf('\nQuatre executions du meme calcul sur %d elements : identiques\n', ...
        numel(donnees));

%% 5. Tableaux distribués
% Sur une seule machine, DISTRIBUTED et GATHER sont l'identité. Ils ne
% sont pas décoratifs pour autant : ils marquent dans le code où les
% données passeraient d'une machine à l'autre, et un programme écrit avec
% eux tourne sans changement sur un vrai pool.
A = magic(4);
d = distributed(A);
fprintf('\nTableau distribue : %s, rapatrie identique : %d\n', ...
        mat2str(size(d)), isequal(gather(d), A));
assert(isequal(gather(distributed(A)), A), 'gather annule distributed');
% Sur un tableau vide comme sur une chaîne, le contrat tient.
assert(isequal(gather(distributed([])), []), 'y compris sur un tableau vide');
assert(isequal(gather(distributed('texte')), 'texte'), 'et sur du texte');
% Et le calcul se fait normalement entre les deux.
somme = gather(distributed(A)) + 1;
assert(isequal(somme, A + 1), 'le calcul entre les deux se fait normalement');

fprintf('\nToutes les verifications passent.\n');

function v = erreurSi(condition)
% Lève une erreur pour éprouver le gestionnaire, et rend zéro sinon.
    if condition
        error('exemple:parallele:Provoquee', 'erreur voulue');
    end
    v = 0;
end
