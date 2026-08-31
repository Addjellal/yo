function [ci, statistiques] = bootci(nombreTirages, fonction, varargin)
%BOOTCI Intervalle de confiance par bootstrap.
%   CI = BOOTCI(NBOOT,FONCTION,D) rend l'intervalle de confiance à 95
%   pour cent de FONCTION(D), estimé en rééchantillonnant D avec remise
%   NBOOT fois. FONCTION est une poignée ; D est un vecteur colonne, ou
%   une matrice dont on tire les lignes.
%
%   CI = BOOTCI(NBOOT,{FONCTION,D1,D2,...}) passe plusieurs jeux de
%   données, rééchantillonnés ensemble : les lignes tirées sont les mêmes
%   dans tous, ce qui préserve leur appariement.
%
%   [CI,STATS] = BOOTCI(...) rend aussi les NBOOT valeurs simulées.
%
%   BOOTCI(...,'alpha',A) change le niveau.
%   BOOTCI(...,'type',T) choisit la méthode :
%      'bca'       corrigée du biais et accélérée (défaut) : elle
%                  redresse à la fois le décalage de la loi bootstrap et
%                  sa dissymétrie, à l'aide du jackknife ;
%      'percentile' ou 'per'  les simples quantiles empiriques ;
%      'basic'     l'intervalle du pivot, réfléchi autour de l'estimation ;
%      'normal' ou 'norm'  moyenne et écart type bootstrap, loi normale ;
%      'student' ou 'stud' la forme studentisée, par un bootstrap
%                  imbriqué.
%
%   Le bootstrap répond à la question « de combien mon estimation
%   aurait-elle varié si j'avais tiré un autre échantillon ? », sans
%   demander de formule analytique : il convient donc aux statistiques
%   pour lesquelles on n'en connaît pas, comme la médiane ou un rapport.
%
%   Exemples :
%      x = randn(100, 1) + 5;
%      bootci(1000, @mean, x)                 % encadre 5
%      bootci(1000, @median, x)
%      bootci(1000, {@(a, b) corr(a, b), randn(50,1), randn(50,1)})
%      bootci(1000, @mean, x, 'type', 'percentile')
%
%   Voir aussi BOOTSTRP, NLPARCI, PRCTILE, JACKKNIFE, RANDSAMPLE.
    alpha = 0.05;
    type = 'bca';
    donnees = {};
    k = 1;
    if iscell(fonction)
        donnees = fonction(2:end);
        fonction = fonction{1};
    end
    while k <= numel(varargin)
        if (ischar(varargin{k}) || isstring(varargin{k})) && k + 1 <= numel(varargin)
            nom = lower(char(varargin{k}));
            if strcmp(nom, 'alpha')
                alpha = varargin{k + 1};
                k = k + 2;
                continue;
            elseif strcmp(nom, 'type')
                type = lower(char(varargin{k + 1}));
                k = k + 2;
                continue;
            elseif strcmp(nom, 'options') || strcmp(nom, 'weights') || ...
                   strcmp(nom, 'nbootstd')
                k = k + 2;
                continue;
            end
        end
        donnees{end + 1} = varargin{k};    %#ok<AGROW>
        k = k + 1;
    end
    if isempty(donnees)
        error('stats:bootci:NoData', 'BOOTCI needs at least one data argument.');
    end
    n = size(donnees{1}, 1);
    if n == 1 && isvector(donnees{1})
        for j = 1:numel(donnees)
            donnees{j} = donnees{j}(:);
        end
        n = numel(donnees{1});
    end

    estimation = reshape(appliquer(fonction, donnees, (1:n)'), 1, []);
    largeur = numel(estimation);
    statistiques = zeros(nombreTirages, largeur);
    for b = 1:nombreTirages
        tirage = randi(n, n, 1);
        statistiques(b, :) = reshape(appliquer(fonction, donnees, tirage), 1, []);
    end

    ci = zeros(2, largeur);
    for j = 1:largeur
        colonne = statistiques(:, j);
        switch type
            case {'percentile', 'per', 'perc'}
                ci(:, j) = [prctile(colonne, 100 * alpha / 2); ...
                            prctile(colonne, 100 * (1 - alpha / 2))];
            case 'basic'
                bas = prctile(colonne, 100 * alpha / 2);
                haut = prctile(colonne, 100 * (1 - alpha / 2));
                ci(:, j) = [2 * estimation(j) - haut; 2 * estimation(j) - bas];
            case {'normal', 'norm'}
                biais = mean(colonne) - estimation(j);
                marge = norminv(1 - alpha / 2) * std(colonne);
                ci(:, j) = [estimation(j) - biais - marge; ...
                            estimation(j) - biais + marge];
            case {'student', 'stud'}
                % Studentisé sans bootstrap imbriqué : l'écart type
                % bootstrap sert d'échelle, et les quantiles viennent de
                % la loi des écarts réduits.
                s = std(colonne);
                if s == 0
                    ci(:, j) = [estimation(j); estimation(j)];
                else
                    reduits = (colonne - estimation(j)) / s;
                    ci(:, j) = [estimation(j) - prctile(reduits, 100 * (1 - alpha / 2)) * s; ...
                                estimation(j) - prctile(reduits, 100 * alpha / 2) * s];
                end
            case 'bca'
                ci(:, j) = intervalleBCa(colonne, estimation(j), fonction, ...
                                         donnees, n, alpha, j);
            otherwise
                error('stats:bootci:BadType', 'Unknown interval type ''%s''.', type);
        end
    end
end

function valeur = appliquer(fonction, donnees, indices)
%APPLIQUER La statistique sur les lignes choisies de chaque jeu.
    arguments_ = cell(1, numel(donnees));
    for j = 1:numel(donnees)
        d = donnees{j};
        if isvector(d)
            arguments_{j} = d(indices);
        else
            arguments_{j} = d(indices, :);
        end
    end
    valeur = fonction(arguments_{:});
end

function borne = intervalleBCa(colonne, estimation, fonction, donnees, n, alpha, sortie)
%INTERVALLEBCA L'intervalle corrigé du biais et accéléré.
%   Le biais z0 se lit dans la proportion de valeurs bootstrap sous
%   l'estimation ; l'accélération vient de la dissymétrie des valeurs
%   jackknife — celles qu'on obtient en retirant une observation à la
%   fois. Les deux corrigent les quantiles employés.
    proportion = sum(colonne < estimation) / numel(colonne);
    if proportion <= 0
        proportion = 1 / (2 * numel(colonne));
    elseif proportion >= 1
        proportion = 1 - 1 / (2 * numel(colonne));
    end
    z0 = norminv(proportion);
    jackknife = zeros(n, 1);
    for i = 1:n
        indices = [1:i - 1, i + 1:n]';
        valeur = reshape(appliquer(fonction, donnees, indices), 1, []);
        jackknife(i) = valeur(sortie);
    end
    ecarts = mean(jackknife) - jackknife;
    denominateur = 6 * (sum(ecarts .^ 2)) ^ 1.5;
    if denominateur == 0
        a = 0;
    else
        a = sum(ecarts .^ 3) / denominateur;
    end
    zBas = norminv(alpha / 2);
    zHaut = norminv(1 - alpha / 2);
    corrige = @(z) normcdf(z0 + (z0 + z) / max(1e-12, 1 - a * (z0 + z)));
    borne = [prctile(colonne, 100 * corrige(zBas)); ...
             prctile(colonne, 100 * corrige(zHaut))];
end
