function [mots, tailles] = matlibre_nuage_entree(arguments)
%MATLIBRE_NUAGE_ENTREE Démêle les arguments d'un nuage de mots.
%   Accepte une liste de mots et leurs tailles, ou un texte brut dont les
%   mots sont comptés. Dans ce dernier cas, les mots d'une lettre et les
%   plus courants sont écartés : ils domineraient le nuage sans rien en
%   dire.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [m, t] = matlibre_nuage_entree({["a" "b"], [2 1]});
%      numel(m) == 2 && t(1) == 2
%
%   Voir aussi WORDCLOUD.
    mots = string([]);
    tailles = [];
    if isempty(arguments)
        return
    end
    if numel(arguments) >= 2 && isnumeric(arguments{2})
        mots = string(arguments{1});
        tailles = double(arguments{2});
        mots = mots(:)';
        tailles = tailles(:)';
        if numel(mots) ~= numel(tailles)
            error('MATLAB:wordcloud:tailles', ...
                  'Il faut autant de tailles que de mots.');
        end
        return
    end
    texte = arguments{1};
    if iscell(texte) || isstring(texte)
        texte = strjoin(cellstr(texte), ' ');
    end
    morceaux = regexp(lower(char(texte)), '[a-zA-Zà-ÿ]+', 'match');
    morceaux = morceaux(cellfun(@(m) numel(m) > 2, morceaux));
    if isempty(morceaux)
        return
    end
    [distincts, ~, ou] = unique(morceaux);
    compte = accumarray(ou(:), 1)';
    mots = string(distincts);
    tailles = compte;
end
