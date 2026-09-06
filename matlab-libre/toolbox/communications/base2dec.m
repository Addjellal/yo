function d = base2dec(chaine, base)
%BASE2DEC Chaîne dans une base quelconque vers entier.
%   D = BASE2DEC(CHAINE,BASE) interprète CHAINE comme l'écriture d'un
%   entier en base BASE et rend sa valeur. Les chiffres au-delà de neuf
%   s'écrivent avec les lettres, A valant dix ; la casse est indifférente
%   et les espaces de tête et de queue sont ignorés.
%
%   La lecture se fait par la méthode de Horner, du chiffre de poids fort
%   vers celui de poids faible : d = d*BASE + chiffre. Elle ne demande
%   aucune puissance, donc aucun arrondi, et reste exacte tant que le
%   résultat tient dans les 53 bits de mantisse d'un double.
%
%   Aucun contrôle n'est fait que les chiffres appartiennent bien à la
%   base : c'est l'appelant qui garantit la cohérence.
%
%   Exemple :
%      base2dec('FF', 16)
%      base2dec('1010', 2)
%
%   Voir aussi DEC2BASE, DEC2BIN, BIN2DEC, HEX2DEC.
    chaine = upper(strtrim(char(chaine)));
    d = 0;
    for k = 1:numel(chaine)
        c = chaine(k);
        if c >= '0' && c <= '9'
            v = double(c) - double('0');
        else
            v = double(c) - double('A') + 10;
        end
        d = d * base + v;
    end
end
