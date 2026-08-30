function noms = matlibre_liste_noms(valeur)
%MATLIBRE_LISTE_NOMS Une liste de noms de signaux, quelle qu'en soit l'écriture.
%   NOMS = MATLIBRE_LISTE_NOMS(V) rend un tableau de cellules de chaînes,
%   que V soit une chaîne, un tableau de chaînes ou déjà un tableau de
%   cellules. C'est ce que CONNECT accepte pour ses listes d'entrées et de
%   sorties.
%
%   Cette fonction est un utilitaire interne de la boîte à outils
%   Automatique : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_liste_noms('u')            % {'u'}
%      matlibre_liste_noms({'a', 'b'})     % {'a', 'b'}
%
%   Voir aussi CONNECT, SUMBLK.
    if isempty(valeur)
        noms = {};
    elseif iscell(valeur)
        noms = cell(1, numel(valeur));
        for k = 1:numel(valeur)
            noms{k} = strtrim(char(valeur{k}));
        end
    elseif ischar(valeur) || isstring(valeur)
        noms = {strtrim(char(valeur))};
    else
        error('Control:connect:BadName', 'Signal names must be text.');
    end
end
