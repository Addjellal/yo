function noms = matlibre_noms_voies(base, largeur)
%MATLIBRE_NOMS_VOIES Les noms d'un signal à plusieurs voies.
%   NOMS = MATLIBRE_NOMS_VOIES('u',3) rend {'u(1)';'u(2)';'u(3)'}, la
%   façon dont MATLAB nomme les voies d'un signal vectoriel. Pour une
%   seule voie, le nom reste tel quel.
%
%   Cette fonction est un utilitaire interne de la boîte à outils
%   Automatique : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_noms_voies('u', 2)      % {'u(1)'; 'u(2)'}
%      matlibre_noms_voies('e', 1)      % {'e'}
%
%   Voir aussi SUMBLK, CONNECT.
    base = strtrim(char(base));
    if largeur <= 1
        noms = {base};
        return
    end
    noms = cell(largeur, 1);
    for k = 1:largeur
        noms{k} = sprintf('%s(%d)', base, k);
    end
end
