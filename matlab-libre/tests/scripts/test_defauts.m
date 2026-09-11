% test_defauts.m — les défauts trouvés à la chasse, et leur correction.
% Chacun était silencieux : la fonction rendait un résultat vraisemblable
% et faux, ou ignorait ce qu'on lui demandait. Ce fichier existe pour
% qu'aucun ne revienne.
disp('--- defauts ---');

%% --------------------------- une option inconnue doit etre refusee
% Se replier sur le comportement par defaut rend un resultat faux sans
% que rien ne le dise. C'est le pire des defauts : il ne se voit pas.
refuse = @(f) verifierRefus(f);
assert(refuse(@() interp1([1 2 3], [1 4 9], 2.5, 'ceciNexistePas')));
assert(refuse(@() interp2([1 2; 1 2], [1 1; 2 2], [1 2; 3 4], 1.5, 1.5, 'inconnue')));
assert(refuse(@() sort([3 1 2], 'decroissant')));
assert(refuse(@() norm([1 2 3], 'frobenius')));
assert(refuse(@() histcounts([1 2 3], 'Normalization', 'inconnue')));
% Et ce qui est valide passe toujours.
assert(abs(interp1([1 2 3], [1 4 9], 2.5, 'linear') - 6.5) < 1e-12);
assert(isequal(sort([3 1 2], 'descend'), [3 2 1]));
assert(isequal(sort([3 1 2], 'ascend'), [1 2 3]));
assert(abs(norm([3 4]) - 5) < 1e-12);
assert(abs(norm([3 4], 1) - 7) < 1e-12);
assert(abs(norm([3 4], inf) - 4) < 1e-12);
assert(abs(norm([1 2; 3 4], 'fro') - sqrt(30)) < 1e-12);

%% -------------------- INTERP1 : chaque methode doit vraiment agir
% Se replier sur la lineaire pour 'spline' rendait une interpolation
% d'ordre un en se faisant passer pour une d'ordre trois.
xi = linspace(0, 1, 11);
vi = sin(pi * xi);
ecartLineaire = abs(interp1(xi, vi, 0.37, 'linear') - sin(pi * 0.37));
ecartSpline = abs(interp1(xi, vi, 0.37, 'spline') - sin(pi * 0.37));
assert(ecartSpline < ecartLineaire / 100);
assert(abs(interp1(xi, vi, 0.37, 'pchip') - interp1(xi, vi, 0.37, 'linear')) > 1e-4);

%% ---------------- ce qui n'a pas de valeur doit etre refuse, non devine
% Chacun de ces appels rendait un nombre qu'on pouvait croire.
assert(refuse(@() nthroot(-8, 2)));          % rendait NaN
assert(refuse(@() nchoosek(5, 7)));          % rendait 0
assert(refuse(@() circshift([1 2 3], 1.5))); % decalait de un
assert(refuse(@() factor(2.5)));             % rendait 2
assert(refuse(@() factor(0)));               % rendait [], de produit 1
assert(refuse(@() factor(-5)));
% Et ce qui est defini reste juste.
assert(abs(nthroot(-8, 3) + 2) < 1e-12);
assert(abs(nthroot(16, 4) - 2) < 1e-12);
assert(nchoosek(5, 2) == 10);
assert(nchoosek(5, 0) == 1 && nchoosek(5, 5) == 1);
assert(isequal(circshift([1 2 3], 1), [3 1 2]));
assert(isequal(factor(60), [2 2 3 5]));

%% ------------------------- CUMMAX et CUMMIN suivent une dimension
% Le balayage lineaire cumulait d'une colonne sur la suivante : la
% premiere valeur de la deuxieme colonne heritait du maximum de la
% premiere, ce qui est faux et se voyait a peine.
A = [3 1; 2 4];
assert(isequal(cummax(A), [3 1; 3 4]));
assert(isequal(cummin(A), [3 1; 2 1]));
assert(isequal(cummax(A, 2), [3 3; 2 4]));
assert(isequal(cummin(A, 2), [3 1; 2 2]));
% Le cumul d'un extremum est croissant ou decroissant, jamais autre chose.
rand('seed', 21);
B = rand(6, 4);
assert(all(all(diff(cummax(B), 1, 1) >= -1e-15)));
assert(all(all(diff(cummin(B), 1, 1) <= 1e-15)));
% Et sa derniere ligne vaut l'extremum de la colonne entiere.
assert(max(abs(cummax(B)(end, :) - max(B, [], 1))) < 1e-15);
assert(max(abs(cummin(B)(end, :) - min(B, [], 1))) < 1e-15);
% Un NaN ne remplace pas l'accumulateur.
assert(isequal(cummax([1 NaN 3]), [1 1 3]));

%% ----------------------- TRAPZ et CUMTRAPZ suivent une dimension
% Un second argument scalaire est la dimension, non une abscisse :
% trapz(ones(3,4), 2) prenait 2 pour une abscisse et rendait zero.
assert(isequal(trapz(ones(3, 4), 2), [3; 3; 3]));
assert(isequal(trapz(ones(3, 4)), [2 2 2 2]));
assert(abs(trapz(1:4) - 7.5) < 1e-12);
assert(abs(trapz([1 2 3], [1 2 3]) - 4) < 1e-12);
% Sur une fonction dont l'integrale s'ecrit, la regle du trapeze converge.
x = linspace(0, pi, 10001);
assert(abs(trapz(x, sin(x)) - 2) < 1e-7);
% Doubler les points divise l'erreur par quatre : la regle est d'ordre deux.
e1 = abs(trapz(linspace(0, pi, 101), sin(linspace(0, pi, 101))) - 2);
e2 = abs(trapz(linspace(0, pi, 201), sin(linspace(0, pi, 201))) - 2);
assert(abs(e1 / e2 - 4) < 0.2);
% CUMTRAPZ finit sur la valeur que TRAPZ rend.
assert(abs(cumtrapz(x, sin(x))(end) - trapz(x, sin(x))) < 1e-12);
assert(isequal(cumtrapz(ones(3, 2)), [0 0; 1 1; 2 2]));
assert(isequal(size(cumtrapz(ones(3, 4), 2)), [3 4]));

