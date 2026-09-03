function [meilleurX, meilleureValeur, sortie] = matlibre_departs_multiples(probleme, nDeparts, trier, nEssais)
%MATLIBRE_DEPARTS_MULTIPLES Rouage commun de MULTISTART et GLOBALSEARCH.
%   Les points de départ sont tirés dans les bornes du problème — ou
%   autour de x0 quand il n'y en a pas. TRIER vrai fait d'abord évaluer
%   NESSAIS points et ne garde que les NDEPARTS meilleurs : c'est ce qui
%   distingue GlobalSearch de MultiStart.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if nargin < 4 || isempty(nEssais), nEssais = 10 * nDeparts; end
    fonction = probleme.objective;
    x0 = double(probleme.x0);
    if isempty(x0)
        error('globaloptim:run:Depart', ...
              'Le problème doit porter un point de départ.');
    end
    x0 = x0(:);
    n = numel(x0);
    bas = matlibre_borne(probleme.lb, n, x0 - 10);
    haut = matlibre_borne(probleme.ub, n, x0 + 10);
    candidats = zeros(n, nEssais);
    candidats(:, 1) = x0;
    for k = 2:nEssais
        candidats(:, k) = bas + (haut - bas) .* rand(n, 1);
    end
    if trier
        valeurs = zeros(1, nEssais);
        for k = 1:nEssais
            valeurs(k) = matlibre_valeur_objectif(fonction, candidats(:, k));
        end
        [~, ordre] = sort(valeurs);
        candidats = candidats(:, ordre(1:min(nDeparts, nEssais)));
    else
        candidats = candidats(:, 1:min(nDeparts, nEssais));
    end
    meilleureValeur = Inf;
    meilleurX = x0;
    for k = 1:size(candidats, 2)
        [x, valeur] = matlibre_resoudre_local(probleme, candidats(:, k));
        if valeur < meilleureValeur
            meilleureValeur = valeur;
            meilleurX = x;
        end
    end
    sortie = struct('funcCount', size(candidats, 2), ...
                    'localSolverTotal', size(candidats, 2), ...
                    'message', 'départs multiples terminés');
    meilleurX = reshape(meilleurX, size(probleme.x0));
end

function borne = matlibre_borne(valeur, n, defaut)
    if isempty(valeur)
        borne = defaut;
        return
    end
    borne = double(valeur(:));
    if numel(borne) == 1
        borne = repmat(borne, n, 1);
    end
    fini = isfinite(borne);
    borne(~fini) = defaut(~fini);
end

function v = matlibre_valeur_objectif(fonction, x)
    try
        v = fonction(x);
        v = sum(double(v(:)) .^ 2) * 0 + double(v(1));
    catch
        v = Inf;
    end
    if ~isfinite(v)
        v = Inf;
    end
end

function [x, valeur] = matlibre_resoudre_local(probleme, depart)
%MATLIBRE_RESOUDRE_LOCAL Un départ, passé au solveur local nommé.
    switch probleme.solver
        case 'fmincon'
            [x, valeur] = fmincon(probleme.objective, depart, probleme.Aineq, ...
                                  probleme.bineq, probleme.Aeq, probleme.beq, ...
                                  probleme.lb, probleme.ub, probleme.nonlcon);
        case 'fminunc'
            [x, valeur] = fminunc(probleme.objective, depart);
        case 'lsqnonlin'
            x = lsqnonlin(probleme.objective, depart, probleme.lb, probleme.ub);
            residus = probleme.objective(x);
            valeur = sum(double(residus(:)) .^ 2);
        case 'lsqcurvefit'
            x = lsqcurvefit(probleme.objective, depart, probleme.xdata, probleme.ydata);
            residus = probleme.objective(x, probleme.xdata) - probleme.ydata;
            valeur = sum(double(residus(:)) .^ 2);
        otherwise
            error('globaloptim:run:Solveur', ...
                  'Solveur inconnu : %s.', probleme.solver);
    end
    valeur = double(valeur);
    if ~isfinite(valeur)
        valeur = Inf;
    end
end
