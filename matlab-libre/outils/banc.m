% banc.m — le banc de performance de MatLibre.
%
%   build/bin/matlibre --path toolbox outils/banc.m
%
% Mesure une vingtaine d'opérations représentatives — l'interpréteur
% (boucles, appels, indexation), la copie sur écriture, le calcul
% vectoriel, l'algèbre linéaire, le texte, le rendu graphique, le
% démarrage d'un parfor, une simulation Simulink — et compare chaque temps
% à sa référence : le plus lent de trois passages sur le conteneur de
% développement (quatre cœurs), le 21 novembre 2026, au commit de
% documentation/reprise.md. Un rapport au-delà de 1,5
% mérite qu'on regarde ; au-delà de 3, c'est une régression, ou une autre
% machine. Chaque mesure est la meilleure de trois, pour écarter le bruit.
% Chaque résultat est aussi vérifié : un banc qui calcule faux ne mesure
% rien.
%
% Le banc ne remplace pas les tests : il dit si c'est devenu lent, non si
% c'est juste.
%
% Exemple :
%    build/bin/matlibre --path toolbox outils/banc.m
%
% Voir aussi outils/audit.m, outils/manques.m.

mesures = {};

% --- l'interpréteur ----------------------------------------------------
mesures(end + 1, :) = {'boucle scalaire (1e6 tours)', meilleur(@boucleScalaire), 0.45};
mesures(end + 1, :) = {'appels de fonction (2e5)', meilleur(@appels), 0.26};
mesures(end + 1, :) = {'recursion (2^14 feuilles)', meilleur(@recursion), 0.155};
mesures(end + 1, :) = {'z(k) = k (1e5)', meilleur(@affectationIndexee), 0.04};
mesures(end + 1, :) = {'croissance g(end+1) (2e4)', meilleur(@croissance), 0.012};
mesures(end + 1, :) = {'champ s.a(k) (2e4)', meilleur(@champ), 0.008};
mesures(end + 1, :) = {'cellule c{k} (2e4)', meilleur(@cellules), 0.021};
% --- la copie sur écriture ---------------------------------------------
mesures(end + 1, :) = {'200 appels sur 16 Mo', meilleur(@argumentsLourds), 0.0021};
% --- le calcul vectoriel -------------------------------------------------
mesures(end + 1, :) = {'elementaire 1500x1500', meilleur(@elementaire), 0.17};
mesures(end + 1, :) = {'sort de 2,25e6', meilleur(@tri), 0.69};
mesures(end + 1, :) = {'produit 1500x1500 par 1500x200', meilleur(@produit), 0.23};
mesures(end + 1, :) = {'fft de 2^20', meilleur(@transformee), 0.08};
% --- l'algèbre linéaire --------------------------------------------------
mesures(end + 1, :) = {'A\b, 600x600', meilleur(@resolution), 0.104};
mesures(end + 1, :) = {'eig, 300x300 symetrique', meilleur(@valeursPropres), 0.27};
mesures(end + 1, :) = {'svd, 300x300', meilleur(@valeursSingulieres), 0.44};
% --- le texte ------------------------------------------------------------
mesures(end + 1, :) = {'sprintf et strjoin (2e4)', meilleur(@texte), 0.091};
mesures(end + 1, :) = {'jsondecode (4000 nombres)', meilleur(@json), 0.61};
mesures(end + 1, :) = {'regexprep (1e4 lignes)', meilleur(@expressions), 0.036};
% --- le rendu ------------------------------------------------------------
mesures(end + 1, :) = {'plot de 1e5 points en SVG', meilleur(@tracePlan), 0.005};
mesures(end + 1, :) = {'surf(peaks(60)) en SVG', meilleur(@traceEspace), 0.019};
% --- le parallélisme et Simulink -----------------------------------------
% Le parfor vide coutait 0,23 s : chaque travailleur indexait le chemin
% dossier par dossier, en temps quadratique. Une seule indexation
% (c16566f) l'a ramene a 0,012 s ; la reference suit, sans quoi le banc
% ne verrait pas ce cout revenir.
mesures(end + 1, :) = {'parfor de 8 tours vides', meilleur(@parforVide), 0.015};
mesures(end + 1, :) = {'sim d''un modele a 4 blocs', meilleur(@simulation), 0.107};

fprintf('\n%-34s %10s %10s %8s\n', 'operation', 'temps (s)', 'reference', 'rapport');
fprintf('%s\n', repmat('-', 1, 66));
lents = 0;
for k = 1:size(mesures, 1)
    rapport = mesures{k, 2} / mesures{k, 3};
    marque = '';
    if rapport > 3
        marque = '  << regression ?';
        lents = lents + 1;
    elseif rapport > 1.5
        marque = '  < a regarder';
    end
    fprintf('%-34s %10.4f %10.4f %8.2f%s\n', mesures{k, 1}, mesures{k, 2}, mesures{k, 3}, ...
            rapport, marque);
