function ok = matlibre_meme_valeur(a, b)
%MATLIBRE_MEME_VALEUR Compare deux valeurs de paramètre, texte ou nombre.
%   Un paramètre de bloc s'écrit indifféremment en nombre ou en texte :
%   ADD_BLOCK accepte « 'Gain', 2 » comme « 'Gain', '2' ». La recherche
%   doit donc les tenir pour égaux, sans quoi retrouver un bloc dépendrait
%   de la façon dont on l'a écrit.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_meme_valeur(2, '2')        % 1
%      matlibre_meme_valeur('abc', 'abc')  % 1
%      matlibre_meme_valeur(2, 3)          % 0
%
%   Voir aussi FIND_SYSTEM, GET_PARAM.
    if isnumeric(a) && isnumeric(b)
        ok = isequal(a, b);
        return
    end
    ok = strcmp(enTexte(a), enTexte(b));
end

function t = enTexte(v)
    if ischar(v)
        t = v;
    elseif isstring(v)
        t = char(v);
    elseif isnumeric(v) && isscalar(v)
        if v == floor(v) && abs(v) < 1e15
            t = sprintf('%d', v);
        else
            t = sprintf('%.17g', v);
        end
    else
        t = mat2str(v);
    end
end