%% -------------------- MAX et MIN d'un vide ne rendent qu'une valeur
% En rendre deux faisait de « max([]) » une liste : passee en argument,
% elle en comptait deux, et isempty(max([])) echouait.
assert(isempty(max([])));
assert(isempty(min([])));
assert(numel({max([])}) == 1);
assert(numel({min([])}) == 1);
[valeur, indice] = max([]);
assert(isempty(valeur) && isempty(indice));

%% ------------------------ UNIQUE rend ses indices en colonnes
% C'est la regle de MATLAB, et elle compte : « x(ia) » rendait une ligne
% la ou le code appelant attendait une colonne.
x = [3 1 3 2];
[u, ia, ic] = unique(x);
assert(size(ia, 2) == 1 && size(ic, 2) == 1);
assert(isequal(x(ia)(:), u(:)));      % la propriete qui definit ia
assert(isequal(u(ic)(:), x(:)));      % celle qui definit ic
% Sur une colonne aussi.
[u2, ia2, ic2] = unique([3; 1; 3; 2]);
assert(size(ia2, 2) == 1 && size(ic2, 2) == 1);
assert(isequal(u2(ic2), [3; 1; 3; 2]));

%% ------------------------------- MODE rend aussi sa frequence
[m, f] = mode([1 2 2 3]);
assert(m == 2 && f == 2);
[m2, f2, c2] = mode([1 1 2 2 3]);
assert(m2 == 1 && f2 == 2);           % a egalite, le plus petit gagne
assert(isequal(sort(c2{1}(:))', [1 2]));
% Sur une matrice, une reponse par colonne.
assert(isequal(mode([1 5; 1 6; 2 6]), [1 6]));

%% ---------------------- HISTCOUNTS normalise ce qu'on lui demande
donnees = [1 1 2 2 2 3];
bords = [0.5 1.5 2.5 3.5];
assert(isequal(histcounts(donnees, bords), [2 3 1]));
% 'probability' somme a un.
p = histcounts(donnees, bords, 'Normalization', 'probability');
assert(abs(sum(p) - 1) < 1e-12);
% 'pdf' a une integrale de un : c'est une densite, non des effectifs.
d = histcounts(donnees, bords, 'Normalization', 'pdf');
assert(abs(sum(d .* diff(bords)) - 1) < 1e-12);
% 'cdf' finit a un et ne decroit jamais.
c = histcounts(donnees, bords, 'Normalization', 'cdf');
assert(abs(c(end) - 1) < 1e-12);
assert(all(diff(c) >= -1e-15));
assert(isequal(histcounts(donnees, bords, 'Normalization', 'cumcount'), [2 5 6]));

%% --------------------- REGEXP rend vraiment ses groupes nommes
% « names » etait documente et rendait une structure vide.
n = regexp('x=1', '(?<nom>\w)=(?<val>\d)', 'names');
assert(isfield(n, 'nom') && isfield(n, 'val'));
assert(strcmp(n.nom, 'x') && strcmp(n.val, '1'));
% Une structure par correspondance.
m3 = regexp('a=1 b=2', '(?<c>\w)=(?<v>\d)', 'names');
assert(numel(m3) == 2);
assert(strcmp(m3(1).c, 'a') && strcmp(m3(2).v, '2'));
% Les groupes ordinaires et les groupes non capturants restent intacts.
t = regexp('nom: Jean', '(\w+): (\w+)', 'tokens');
assert(strcmp(t{1}{1}, 'nom') && strcmp(t{1}{2}, 'Jean'));
assert(strcmp(regexp('abc', '(?:a)(b)', 'tokens'){1}{1}, 'b'));
% Un nom melange a un groupe anonyme garde le bon rang.
melange = regexp('ab12', '(?<lettres>[a-z]+)(\d+)', 'names');
assert(strcmp(melange.lettres, 'ab'));

%% ------------------ FUNC2STR n'ajoute pas de parentheses inutiles
% Le texte doit se lire, et surtout se relire : l'aller-retour par
% STR2FUNC ne doit rien changer a ce que la poignee calcule.
assert(strcmp(func2str(@(y) y + 1), '@(y) y + 1'));
assert(isempty(strfind(func2str(@(x) x + 1), '((')));
% Les parentheses qui portent un sens restent.
assert(~isempty(strfind(func2str(@(a, b, c) a - (b - c)), '(b - c)')));
for poignee = {@(x) x^3 - 2*x + 1, @(a,b) (a + b) * (a - b), @(x) -x^2 + 3, ...
               @(a,b,c) a - (b - c), @(x) 1 / (1 + exp(-x))}
    refaite = str2func(func2str(poignee{1}));
    for essai = [0.3 1 2.5]
        try
            attendu = poignee{1}(essai, essai + 1, essai + 2);
            obtenu = refaite(essai, essai + 1, essai + 2);
        catch
            attendu = poignee{1}(essai);
            obtenu = refaite(essai);
        end
        assert(abs(attendu - obtenu) < 1e-12);
    end
end

disp('defauts : toutes les verifications passent');

function ok = verifierRefus(f)
% Vrai si l'appel leve une erreur, faux s'il passe.
    ok = false;
    try
        f();
    catch
        ok = true;
    end
end
