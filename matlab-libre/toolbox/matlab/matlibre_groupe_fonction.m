function f = matlibre_groupe_fonction(methode)
%MATLIBRE_GROUPE_FONCTION Traduit un nom de méthode en poignée de fonction.
%   GROUPSUMMARY, GROUPTRANSFORM et GROUPFILTER acceptent les mêmes noms ;
%   la traduction se fait ici une fois pour toutes.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      f = matlibre_groupe_fonction('sum');
%      f([1 2 3])                      % 6
%
%   Voir aussi GROUPSUMMARY, GROUPTRANSFORM, GROUPFILTER.
    if isa(methode, 'function_handle')
        f = methode;
        return
    end
    switch lower(char(methode))
        case 'sum',      f = @sum;
        case 'mean',     f = @mean;
        case 'median',   f = @median;
        case 'min',      f = @min;
        case 'max',      f = @max;
        case 'std',      f = @std;
        case 'var',      f = @var;
        case {'numel', 'count'}, f = @numel;
        case 'nnz',      f = @nnz;
        case 'all',      f = @all;
        case 'any',      f = @any;
        case 'range',    f = @(v) max(v) - min(v);
        case 'zscore',   f = @(v) (v - mean(v)) / max(std(v), eps);
        case 'norm',     f = @(v) (v - min(v)) / max(max(v) - min(v), eps);
        case 'center',   f = @(v) v - mean(v);
        case 'meanfill', f = @(v) remplirParMoyenne(v);
        otherwise
            error('MATLAB:groupe:UnknownMethod', ...
                  'Méthode inconnue : %s.', char(methode));
    end
end

function v = remplirParMoyenne(v)
    manque = isnan(v);
    if any(~manque)
        v(manque) = mean(v(~manque));
    end
end
