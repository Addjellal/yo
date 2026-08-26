function d = oct2dec(o)
%OCT2DEC Conversion d'un nombre écrit en octal vers le décimal.
%   D = OCT2DEC(O) interprète les chiffres décimaux de O comme des
%   chiffres octaux : 17 devient 15, 7 reste 7. C'est la convention des
%   polynômes générateurs, qu'on écrit toujours en octal.
%
%   Exemple :
%      oct2dec([7 5])    % [7 5]
%      oct2dec([171 133])   % [121 91]
%
%   Voir aussi DEC2OCT, POLY2TRELLIS.
    o = double(o);
    d = zeros(size(o));
    for indice = 1:numel(o)
        valeur = abs(round(o(indice)));
        somme = 0;
        puissance = 1;
        while valeur > 0
            chiffre = mod(valeur, 10);
            if chiffre > 7
                error('comm:oct2dec:BadDigit', ...
                      'Le chiffre %d n''existe pas en octal.', chiffre);
            end
            somme = somme + chiffre * puissance;
            puissance = puissance * 8;
            valeur = floor(valeur / 10);
        end
        d(indice) = somme * sign(o(indice) + (o(indice) == 0));
    end
end
