function o = dec2oct(d)
%DEC2OCT Écriture octale d'un nombre décimal, rendue comme un nombre.
%   O = DEC2OCT(D) rend le nombre dont les chiffres décimaux sont les
%   chiffres octaux de D : 15 devient 17.
%
%   Exemple :
%      dec2oct([121 91])   % [171 133]
%
%   Voir aussi OCT2DEC, POLY2TRELLIS.
    d = double(d);
    o = zeros(size(d));
    for indice = 1:numel(d)
        valeur = abs(round(d(indice)));
        somme = 0;
        puissance = 1;
        while valeur > 0
            somme = somme + mod(valeur, 8) * puissance;
            puissance = puissance * 10;
            valeur = floor(valeur / 8);
        end
        o(indice) = somme;
    end
end
