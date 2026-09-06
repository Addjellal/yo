function s = dec2base(d, base, longueur)
%DEC2BASE Entier vers chaîne dans une base quelconque.
%   S = DEC2BASE(D,BASE) rend l'écriture de l'entier D en base BASE, sous
%   forme de chaîne. Les chiffres au-delà de neuf s'écrivent A, B, C… ce
%   qui borne BASE à 36. Zéro s'écrit '0'.
%   S = DEC2BASE(D,BASE,LONGUEUR) complète à gauche par des zéros jusqu'à
%   LONGUEUR caractères ; une écriture plus longue n'est pas tronquée.
%
%   Les chiffres sortent par divisions successives, donc du poids faible
%   vers le poids fort, et sont empilés à gauche au fur et à mesure. D est
%   arrondi : la fonction ne représente que des entiers.
%
%   Le remplissage à longueur fixe sert à aligner des mots binaires — une
%   trame se lit à colonnes constantes, et un mot plus court qu'un autre
%   la décale tout entière.
%
%   Exemple :
%      dec2base(255, 16)
%      dec2base(5, 2, 8)
%
%   Voir aussi BASE2DEC, DEC2BIN, DEC2HEX.
    chiffres = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    s = '';
    v = round(d);
    while v > 0
        s = [chiffres(mod(v, base) + 1), s];
        v = floor(v / base);
    end
    if isempty(s)
        s = '0';
    end
    if nargin > 2
        while numel(s) < longueur
            s = ['0', s];
        end
    end
end
