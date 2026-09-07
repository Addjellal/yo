function j = matlibre_dict_trouver(d, cle)
%MATLIBRE_DICT_TROUVER Rang d'une clé dans un dictionnaire, vide si absente.
%   La recherche est linéaire. Sur un dictionnaire de quelques milliers
%   d'entrées cela suffit ; au-delà, une table de hachage s'imposerait.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      d = dictionary(["a", "b"], [1 2]);
%      matlibre_dict_trouver(d, 'b')   % 2
%
%   Voir aussi DICTIONARY, ISKEY, LOOKUP.
    j = [];
    for k = 1:numel(d.Cles)
        courante = d.Cles{k};
        if isnumeric(cle) && isnumeric(courante)
            if courante == cle, j = k; return, end
        elseif ~isnumeric(cle) && ~isnumeric(courante)
            if strcmp(char(courante), char(cle)), j = k; return, end
        end
    end
end
