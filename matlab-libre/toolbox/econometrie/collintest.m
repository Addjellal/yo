function [valeursSingulieres, indices, proportions] = collintest(X, varargin)
%COLLINTEST Diagnostics de colinéarité de Belsley.
%   S = COLLINTEST(X) rend les valeurs singulières des colonnes de X
%   ramenées à la norme un. [S,IDX,PROP] = COLLINTEST(X) rend en plus les
%   indices de conditionnement et les proportions de variance.
%
%   Deux colonnes presque proportionnelles rendent les coefficients d'une
%   régression instables sans que rien, dans les résidus, ne le signale.
%   Belsley propose de regarder les valeurs singulières : un indice de
%   conditionnement élevé annonce une dépendance quasi linéaire, et la
%   ligne correspondante des proportions de variance dit lesquelles des
%   colonnes y participent.
%
%   Les colonnes sont ramenées à la norme un mais ne sont pas centrées :
%   centrer effacerait la colinéarité de la constante avec le reste, qui
%   est justement ce qu'on veut voir.
%
%   COLLINTEST(...,'tolIdx',T) règle le seuil d'alerte sur l'indice de
%   conditionnement (30), 'tolProp',P celui sur les proportions (0,5),
%   'varNames',N nomme les colonnes, 'display','off' se tait.
%
%   Une dépendance est signalée quand un indice dépasse tolIdx et qu'au
%   moins deux colonnes y contribuent pour plus de tolProp.
%
%   Exemple :
%      x1 = randn(100, 1);
%      X = [ones(100, 1), x1, x1 + 0.001 * randn(100, 1)];
%      collintest(X)
%
%   Voir aussi OLS, REGRESS, SVD, COND.
    X = double(X);
    if ndims(X) > 2 || isempty(X)   %#ok<ISMAT>
        error('econ:collintest:Donnees', 'X doit être une matrice non vide.');
    end
    nombre = size(X, 2);
    noms = cell(1, nombre);
    for j = 1:nombre
        noms{j} = sprintf('x%d', j);
    end
    seuilIndice = 30;
    seuilProportion = 0.5;
    affichage = true;
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'tolidx',   seuilIndice = varargin{k+1};
            case 'tolprop',  seuilProportion = varargin{k+1};
            case 'varnames', noms = varargin{k+1};
            case 'display',  affichage = strcmpi(char(varargin{k+1}), 'on');
            case 'plot'      % pas de tracé : les tableaux disent tout
            otherwise
                error('econ:collintest:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    if ~iscell(noms)
        noms = cellstr(noms);
    end
    if numel(noms) ~= nombre
        error('econ:collintest:Noms', ...
              'Il faut %d noms de colonnes.', nombre);
    end
    % Mise à la norme un, colonne par colonne.
    normes = sqrt(sum(X .^ 2, 1));
    normes(normes == 0) = 1;
    reduite = X ./ repmat(normes, size(X, 1), 1);
    [~, S, V] = svd(reduite, 0);
    valeursSingulieres = diag(S);
    valeursSingulieres = valeursSingulieres(:);
    plusGrande = valeursSingulieres(1);
    indices = plusGrande ./ max(valeursSingulieres, eps);
    % Proportion de la variance du coefficient k due à la composante j.
    parts = (V .^ 2) ./ repmat((valeursSingulieres .^ 2).', nombre, 1);
    totaux = sum(parts, 2);
    totaux(totaux == 0) = 1;
    proportions = (parts ./ repmat(totaux, 1, nombre)).';
    if affichage
        fprintf('\nDiagnostics de colinéarité\n\n');
        fprintf('  %-10s %-10s', 'sValeur', 'condIdx');
        for j = 1:nombre
            fprintf(' %10s', noms{j});
        end
        fprintf('\n');
        for j = 1:nombre
            fprintf('  %-10.4f %-10.4f', valeursSingulieres(j), indices(j));
            for c = 1:nombre
                fprintf(' %10.4f', proportions(j, c));
            end
            if indices(j) > seuilIndice && ...
               sum(proportions(j, :) > seuilProportion) > 1
                fprintf('   <-- dépendance');
            end
            fprintf('\n');
        end
        fprintf('\n');
    end
end
