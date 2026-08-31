function [h, p, statistiques] = chi2gof(x, varargin)
%CHI2GOF Test du khi-deux d'adéquation.
%   H = CHI2GOF(X) teste l'hypothèse « X suit une loi normale ». Les
%   observations sont réparties en classes, et l'on compare l'effectif
%   observé de chaque classe à celui qu'on attendrait sous la loi. La
%   statistique est
%
%      chi2 = somme (observe - attendu)^2 / attendu
%
%   qui suit une loi du khi-deux à K-1-P degrés de liberté, où K est le
%   nombre de classes et P le nombre de paramètres estimés sur les
%   données — deux pour une normale ajustée.
%
%   [H,P] = CHI2GOF(...) rend la probabilité critique.
%   [H,P,STATS] = CHI2GOF(...) rend le détail : les bords des classes,
%   les effectifs observés et attendus, la statistique et les degrés de
%   liberté.
%
%   CHI2GOF(...,'NBins',N) fixe le nombre de classes, dix par défaut.
%   CHI2GOF(...,'Edges',E) impose les bords des classes.
%   CHI2GOF(...,'CDF',F) teste une autre loi que la normale : F est une
%   poignée de fonction qui rend la répartition, par exemple
%   @(t) expcdf(t, 2). Aucun paramètre n'est alors compté comme estimé.
%   CHI2GOF(...,'Expected',E) donne directement les effectifs attendus,
%   ce qui teste une loi discrète connue.
%   CHI2GOF(...,'NParams',P) dit combien de paramètres ont été estimés.
%   CHI2GOF(...,'EMin',M) fusionne les classes dont l'effectif attendu
%   tombe sous M, cinq par défaut : l'approximation du khi-deux ne vaut
%   que si les classes sont assez garnies.
%   CHI2GOF(...,'Alpha',A) change le seuil.
%
%   Exemples :
%      chi2gof(randn(500, 1))                      % 0 : normal
%      chi2gof(exprnd(1, 500, 1))                  % 1 : ne l'est pas
%      chi2gof(exprnd(2, 500, 1), 'CDF', @(t) expcdf(t, 2))
%
%      % Un de six faces, lance six cents fois
%      des = randi(6, 600, 1);
%      chi2gof(des, 'Edges', 0.5:1:6.5, 'Expected', repmat(100, 1, 6))
%
%   Voir aussi KSTEST, LILLIETEST, JBTEST, CROSSTAB, HISTCOUNTS.
    nombreClasses = 10;
    bords = [];
    repartition = [];
    attendus = [];
    nombreParametres = -1;
    effectifMinimum = 5;
    alpha = 0.05;
    k = 1;
    while k + 1 <= numel(varargin)
        nom = lower(char(varargin{k}));
        switch nom
            case 'nbins'
                nombreClasses = varargin{k + 1};
            case 'edges'
                bords = varargin{k + 1};
            case 'cdf'
                repartition = varargin{k + 1};
            case 'expected'
                attendus = varargin{k + 1};
            case 'nparams'
                nombreParametres = varargin{k + 1};
            case 'emin'
                effectifMinimum = varargin{k + 1};
            case 'alpha'
                alpha = varargin{k + 1};
            case {'frequency', 'ctrs'}
                % acceptés et sans effet
            otherwise
                error('stats:chi2gof:BadOption', 'Unknown option ''%s''.', nom);
        end
        k = k + 2;
    end
    x = x(:);
    x = x(~isnan(x));
    n = numel(x);
    if n < 2
        error('stats:chi2gof:NotEnoughData', 'CHI2GOF needs at least two values.');
    end

    if isempty(bords)
        % Des classes de largeur égale, ouvertes aux deux bouts pour que
        % rien ne tombe dehors.
        bas = min(x);
        haut = max(x);
        if bas == haut
            haut = bas + 1;
        end
        bords = linspace(bas, haut, nombreClasses + 1);
    end
    bords = bords(:)';
    bordsOuverts = bords;
    bordsOuverts(1) = -Inf;
    bordsOuverts(end) = Inf;

    observes = zeros(1, numel(bords) - 1);
    for i = 1:numel(observes)
        if i < numel(observes)
            observes(i) = sum(x >= bordsOuverts(i) & x < bordsOuverts(i + 1));
        else
            observes(i) = sum(x >= bordsOuverts(i) & x <= bordsOuverts(i + 1));
        end
    end

    if isempty(attendus)
        if isempty(repartition)
            % Normale ajustée sur les données : deux paramètres estimés.
            m = mean(x);
            s = std(x);
            if s == 0
                s = 1;
            end
            F = normcdf((bordsOuverts - m) / s);
            if nombreParametres < 0
                nombreParametres = 2;
            end
        else
            F = zeros(1, numel(bordsOuverts));
            for i = 1:numel(bordsOuverts)
                if bordsOuverts(i) == -Inf
                    F(i) = 0;
                elseif bordsOuverts(i) == Inf
                    F(i) = 1;
                else
                    F(i) = repartition(bordsOuverts(i));
                end
            end
            if nombreParametres < 0
                nombreParametres = 0;
            end
        end
        attendus = n * diff(F);
    else
        attendus = attendus(:)';
        if numel(attendus) ~= numel(observes)
            error('stats:chi2gof:InputSizeMismatch', ...
                  'EXPECTED must have one value per bin.');
        end
        if nombreParametres < 0
            nombreParametres = 0;
        end
    end

    % Fusion des classes trop peu garnies, des extrémités vers le centre.
    [observes, attendus] = fusionner(observes, attendus, effectifMinimum);
    K = numel(observes);
    ddl = K - 1 - nombreParametres;
    if ddl < 1
        error('stats:chi2gof:NotEnoughBins', ...
              'Too few bins remain after merging: reduce NPARAMS or EMIN.');
    end
    chi2 = sum((observes - attendus) .^ 2 ./ attendus);
    p = 1 - chi2cdf(chi2, ddl);
    h = double(p < alpha);
    statistiques = struct('chi2stat', chi2, 'df', ddl, 'edges', bords, ...
                          'O', observes, 'E', attendus);
end

function [observes, attendus] = fusionner(observes, attendus, minimum)
%FUSIONNER Réunit les classes dont l'effectif attendu est trop faible.
%   On part de la gauche, puis de la droite : ce sont les queues qui sont
%   dégarnies, et les fusionner vers le centre garde des classes
%   contiguës.
    while numel(attendus) > 2 && attendus(1) < minimum
        attendus(2) = attendus(2) + attendus(1);
        observes(2) = observes(2) + observes(1);
        attendus(1) = [];
        observes(1) = [];
    end
    while numel(attendus) > 2 && attendus(end) < minimum
        attendus(end - 1) = attendus(end - 1) + attendus(end);
        observes(end - 1) = observes(end - 1) + observes(end);
        attendus(end) = [];
        observes(end) = [];
    end
    % Ce qui reste au milieu : on fusionne avec la voisine de droite.
    i = 1;
    while i < numel(attendus)
        if attendus(i) < minimum
            attendus(i + 1) = attendus(i + 1) + attendus(i);
            observes(i + 1) = observes(i + 1) + observes(i);
            attendus(i) = [];
            observes(i) = [];
        else
            i = i + 1;
        end
    end
end
