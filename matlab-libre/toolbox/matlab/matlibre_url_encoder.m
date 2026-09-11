function t = matlibre_url_encoder(t)
%MATLIBRE_URL_ENCODER Encodage d'une valeur pour une adresse.
%   T = MATLIBRE_URL_ENCODER(TEXTE) remplace par %XX tout ce qui n'est ni
%   lettre, ni chiffre, ni l'un des caractères sûrs « -_.~ ».
%
%   Sans cela, un espace ou une esperluette dans une valeur couperait la
%   requête en deux : l'encodage n'est pas une politesse, c'est ce qui
%   sépare la donnée de la syntaxe.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_url_encoder('un chat&')   % 'un%20chat%26'
%
%   Voir aussi WEBSAVE, WEBREAD, WEBWRITE.
    t = char(t);
    sortie = '';
    for k = 1:numel(t)
        c = t(k);
        if isletter(c) || (c >= '0' && c <= '9') || any(c == '-_.~')
            sortie(end+1) = c;   %#ok<AGROW>
        else
            sortie = [sortie sprintf('%%%02X', double(c))];   %#ok<AGROW>
        end
    end
    t = sortie;
end
