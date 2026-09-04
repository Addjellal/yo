function [entiers, trentedeuxiemes] = dec2thirtytwo(valeur, precision)
%DEC2THIRTYTWO Cours décimal converti en trente-deuxièmes.
%   [E,T] = DEC2THIRTYTWO(VALEUR) sépare la partie entière et le nombre
%   de trente-deuxièmes. PRECISION arrondit ces derniers à la fraction
%   voulue : 1 pour l'unité, 2 pour le demi, 4 pour le quart.
%
%   Les obligations d'État américaines se cotent ainsi : 101 et 16
%   trente-deuxièmes, soit 101,5.
%
%   Exemple :
%      [e, t] = dec2thirtytwo(101.5)     % 101 et 16
%
%   Voir aussi THIRTYTWO2DEC, CUR2FRAC, FRAC2CUR.
    if nargin < 2 || isempty(precision)
        precision = 1;
    end
    valeur = double(valeur);
    entiers = floor(valeur);
    trentedeuxiemes = round((valeur - entiers) * 32 * precision) / precision;
    plein = trentedeuxiemes >= 32;
    entiers(plein) = entiers(plein) + 1;
    trentedeuxiemes(plein) = 0;
end