end
fprintf('%s\n', repmat('-', 1, 66));
fprintf('%d mesure(s) plus de trois fois plus lente(s) que la reference.\n', lents);

% ------------------------------------------------------------------------

function t = meilleur(f)
    % La meilleure de trois : le bruit du système n'allonge qu'un essai.
    t = inf;
    for essai = 1:3
        debut = tic;
        f();
        t = min(t, toc(debut));
    end
end

function boucleScalaire()
    s = 0;
    for k = 1:1e6
        s = s + k * 0.5;
    end
    assert(s == 0.5 * 1e6 * (1e6 + 1) / 2);
end

function appels()
    s = 0;
    for k = 1:2e5
        s = s + carre(k);
    end
    assert(s > 0);
end

function y = carre(x)
    y = x * x;
end

function recursion()
    v = 1:2^14;
    assert(sommeRec(v) == sum(v));
end

function s = sommeRec(v)
    if numel(v) <= 2
        s = sum(v);
        return
    end
    m = floor(numel(v) / 2);
    s = sommeRec(v(1:m)) + sommeRec(v(m + 1:end));
end

function affectationIndexee()
    z = zeros(1, 1e5);
    for k = 1:1e5
        z(k) = k;
    end
    assert(isequal(z, 1:1e5));
end

function croissance()
    g = [];
    for k = 1:2e4
        g(end + 1) = k; %#ok<AGROW>
    end
    assert(numel(g) == 2e4);
end

function champ()
    s.a = zeros(1, 2e4);
    for k = 1:2e4
        s.a(k) = k;
    end
    assert(s.a(end) == 2e4);
end

function cellules()
    c = cell(1, 2e4);
    for k = 1:2e4
        c{k} = k;
    end
    assert(c{end} == 2e4);
end

function argumentsLourds()
    x = zeros(2e6, 1);
    for k = 1:200
        y = premier(x);
    end
    assert(y == 0);
end

function y = premier(x)
    y = x(1);
end

function elementaire()
    rng(0);
    A = rand(1500);
    B = A .* A + 1 - A ./ (1 + A);
    assert(all(B(:) > 0));
end

function tri()
    rng(0);
    v = sort(rand(1500 * 1500, 1));
    assert(issorted(v));
end

function produit()
    rng(0);
    A = rand(1500);
    P = A * A(:, 1:200);
    assert(isequal(size(P), [1500 200]));
end

function transformee()
    rng(0);
    x = rand(2^20, 1);
    X = fft(x);
    assert(abs(X(1) - sum(x)) < 1e-6 * sum(x));
end

function resolution()
    rng(0);
    A = rand(600) + 600 * eye(600);
    b = rand(600, 1);
    x = A \ b;
    assert(norm(A * x - b) < 1e-8);
end

function valeursPropres()
    rng(0);
    A = rand(300);
    A = A + A';
    e = eig(A);
    assert(abs(sum(e) - trace(A)) < 1e-8 * abs(trace(A)));
end

function valeursSingulieres()
    rng(0);
    A = rand(300);
    s = svd(A);
    assert(abs(s(1) - norm(A)) < 1e-8 * s(1));
end

function texte()
    morceaux = cell(1, 2e4);
    for k = 1:2e4
        morceaux{k} = sprintf('%d:%.2f', k, k / 3);
    end
    assert(numel(strjoin(morceaux, ',')) > 1e5);
end

function json()
    t = ['[' strjoin(arrayfun(@(v) sprintf('%g', v), 1:4000, 'UniformOutput', false), ',') ']'];
    v = jsondecode(t);
    assert(numel(v) == 4000);
end

function expressions()
    lignes = repmat({'valeur_12 = 3.5e-2; % commentaire'}, 1, 1e4);
    r = regexprep(lignes, '(\w+)_(\d+)', '$2-$1');
    assert(strcmp(r{end}, '12-valeur = 3.5e-2; % commentaire'));
end

function tracePlan()
    figure('Visible', 'off');
    plot(sin((1:1e5) / 1e3));
    s = matlibre_svg();
    close;
    assert(numel(s) > 1000);
end

function traceEspace()
    figure('Visible', 'off');
    surf(peaks(60));
    s = matlibre_svg();
    close;
    assert(numel(strfind(s, '<path')) > 3000);
end

function parforVide()
    v = zeros(1, 8);
    parfor k = 1:8
        v(k) = k;
    end
    assert(isequal(v, 1:8));
end

function simulation()
    m = new_system('banc_modele');
    m = add_block(m, 'sine', 'source');
    m = add_block(m, 'gain', 'g', 'Gain', 2);
    m = add_block(m, 'integrator', 'i');
    m = add_block(m, 'outport', 'y');
    m = add_line(add_line(add_line(m, 'source', 'g'), 'g', 'i'), 'i', 'y');
    r = sim(m, 'StopTime', 10, 'Solver', 'ode45');
    assert(abs(r.yout(end) - 2 * (1 - cos(10))) < 1e-6);
end
