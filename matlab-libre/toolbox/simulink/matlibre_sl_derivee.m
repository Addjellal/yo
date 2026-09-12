function [dx, y] = matlibre_sl_derivee(modele, x, u, pas)
%MATLIBRE_SL_DERIVEE Dérivée d'état et sortie d'un modèle en un point.
%   [DX,Y] = MATLIBRE_SL_DERIVEE(MODELE,X,U,PAS) place les états
%   continus à X et les entrées à U, simule un seul instant, et relève la
%   dérivée de chaque état ainsi que la valeur de chaque sortie.
%
%   La dérivée ne se mesure pas : elle se lit. L'entrée d'un intégrateur
%   est sa dérivée, et le simulateur relève déjà la sortie de chaque
%   bloc. Pour une représentation d'état, c'est A x + B u, calculé sur
%   l'entrée relevée.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      m = new_system('chaine');
%      m = add_block(m, 'inport', 'u', 'Port', 1);
%      m = add_block(m, 'gain', 'k', 'Gain', 3);
%      m = add_block(m, 'integrator', 'x');
%      m = add_line(m, 'u', 'k');
%      m = add_line(m, 'k', 'x');
%      matlibre_sl_derivee(m, 0, 2, 1e-3)     % 6 : la dérivée vaut 3*u
%
%   Voir aussi LINMOD, DLINMOD, TRIM, SIM.
    [blocsEtat, rangs, entrees, sorties] = matlibre_sl_etats(modele);
    x = x(:);
    u = u(:);
    for i = 1:numel(blocsEtat)
        k = blocsEtat(i);
        bloc = modele.blocs{k};
        part = x(rangs{i});
        if strcmp(bloc.type, 'integrator')
            modele.blocs{k}.parametres.InitialCondition = part(1);
        else
            modele.blocs{k}.parametres.X0 = part;
        end
    end
    for j = 1:numel(entrees)
        modele.blocs{entrees(j)}.parametres.Value = u(j);
    end

    resultat = sim(modele, 0, pas);
    valeurs = zeros(1, numel(modele.blocs));
    for k = 1:numel(modele.blocs)
        valeurs(k) = resultat.signals(k).values(1);
    end

    y = zeros(numel(sorties), 1);
    for j = 1:numel(sorties)
        y(j) = valeurs(sorties(j));
    end

    dx = zeros(numel(x), 1);
    for i = 1:numel(blocsEtat)
        k = blocsEtat(i);
        bloc = modele.blocs{k};
        amont = valeurEntree(modele, valeurs, k);
        if strcmp(bloc.type, 'integrator')
            dx(rangs{i}) = amont;
        else
            [A, B] = matricesEtat(bloc);
            dx(rangs{i}) = A * x(rangs{i}) + B * amont;
        end
    end
end

% La valeur qui arrive sur la première entrée d'un bloc : la sortie du
% bloc qui l'alimente, ou zéro si rien ne l'alimente.
function v = valeurEntree(modele, valeurs, k)
    v = 0;
    for l = 1:size(modele.liens, 1)
        if modele.liens(l, 2) == k && modele.liens(l, 3) == 1
            v = valeurs(modele.liens(l, 1));
            return
        end
    end
end

function [A, B] = matricesEtat(bloc)
    if strcmp(bloc.type, 'transferfcn')
        [A, B] = tf2ss(lireNombre(bloc, 'Numerator', 1), ...
                       lireNombre(bloc, 'Denominator', 1));
    else
        A = lireNombre(bloc, 'A', 0);
        B = lireNombre(bloc, 'B', 0);
    end
end

function v = lireParametre(bloc, nom, defaut)
    if isfield(bloc.parametres, nom)
        v = bloc.parametres.(nom);
    else
        v = defaut;
    end
end

% Comme dans SIM, un paramètre numérique peut être une expression : il
% vaut alors ce que vaut l'espace de travail de base au moment du calcul.
function v = lireNombre(bloc, nom, defaut)
    v = lireParametre(bloc, nom, defaut);
    if ischar(v) || isstring(v)
        v = matlibre_sl_expression(char(v), bloc.nom, nom);
    end
end
